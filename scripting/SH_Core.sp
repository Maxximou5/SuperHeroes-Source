#pragma semicolon 1

//Includes
#include <sourcemod>
#include <sdktools>
#include <SH_Core>
#include <SH_Logging>

//New Syntax
#pragma newdecls required

//Defines
#define PLUGIN_AUTHOR "Keith Warren(Drixevel)"
#define PLUGIN_VERSION "1.0.0"

//#define DEBUG				//Enable/Disable Debugs
#define CONVAR_NUMBER 3		//Number of ConVars for this plugin.

//////////////////
//Globals

//ConVar Globals
Handle hConVars[CONVAR_NUMBER];
char cv_sVersion[12]; bool cv_bStatus; char cv_sDatabase[256];

//Handles
Handle hDatabase;

//Variables
bool bIsConnected; bool bIsLateLoad; bool bIsAllPluginsLoaded;

//Main Menu Globals
enum MainMenu_Item
{
	String:MenuItemDisplayName[MAX_MAINMENU_ITEM_SIZE], 
	String:MenuItemValue[64], 
	Handle:MenuItemPlugin, 
	SH_MenuItemClickCallback:MenuItemCallback, 
	MenuItemOrder
}

int iMainMenu_Items[MAX_MAINMENU_ITEMS][MainMenu_Item];
int iMainMenu_ItemCount;

//Menu Handle
Handle hMainMenu;

//Forwards
Handle hF_OnDatabaseConnected;
Handle hF_OnReady;

//Plugin Info
public Plugin myinfo =
{
	name = "[SuperHeroes] Core",
	author = PLUGIN_AUTHOR,
	description = "Core module for the SuperHeroes plugin set.",
	version = PLUGIN_VERSION,
	url = "http://www.drixevel.com/"
};

//Ask Plugin Load 2
public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrorSize)
{
	CreateNative("SH_TQuery", Native_TQuery);
	CreateNative("SH_Query", Native_Query);
	CreateNative("SH_AddMainMenuItem", Native_AddMainMenuItem);
	CreateNative("SH_IsValidPlayer", Native_IsValidPlayer);
	CreateNative("SH_OpenMainMenu", Native_OpenMainMenu);
	
	hF_OnDatabaseConnected = CreateGlobalForward("SH_OnDatabaseConnected", ET_Ignore);
	hF_OnReady = CreateGlobalForward("SH_OnReady", ET_Ignore);
	
	RegPluginLibrary("SH_Core");
	
	bIsLateLoad = bLate;
	return APLRes_Success;
}

//On Plugin Start
public void OnPluginStart()
{
	hConVars[0] = CreateConVar("superheroes_version", PLUGIN_VERSION, "Version Control", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD);
	hConVars[1] = CreateConVar("sm_superheroes_core_status", "1", "Status of the plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[2] = CreateConVar("sm_superheroes_core_database", "superheroes", "Name of the database config entry.", FCVAR_NOTIFY);
	
	for (int i = 0; i < sizeof(hConVars); i++)
	{
		HookConVarChange(hConVars[i], OnConVarsChanged);
	}
	
	RegConsoleCmd("sm_mainmenu", OpenMainMenu);
	
	hMainMenu = CreateMenu(MainMenuSelectHandle);
	SetMenuTitle(hMainMenu, "SuperHeroes Menu");
	SetMenuExitButton(hMainMenu, true);
	
	bIsAllPluginsLoaded = true;
	
	AutoExecConfig(true, "SH_Core", "superheroes");
}

//On Configs Executed
public void OnConfigsExecuted()
{
	GetConVarString(hConVars[0], cv_sVersion, sizeof(cv_sVersion));
	cv_bStatus = GetConVarBool(hConVars[1]);
	GetConVarString(hConVars[2], cv_sDatabase, sizeof(cv_sDatabase));
	
	if (!cv_bStatus)
	{
		return;
	}
	
	if (bIsLateLoad)
	{
		//Do Things Later...
	}
	
	SQL_TConnect(OnSQLConnect, cv_sDatabase);
}

//ConVar Changes
public void OnConVarsChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	int value = StringToInt(newValue);
	
	if (convar == hConVars[0])
	{
		SetConVarString(hConVars[0], PLUGIN_VERSION);
	}
	else if (convar == hConVars[1])
	{
		cv_bStatus = view_as<bool>value;
	}
	else if (convar == hConVars[2])
	{
		strcopy(cv_sDatabase, sizeof(cv_sDatabase), newValue);
	}
}

//On All Plugins Loaded
public void OnAllPluginsLoaded()
{
	bIsAllPluginsLoaded = true;
}

//On SQL Connection
public void OnSQLConnect(Handle owner, Handle hndl, const char[] sError, any data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Error connecting to database: %s", sError);
		bIsConnected = false;
		return;
	}
	
	hDatabase = hndl;
	bIsConnected = true;
	
	//Create a forward call for when the database has connected.
	Call_StartForward(hF_OnDatabaseConnected);
	Call_Finish();
	
	SH_Log("Successfully connected to the database.");
	
	RequestFrame(OnReadyStatus);
}

public void OnReadyStatus(any data)
{
	Call_StartForward(hF_OnReady);
	Call_Finish();
	
	SH_Log("All plugins are ready to accept hero/ability registrations.");
}

//Opens the Main Menu to the client with registered items provided by other modules.
public Action OpenMainMenu(int client, int args)
{
	if (!cv_bStatus)return Plugin_Handled;
	
	if (!ShowMainMenu(client))
	{
		PrintToChat(client, "Error opening main menu, please contact an administrator.");
	}
	
	return Plugin_Handled;
}

//Opens Main Menu and checks client in the process.
bool ShowMainMenu(int client)
{
	if (!SH_IsValidPlayer(client, true))
	{
		return false;
	}
	
	return DisplayMenu(hMainMenu, client, MENU_TIME_FOREVER);
}

//////////////////
//Natives

//Executes threaded queries into SuperHeroes database and receive callbacks.
public int Native_TQuery(Handle hPlugin, int iParams)
{
	if (!bIsConnected || hDatabase == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Database is not connected currently.");
		return;
	}
	
	SQLTCallback callback = view_as<SQLTCallback>GetNativeFunction(1); //Callback
	
	//Query String Size
	int size;
	GetNativeStringLength(2, size);
	
	//Query String
	char[] sQuery = new char[size];
	GetNativeString(2, sQuery, size);
	
	int data = GetNativeCell(3); //Data
	DBPriority prio = view_as<DBPriority>GetNativeCell(4); //Priority
	
	Handle hPack = CreateDataPack();
	WritePackCell(hPack, hPlugin); //Plugin Handle
	WritePackFunction(hPack, callback); //Callback Handle
	WritePackCell(hPack, data); //Data
	
	SQL_TQuery(hDatabase, Query_Callback, sQuery, hPack, prio);
}

public void Query_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
	ResetPack(data);
	
	Handle plugin = view_as<Handle>ReadPackCell(data); //Plugin Handle
	SQLTCallback callback = view_as<SQLTCallback>ReadPackFunction(data); //Callback Handle
	int pack = ReadPackCell(data); //Data
	
	CloseHandle(data);
	
	Call_StartFunction(plugin, callback);
	Call_PushCell(owner);
	Call_PushCell(hndl);
	Call_PushString(error);
	Call_PushCell(pack);
	Call_Finish();
}

//Executes fast queries to the database with no callbacks.
public int Native_Query(Handle hPlugin, int iParams)
{
	if (!bIsConnected || hDatabase == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Database is not connected currently.");
		return;
	}
	
	//Query String Size
	int size;
	GetNativeStringLength(1, size);
	
	//Query String
	char[] sQuery = new char[size];
	GetNativeString(1, sQuery, size);
	
	SQL_FastQuery(hDatabase, sQuery);
}

//Adds an item with a callback to the main menu.
public int Native_AddMainMenuItem(Handle hPlugin, int iParams)
{
	char sDisplay[MAX_MAINMENU_ITEM_SIZE];
	GetNativeString(1, sDisplay, sizeof(sDisplay));
	
	char sValue[64];
	GetNativeString(2, sValue, sizeof(sValue));
	
	AddMainMenuItem(sDisplay, sValue, hPlugin, view_as<SH_MenuItemClickCallback>GetNativeFunction(3), GetNativeCell(4));
}

void AddMainMenuItem(const char[] sDisplay, const char[] value = "", Handle plugin = INVALID_HANDLE, SH_MenuItemClickCallback callback, int order = 32)
{
	int item;
	
	for (; item <= iMainMenu_ItemCount; item++)
	{
		if (item == iMainMenu_ItemCount || StrEqual(iMainMenu_Items[item][MenuItemDisplayName], sDisplay))
		{
			break;
		}
	}
	
	strcopy(iMainMenu_Items[item][MenuItemDisplayName], MAX_MAINMENU_ITEM_SIZE, sDisplay);
	strcopy(iMainMenu_Items[item][MenuItemValue], 64, value);
	iMainMenu_Items[item][MenuItemPlugin] = plugin;
	iMainMenu_Items[item][MenuItemCallback] = callback;
	iMainMenu_Items[item][MenuItemOrder] = order;
	
	if (item == iMainMenu_ItemCount)
	{
		iMainMenu_ItemCount++;
	}
	
	if (bIsAllPluginsLoaded)
	{
		SortMainMenuItems();
	}
}

void SortMainMenuItems()
{
	int sortIndex = sizeof(iMainMenu_Items) - 1;
	
	for (int x = 0; x < iMainMenu_ItemCount; x++)
	{
		for (int y = 0; y < iMainMenu_ItemCount; y++)
		{
			if (iMainMenu_Items[x][MenuItemOrder] < iMainMenu_Items[y][MenuItemOrder])
			{
				iMainMenu_Items[sortIndex] = iMainMenu_Items[x];
				iMainMenu_Items[x] = iMainMenu_Items[y];
				iMainMenu_Items[y] = iMainMenu_Items[sortIndex];
			}
		}
	}
	
	if (hMainMenu != INVALID_HANDLE)
	{
		RemoveAllMenuItems(hMainMenu);
		
		for (int i = 0; i < iMainMenu_ItemCount; i++)
		{
			char sInfo[32];
			IntToString(i, sInfo, sizeof(sInfo));
			
			char sDisplay[256];
			Format(sDisplay, sizeof(sDisplay), "%s", iMainMenu_Items[i][MenuItemDisplayName]);
			
			AddMenuItem(hMainMenu, sInfo, sDisplay);
		}
	}
}

public int MainMenuSelectHandle(Handle menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
			GetMenuItem(menu, slot, sInfo, sizeof(sInfo));
			int ID = StringToInt(sInfo);
			
			Call_StartFunction(iMainMenu_Items[ID][MenuItemPlugin], iMainMenu_Items[ID][MenuItemCallback]);
			Call_PushCell(client);
			Call_PushString(iMainMenu_Items[ID][MenuItemValue]);
			Call_Finish();
		}
	}
}

//Validates a client for you. You can check if a client is fake and/or alive as well.
public int Native_IsValidPlayer(Handle hPlugin, int iParams)
{
	int client = GetNativeCell(1);
	
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || view_as<bool>GetNativeCell(2) && IsFakeClient(client) || view_as<bool>GetNativeCell(3) && !IsPlayerAlive(client))
	{
		return false;
	}
	
	return true;
}

//Opens the main menu for a client.
public int Native_OpenMainMenu(Handle hPlugin, int iParams)
{
	int client = GetNativeCell(1);
	
	return ShowMainMenu(client);
} 
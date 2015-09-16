#pragma semicolon 1

//Includes
#include <sourcemod>
#include <sdktools>
#include <SH_Core>
#include <SH_Heroes>
#include <SH_Progression>
#include <SH_Logging>

#undef REQUIRE_PLUGIN
#include <SH_Abilities>

//New Syntax
#pragma newdecls required

//Defines
#define PLUGIN_AUTHOR "Keith Warren(Drixevel)"
#define PLUGIN_VERSION "1.0.0"

//#define DEBUG				//Enable/Disable Debugs
#define CONVAR_NUMBER 8		//Number of ConVars for this plugin.

//SH Load Types
#define SH_LOAD_CONFIG 1	//Hero is loading from a configuration file.
#define SH_LOAD_PLUGIN 2	//Hero is loading from a plugin native.
#define SH_LOAD_MYSQL  3	//Hero is loading from a an SQL table.
#define SH_LOAD_ALL    4	//Used when reloading as an indication of all.

//////////////////
//Globals

//ConVar Globals
Handle hConVars[CONVAR_NUMBER];
bool cv_bStatus; int cv_iLoadType; bool cv_bLoadModels; char cv_sConfigLocation[PLATFORM_MAX_PATH]; bool cv_bRespectFlags; bool cv_bRespectLevel; bool cv_bShowDescriptions; int cv_iClientHeroes;

//Natives/Forwards
Handle hF_OnAssignedHero;
Handle hF_OnUnassignedHero;

//Variables
bool bIsLateLoad;

enum Heroes
{
	String:Hero_Name[MAX_HERO_NAME_LENGTH],  //Hero Name
	String:Hero_Description[MAX_HERO_DESCRIPTION_LENGTH],  //Hero Description
	Hero_RequiredLevel,  //Hero Required Level - The level required for clients to pick this hero.
	String:Hero_Model[PLATFORM_MAX_PATH],  //Model to assign player.
	String:Hero_Flags[32],  //Flags assigned to heroes.
	Hero_LoadType,  //The loadtype is the method that the hero is created and loaded into memory. (either config or plugin, look at SH Load Types defines above)
	Handle:Hero_Plugin
}

int iHeroes[MAX_HEROES][Heroes];
int iHeroesAmount;

int iAssignedHero[MAXPLAYERS + 1][MAX_HEROES];
int iCurrentHeroes[MAXPLAYERS + 1];

//Plugin Info
public Plugin myinfo =
{
	name = "[SuperHeroes] Heroes",
	author = PLUGIN_AUTHOR,
	description = "Module that handles the heroes and their data.",
	version = PLUGIN_VERSION,
	url = "http://www.drixevel.com/"
};

//Ask Plugin Load 2
public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrorSize)
{
	CreateNative("SH_RegisterHero", Native_RegisterHero);
	CreateNative("SH_GetClientHeroes", Native_GetClientHeroes);
	CreateNative("SH_AddClientHero", Native_AddClientHero);
	CreateNative("SH_RemoveClientHero", Native_RemoveClientHero);
	CreateNative("SH_IsClientHero", Native_IsClientHero);
	
	CreateNative("SH_GetHeroID", Native_GetHeroID);
	CreateNative("SH_GetHeroName", Native_GetHeroName);
	CreateNative("SH_GetHeroDescription", Native_GetHeroDescription);
	CreateNative("SH_GetHeroRequiredLevel", Native_GetHeroRequiredLevel);
	CreateNative("SH_GetHeroModel", Native_GetHeroModel);
	
	CreateNative("SH_IsHeroValid", Native_IsHeroValid);
	
	RegPluginLibrary("SH_Heroes");
	
	hF_OnAssignedHero = CreateGlobalForward("SH_OnAssignedHero", ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_String, Param_Cell, Param_String);
	hF_OnUnassignedHero = CreateGlobalForward("SH_OnUnassignedHero", ET_Ignore, Param_Cell, Param_Cell);
	
	bIsLateLoad = bLate;
	return APLRes_Success;
}

//On Plugin Start
public void OnPluginStart()
{
	hConVars[0] = CreateConVar("sm_superheroes_heroes_status", "1", "Status of the plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[1] = CreateConVar("sm_superheroes_heroes_allow_load", "0", "Allow which kinds of loading heroes. (0 = all, 1 = configs, 2 = plugins)", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hConVars[2] = CreateConVar("sm_superheroes_heroes_models", "1", "Load models data for all heroes.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[3] = CreateConVar("sm_superheroes_heroes_configs_location", "superheroes/heroes", "Name of the folder to load new hero configs from.", FCVAR_NOTIFY);
	hConVars[4] = CreateConVar("sm_superheroes_heroes_respect_flags", "1", "Check flags specified for the hero and respect them.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[5] = CreateConVar("sm_superheroes_heroes_respect_levels", "1", "Check the required level specified for the hero and respect it.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[6] = CreateConVar("sm_superheroes_heroes_show_descriptions", "1", "Show descriptions in the heroes menu.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[7] = CreateConVar("sm_superheroes_heroes_slots", "3", "Amount of heroes a client can be at the same time.", FCVAR_NOTIFY, true, 1.0);
	
	for (int i = 0; i < sizeof(hConVars); i++)
	{
		HookConVarChange(hConVars[i], OnConVarsChanged);
	}
	
	RegConsoleCmd("sm_listheroes", ListHeroes);
	RegConsoleCmd("sm_setheroes", SetHeroes);
	RegConsoleCmd("sm_heroes", SetHeroes);
	RegConsoleCmd("sm_currentheroes", CurrentHeroes);
	
	//RegAdminCmd("sm_reloadheroes", ReloadHeroes, ADMFLAG_ROOT, "Reload hero cache.");
	RegAdminCmd("sm_setclienthero", SetClientHero, ADMFLAG_ROOT, "Set a client(s) hero.");
	
	AutoExecConfig(true, "SH_Heroes", "superheroes");
}

//On Configs Executed
public void OnConfigsExecuted()
{
	cv_bStatus = GetConVarBool(hConVars[0]);
	cv_iLoadType = GetConVarInt(hConVars[1]);
	cv_bLoadModels = GetConVarBool(hConVars[2]);
	GetConVarString(hConVars[3], cv_sConfigLocation, sizeof(cv_sConfigLocation));
	cv_bRespectFlags = GetConVarBool(hConVars[4]);
	cv_bRespectLevel = GetConVarBool(hConVars[5]);
	cv_bShowDescriptions = GetConVarBool(hConVars[6]);
	cv_iClientHeroes = GetConVarInt(hConVars[7]);
	
	if (!cv_bStatus)
	{
		return;
	}
	
	if (bIsLateLoad)
	{
		
		bIsLateLoad = false;
	}
	
	//Resets all heroes for all clients.
	for (int i = 1; i <= MaxClients; i++)
	{
		Array_Fill(iAssignedHero[i], MAX_HEROES, -1);
	}
}

//ConVar Changes
public void OnConVarsChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	int value = StringToInt(newValue);
	
	if (convar == hConVars[0])
	{
		cv_bStatus = view_as<bool>value;
	}
	else if (convar == hConVars[0])
	{
		cv_iLoadType = value;
	}
	else if (convar == hConVars[1])
	{
		cv_bLoadModels = view_as<bool>value;
	}
	else if (convar == hConVars[2])
	{
		strcopy(cv_sConfigLocation, sizeof(cv_sConfigLocation), newValue);
	}
	else if (convar == hConVars[3])
	{
		cv_bRespectFlags = view_as<bool>value;
	}
	else if (convar == hConVars[4])
	{
		cv_bRespectLevel = view_as<bool>value;
	}
	else if (convar == hConVars[5])
	{
		cv_bShowDescriptions = view_as<bool>value;
	}
	else if (convar == hConVars[6])
	{
		cv_iClientHeroes = view_as<bool>value;
	}
}

//On All Plugins Loaded
public void OnAllPluginsLoaded()
{
	SH_AddMainMenuItem("List Heroes", _, Menu_ListHeroes, 1);
	SH_AddMainMenuItem("Set Heroes", _, Menu_SetHeroes, 2);
}

//Called when the database is connected, perfect time to register everything.
public void SH_OnReady()
{
	if (cv_iLoadType != 2)
	{
		char sPath[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, sPath, sizeof(sPath), "configs/%s", cv_sConfigLocation);
		
		ParseHeroesConfigs(sPath);
	}
}

//On Map Start
public void OnMapStart()
{
	
}

public void OnClientPutInServer(int client)
{
	Array_Fill(iAssignedHero[client], MAX_HEROES, -1);
	iCurrentHeroes[client] = 0;
}

public void OnClientDisconnect(int client)
{
	OnClientPutInServer(client);
}

//Shows the list of heroes to a client that they can choose from.
public Action ListHeroes(int client, int args)
{
	ListHeroesMenu(client);
	return Plugin_Handled;
}

public void Menu_ListHeroes(int client, const char[] value)
{
	ListHeroesMenu(client);
}

void ListHeroesMenu(int client)
{
	Handle hMenu = CreateMenu(SuperHeroesListMenuHandle);
	SetMenuTitle(hMenu, "SuperHeroes List");
	SetMenuExitBackButton(hMenu, true);
	
	RefillHeroesMenu(client, hMenu, cv_bRespectLevel, cv_bRespectFlags);
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int SuperHeroesListMenuHandle(Handle menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
			GetMenuItem(menu, slot, sInfo, sizeof(sInfo));
			int ID = StringToInt(sInfo);
			
			char sHeroName[MAX_HERO_NAME_LENGTH];
			SH_GetHeroName(ID, sHeroName, sizeof(sHeroName));
			
			char sHeroDescription[MAX_HERO_DESCRIPTION_LENGTH];
			SH_GetHeroDescription(ID, sHeroDescription, sizeof(sHeroDescription));
			
			PrintToChat(client, "[Hero %i] - %s - %s", ID, sHeroName, sHeroDescription);
			
			char sAbilityName[32];
			if (SH_ListAbilities(ID, 2, sAbilityName, sizeof(sAbilityName)))
			{
				PrintToChat(client, "[Hero %i] - Abilities: %s", ID, sAbilityName);
			}
			
			ListHeroesMenu(client);
		}
		
		case MenuAction_Cancel:
		{
			if (slot == MenuCancel_ExitBack)
			{
				SH_OpenMainMenu(client);
			}
		}
		
		case MenuAction_End:CloseHandle(menu);
	}
}

//Shows the list of heroes to a client that they can choose from.
public Action SetHeroes(int client, int args)
{
	SetHeroesMenu(client);
	return Plugin_Handled;
}

public void Menu_SetHeroes(int client, const char[] value)
{
	SetHeroesMenu(client);
}

void SetHeroesMenu(int client)
{
	Handle hMenu = CreateMenu(SlotsMenuHandle);
	SetMenuTitle(hMenu, "SuperHeroes - Your Slots");
	SetMenuExitBackButton(hMenu, true);
	
	for (int i = 0; i < cv_iClientHeroes; i++)
	{
		int ID = iAssignedHero[client][i];
		
		char sHeroName[MAX_HERO_NAME_LENGTH];
		
		if (ID > -1)
		{
			strcopy(sHeroName, sizeof(sHeroName), iHeroes[ID][Hero_Name]);
		}
		else
		{
			strcopy(sHeroName, sizeof(sHeroName), "(Empty)");
		}
		
		char sID[32];
		IntToString(i, sID, sizeof(sID));
		
		AddMenuItem(hMenu, sID, sHeroName);
	}
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int SlotsMenuHandle(Handle menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
			GetMenuItem(menu, slot, sInfo, sizeof(sInfo));
			int Slot_ID = StringToInt(sInfo);
			
			Handle hMenu = CreateMenu(SuperHeroesMenuHandle);
			SetMenuTitle(hMenu, "SuperHeroes - Your Slots");
			SetMenuExitBackButton(hMenu, true);
			
			AddMenuItem(hMenu, "Clear", "Clear Slot");
			RefillHeroesMenu(client, hMenu, cv_bRespectLevel, cv_bRespectFlags);
			
			PushMenuCell(hMenu, "Slot_ID", Slot_ID);
			
			DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
		}
		
		case MenuAction_Cancel:
		{
			if (slot == MenuCancel_ExitBack)
			{
				SH_OpenMainMenu(client);
			}
		}
		
		case MenuAction_End:CloseHandle(menu);
	}
}

public int SuperHeroesMenuHandle(Handle menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
			GetMenuItem(menu, slot, sInfo, sizeof(sInfo));
			
			int Slot_ID = GetMenuCell(menu, "Slot_ID", -1);
			
			if (!StrEqual(sInfo, "Clear"))
			{
				int Hero_ID = StringToInt(sInfo);
				
				char sName[MAX_HERO_NAME_LENGTH];
				SH_GetHeroName(Hero_ID, sName, sizeof(sName));
				
				MakeClientHero(client, Slot_ID, sName, true, true);
			}
			else
			{
				RemoveClientHero(client, Slot_ID, "", true);
			}
			
			SetHeroesMenu(client);
		}
		
		case MenuAction_Cancel:
		{
			SetHeroesMenu(client);
		}
		
		case MenuAction_End:CloseHandle(menu);
	}
}

//Shows the current hero assigned to a client.
public Action CurrentHeroes(int client, int args)
{
	char sBuffer[256];
	Format(sBuffer, sizeof(sBuffer), "Current Heroes: ");
	
	int inx;
	for (int i = 0; i < MAX_HEROES; i++)
	{
		int ID = iAssignedHero[client][i];
		
		if (inx > 0 && ID != -1)
		{
			Format(sBuffer, sizeof(sBuffer), "%s, %s", sBuffer, iHeroes[ID][Hero_Name]);
		}
		else if (ID != -1)
		{
			Format(sBuffer, sizeof(sBuffer), "%s%s", sBuffer, iHeroes[ID][Hero_Name]);
			inx++;
		}
	}
	
	PrintToChat(client, sBuffer);
	
	return Plugin_Handled;
}

/*
//ADMIN - Reloads all heroes via cache and resets the heroes list menu.
public Action:ReloadHeroes(client, args)
{
	new String:sArg[32];
	GetCmdArgString(sArg, sizeof(sArg));
	
	if (StrEqual(sArg, "All"))
	{
		ReplyToCommand(client, "Now reloading all heroes...");
		ReloadAllHeroes(client, SH_LOAD_ALL);
	}
	else if (StrEqual(sArg, "Configs"))
	{
		ReplyToCommand(client, "Now reloading heroes from configs...");
		ReloadAllHeroes(client, SH_LOAD_CONFIG);
	}
	else if (StrEqual(sArg, "Plugins"))
	{
		ReplyToCommand(client, "Now reloading heroes from plugins...");
		ReloadAllHeroes(client, SH_LOAD_PLUGIN);
	}
	else if (StrEqual(sArg, "Databases"))
	{
		ReplyToCommand(client, "Now reloading heroes from databases...");
		ReloadAllHeroes(client, SH_LOAD_MYSQL);
	}
	
	return Plugin_Handled;
}*/

//ADMIN - Sets a client(s) hero.
public Action SetClientHero(int client, int args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "Usage: sm_setclienthero <target-string> <hero name>");
		return Plugin_Handled;
	}
	
	char sTargets[32];
	GetCmdArg(1, sTargets, sizeof(sTargets));
	
	char sHero[32];
	GetCmdArg(2, sHero, sizeof(sHero));
	
	char sIndex[32];
	GetCmdArg(3, sIndex, sizeof(sIndex));
	int Slot_ID = StringToInt(sIndex);
	
	if (cv_iClientHeroes < 2)
	{
		Slot_ID = 0;
	}
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	bool tn_is_ml;
	
	int target_count = ProcessTargetString(sTargets, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY, target_name, sizeof(target_name), tn_is_ml);
	
	if (target_count <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		if (!MakeClientHero(target_list[i], Slot_ID, sHero))
		{
			PrintToChat(client, "Error finding Hero %s, please try again.", sHero);
			break;
		}
	}
	
	return Plugin_Handled;
}

//Function to create new heroes.
int RegisterNewHero(SH_OnHeroRegistered callback = INVALID_FUNCTION, int Load_Type, Handle hPlugin, const char[] sName, const char[] sDescription, int iRequiredLevel, const char[] sModel, const char[] sFlags)
{
	if (IsHeroRegistered(sName))
	{
		return SH_GetHeroID(sName);
	}
	
	strcopy(iHeroes[iHeroesAmount][Hero_Name], MAX_HERO_NAME_LENGTH, sName);
	strcopy(iHeroes[iHeroesAmount][Hero_Description], MAX_HERO_NAME_LENGTH, sDescription);
	iHeroes[iHeroesAmount][Hero_RequiredLevel] = iRequiredLevel;
	strcopy(iHeroes[iHeroesAmount][Hero_Model], PLATFORM_MAX_PATH, sModel);
	strcopy(iHeroes[iHeroesAmount][Hero_Flags], 32, sFlags);
	iHeroes[iHeroesAmount][Hero_LoadType] = Load_Type;
	iHeroes[iHeroesAmount][Hero_Plugin] = hPlugin;
	
	int HeroID = iHeroesAmount;
	iHeroesAmount++;
	
	char sLoadType[32];
	switch (iHeroes[HeroID][Hero_LoadType])
	{
		case SH_LOAD_CONFIG:
		{
			//Hero is loading from a configuration file.
			strcopy(sLoadType, sizeof(sLoadType), "Config");
		}
		case SH_LOAD_PLUGIN:
		{
			//Hero is loading from a plugin native.
			strcopy(sLoadType, sizeof(sLoadType), "Plugin");
		}
		case SH_LOAD_MYSQL:
		{
			//Hero is loading from a an SQL table.
			strcopy(sLoadType, sizeof(sLoadType), "MySQL");
		}
		case SH_LOAD_ALL:
		{
			//Used when reloading as an indication of all.
			strcopy(sLoadType, sizeof(sLoadType), "All");
		}
	}
	
	SH_LogInfo("Hero Registered - Index:[%i] Name:[%s] Description:[%s] Required Level:[%i] Model Path:[%s] Flags:[%s] LoadType:[%s]", HeroID, iHeroes[HeroID][Hero_Name], iHeroes[HeroID][Hero_Description], iHeroes[HeroID][Hero_RequiredLevel], iHeroes[HeroID][Hero_Model], iHeroes[HeroID][Hero_Flags], sLoadType);
	
	if (callback != INVALID_FUNCTION)
	{
		Call_StartFunction(hPlugin, callback);
		Call_PushCell(HeroID);
		Call_PushString(iHeroes[HeroID][Hero_Name]);
		Call_PushString(iHeroes[HeroID][Hero_Description]);
		Call_PushCell(iHeroes[HeroID][Hero_RequiredLevel]);
		Call_PushString(iHeroes[HeroID][Hero_Model]);
		Call_PushString(iHeroes[HeroID][Hero_Flags]);
		Call_Finish();
	}
	
	return HeroID;
}

//Checks if a specific hero is already registered.
bool IsHeroRegistered(const char[] sName)
{
	for (int i = 0; i < iHeroesAmount; i++)
	{
		if (StrEqual(iHeroes[i][Hero_Name], sName))
		{
			return true;
		}
	}
	
	return false;
}

//Delete all items from the heroes menu and refill them.
void RefillHeroesMenu(int client, Handle hMenu, bool bCheckLevels = false, bool bCheckVIP = false)
{
	for (int i = 0; i < iHeroesAmount; i++)
	{
		bool bDisabled;
		
		char sValue[32];
		Format(sValue, sizeof(sValue), "%i", i);
		
		char sDisplay[64];
		Format(sDisplay, sizeof(sDisplay), "%s", iHeroes[i][Hero_Name]);
		
		if (bCheckLevels)
		{
			int iRequiredLevel = iHeroes[i][Hero_RequiredLevel];
			Format(sDisplay, sizeof(sDisplay), "%s [%i]", sDisplay, iRequiredLevel);
			
			if (SH_GetClientLevel(client) < iRequiredLevel)
			{
				bDisabled = true;
			}
		}
		
		if (bCheckVIP)
		{
			Format(sDisplay, sizeof(sDisplay), "%s %s", sDisplay, HeroHasFlags(i) ? "[VIP]" : "");
			
			if (!bDisabled && !ClientHasHeroFlags(client, i))
			{
				bDisabled = true;
			}
		}
		
		if (cv_bShowDescriptions)
		{
			Format(sDisplay, sizeof(sDisplay), "%s\n%s", sDisplay, iHeroes[i][Hero_Description]);
		}
		
		AddMenuItem(hMenu, sValue, sDisplay, bDisabled ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
}

//Checks if a specific hero has flags.
bool HeroHasFlags(int HeroID)
{
	if (strlen(iHeroes[HeroID][Hero_Flags]) != 0)
	{
		return true;
	}
	
	return false;
}

bool ClientHasHeroFlags(int client, int HeroID)
{
	if (strlen(iHeroes[HeroID][Hero_Flags]) == 0)
	{
		return true;
	}
	
	AdminId admin = GetUserAdmin(client);
	
	if (admin != INVALID_ADMIN_ID)
	{
		int count, found, flags = ReadFlagString(iHeroes[HeroID][Hero_Flags]);
		
		for (int i = 0; i <= 20; i++)
		{
			if (flags & (1 << i))
			{
				count++;
				
				if (GetAdminFlag(admin, view_as<AdminFlag>i))
				{
					found++;
				}
			}
		}
		
		if (count == found)
		{
			return true;
		}
	}
	
	return false;
}

/** Need to make this code better at a later date.

//Function to reload heroes based on the reload type specified.
ReloadAllHeroes(client, iReloadType)
{
	switch (iReloadType)
	{
		case SH_LOAD_ALL: 
	}
	ReplyToCommand(client, "Heroes have been reloaded.");
}

//Reload all heroes from configs.
ReloadHeroesViaConfigs()
{
	
}

//Reload all heroes from plugins.
ReloadHeroesViaPlugins()
{
	
}

//Reload all heroes from databases.
ReloadHeroesViaDatabases()
{
	
}
*/

//Adds a hero to the client.
bool MakeClientHero(int client, int slot, const char[] sHeroName, bool bCheckLevel = true, bool bVerbose = true)
{
	int HeroID = GetHeroID(sHeroName);
	
	if (HeroID <= -1)
	{
		return false;
	}
	
	int iRequiredLevel = iHeroes[HeroID][Hero_RequiredLevel];
	
	if (bCheckLevel && iRequiredLevel != 0 && SH_GetClientLevel(client) < iRequiredLevel)
	{
		PrintToChat(client, "You cannot pick this Hero, their required level is %i.", iRequiredLevel);
		SetHeroesMenu(client);
		return true;
	}
	
	if (slot <= -1)
	{
		for (int i = 0; i < iCurrentHeroes[client]; i++)
		{
			if (iAssignedHero[client][i] == -1)
			{
				slot = i;
				break;
			}
		}
	}
	
	if (slot != -1 && iAssignedHero[client][slot] != -1)
	{
		RemoveClientHero(client, slot, "", false);
	}
	
	if (SH_IsClientHero(client, HeroID))
	{
		RemoveClientHero(client, -1, iHeroes[HeroID][Hero_Name], false);
	}
	
	iAssignedHero[client][slot] = HeroID;
	iCurrentHeroes[client]++;
	
	if (bVerbose)
	{
		PrintToChat(client, "Hero '%s' has been added to your roster.", iHeroes[HeroID][Hero_Name]);
	}
	
	if (cv_bLoadModels && strlen(iHeroes[HeroID][Hero_Model]) != 0 && FileExists(iHeroes[HeroID][Hero_Model]))
	{
		SetEntityModel(client, iHeroes[HeroID][Hero_Model]);
	}
	
	//Create a forward call for when a client is assigned a hero.
	Call_StartForward(hF_OnAssignedHero);
	Call_PushCell(client); //Client Index
	Call_PushCell(HeroID); //Hero ID/Index
	Call_PushString(iHeroes[HeroID][Hero_Name]); //Hero Name
	Call_PushString(iHeroes[HeroID][Hero_Description]); //Hero Description
	Call_PushCell(iRequiredLevel); //Required Level
	Call_PushString(iHeroes[HeroID][Hero_Model]); //Hero Model
	Call_Finish();
	
	return true;
}

//Remove a hero from the client.
bool RemoveClientHero(int client, int slot = -1, const char[] sHeroName = "", bool bVerbose = true)
{
	int HeroID;
	
	if (slot != -1)
	{
		HeroID = iAssignedHero[client][slot];
		
		if (HeroID <= -1)
		{
			return false;
		}
	}
	else	
	{
		for (int i = 0; i < cv_iClientHeroes; i++)
		{
			if (iAssignedHero[client][i] != -1)
			{
				char sLocalHeroName[MAX_HERO_NAME_LENGTH];
				SH_GetHeroName(iAssignedHero[client][i], sLocalHeroName, sizeof(sLocalHeroName));
				
				if (StrEqual(sHeroName, sLocalHeroName))
				{
					HeroID = iAssignedHero[client][i];
					slot = i;
					break;
				}
			}
		}
	}
	
	if (bVerbose)
	{
		PrintToChat(client, "Hero '%s' has been removed from your roster.", iHeroes[HeroID][Hero_Name]);
	}
	
	//Create a forward call for when a client is assigned a hero.
	Call_StartForward(hF_OnUnassignedHero);
	Call_PushCell(client); //Client Index
	Call_PushCell(HeroID); //Hero ID/Index
	Call_Finish();
	
	iAssignedHero[client][slot] = -1;
	iCurrentHeroes[client]--;
	
	return true;
}

//Parse all heroes in the config folder specified.
bool ParseHeroesConfigs(const char[] sConfigs)
{
	Handle hConfigs = OpenDirectory(sConfigs);
	
	if (hConfigs == INVALID_HANDLE)
	{
		return false;
	}
	
	FileType type; char sFile[PLATFORM_MAX_PATH];
	while (ReadDirEntry(hConfigs, sFile, sizeof(sFile), type))
	{
		//Not a file, is communist.
		if (type != FileType_File)
		{
			continue;
		}
		
		LoadSuperHeroConfig(sFile);
	}
	
	CloseHandle(hConfigs);
	
	return true;
}

//Load a specific hero config based on iteration, adding in fail safes just to be... fail safe.
bool LoadSuperHeroConfig(const char[] sFile)
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/%s/%s", cv_sConfigLocation, sFile);
	
	Handle hKV = CreateKeyValues("SuperHero");
	
	if (!FileToKeyValues(hKV, sPath))
	{
		LogError("Error parsing SuperHero config: [Missing File] - %s", sPath);
		CloseHandle(hKV);
		return false;
	}
	
	char sName[MAX_HERO_NAME_LENGTH];
	if (!KvGetString(hKV, "Name", sName, sizeof(sName)))
	{
		LogError("Error parsing SuperHero config: [Missing Name Field] - %s", sPath);
		CloseHandle(hKV);
		return false;
	}
	
	char sDescription[MAX_HERO_NAME_LENGTH];
	if (!KvGetString(hKV, "Description", sDescription, sizeof(sDescription)))
	{
		LogError("Error parsing SuperHero config: [Missing Description Field] - %s", sPath);
		CloseHandle(hKV);
		return false;
	}
	
	int iRequiredLevel = KvGetNum(hKV, "RequiredLevel", 0);
	if (iRequiredLevel < 0)
	{
		LogError("Error parsing SuperHero config: [RequiredLevel must not be a negative number.] - %s", sPath);
		iRequiredLevel = 0;
	}
	
	char sModel[MAX_HERO_NAME_LENGTH];
	KvGetString(hKV, "Model", sModel, sizeof(sModel));
	
	char sFlags[32];
	KvGetString(hKV, "Flags", sFlags, sizeof(sFlags));
	
	int HeroID = RegisterNewHero(INVALID_FUNCTION, SH_LOAD_CONFIG, INVALID_HANDLE, sName, sDescription, iRequiredLevel, sModel, sFlags);
	
	if (KvJumpToKey(hKV, "Abilities"))
	{
		KvGotoFirstSubKey(hKV, false);
		
		do {
			char sKey[MAX_ABILITY_NAME_LENGTH];
			KvGetSectionName(hKV, sKey, sizeof(sKey));
			
			if (SH_IsValidAbility(sKey))
			{
				int AbilityID = SH_GetAbilityID(sKey);
				switch (SH_AssignHeroAbility(HeroID, AbilityID))
				{
					case false: LogError("Error while assigning the ability '%s' to the Hero '%s', the ability doesn't exist.", sKey, sName);
				}
			}
			
		} while KvGotoNextKey(hKV, false);
		KvGoBack(hKV);
	}
	
	CloseHandle(hKV);
	return true;
}

int GetHeroID(const char[] sHeroName)
{
	for (int i = 0; i < iHeroesAmount; i++)
	{
		if (StrEqual(sHeroName, iHeroes[i][Hero_Name]))
		{
			return i;
		}
	}
	
	return -1;
}

bool IsClientHero(int client, int HeroID)
{
	for (int i = 0; i < iHeroesAmount; i++)
	{
		if (iAssignedHero[client][i] == HeroID)
		{
			return true;
		}
	}
	
	return false;
}

//////////////////
//Natives

//Register new heroes with this function then handle the new hero with other functions.
public int Native_RegisterHero(Handle hPlugin, int iParams)
{
	if (cv_iLoadType == 1)
	{
		return -1;
	}
	
	char sName[MAX_HERO_NAME_LENGTH];
	GetNativeString(2, sName, sizeof(sName));
	
	char sDescription[MAX_HERO_DESCRIPTION_LENGTH];
	GetNativeString(3, sDescription, sizeof(sDescription));
	
	int iRequiredLevel = GetNativeCell(4);
	
	char sModel[PLATFORM_MAX_PATH];
	GetNativeString(5, sModel, sizeof(sModel));
	
	char sFlags[32];
	GetNativeString(6, sFlags, sizeof(sFlags));
	
	return RegisterNewHero(view_as<SH_OnHeroRegistered>GetNativeFunction(1), SH_LOAD_PLUGIN, hPlugin, sName, sDescription, iRequiredLevel, sModel, sFlags);
}

//Retrieves the index of the hero the client is playing.
public int Native_GetClientHeroes(Handle hPlugin, int iParams)
{
	int client = GetNativeCell(1);
	
	if (!SH_IsValidPlayer(client, true))
	{
		return false;
	}
	
	int amount = iCurrentHeroes[client];
	
	if (amount < 1)
	{
		return false;
	}
	
	SetNativeArray(2, iAssignedHero[client], sizeof(amount));
	SetNativeCellRef(3, amount);
	
	return true;
}

//Adds an index of a new hero to the client.
public int Native_AddClientHero(Handle hPlugin, int iParams)
{
	int client = GetNativeCell(1);
	int slot = GetNativeCell(2);
	
	char sHeroName[MAX_HERO_NAME_LENGTH];
	GetNativeString(3, sHeroName, sizeof(sHeroName));
	
	if (!SH_IsValidPlayer(client, true) || strlen(sHeroName) == 0)
	{
		return false;
	}
	
	return MakeClientHero(client, slot, sHeroName, view_as<bool>GetNativeCell(4), view_as<bool>GetNativeCell(5));
}

//Removes an index of a hero from the client.
public int Native_RemoveClientHero(Handle hPlugin, int iParams)
{
	int client = GetNativeCell(1);
	int slot = GetNativeCell(2);
	
	char sHeroName[MAX_HERO_NAME_LENGTH];
	GetNativeString(3, sHeroName, sizeof(sHeroName));
	
	if (!SH_IsValidPlayer(client, true) || slot == -1 && strlen(sHeroName) == 0)
	{
		return false;
	}
	
	return RemoveClientHero(client, slot, sHeroName, view_as<bool>GetNativeCell(4));
}

//Checks if a client is a specified hero. This searches through all the heroes.
public int Native_IsClientHero(Handle hPlugin, int iParams)
{
	int client = GetNativeCell(1);
	int HeroID = GetNativeCell(2);
	
	if (!SH_IsValidPlayer(client, true) || HeroID < 0 || HeroID > MAX_HEROES)
	{
		return false;
	}
	
	return IsClientHero(client, HeroID);
}

//Converts a Heroes Name to a Heroes ID.
public int Native_GetHeroID(Handle hPlugin, int iParams)
{
	char sHeroName[MAX_HERO_NAME_LENGTH];
	GetNativeString(1, sHeroName, sizeof(sHeroName));
	
	return GetHeroID(sHeroName);
}

//Converts a Heroes ID to a Heroes Name.
public int Native_GetHeroName(Handle hPlugin, int iParams)
{
	int ID = GetNativeCell(1);
	
	if (ID < 0 || ID > iHeroesAmount)
	{
		return false;
	}
	
	SetNativeString(2, iHeroes[ID][Hero_Name], MAX_HERO_NAME_LENGTH);
	
	return true;
}

//Converts a Heroes ID to a Heroes Description.
public int Native_GetHeroDescription(Handle hPlugin, int iParams)
{
	int ID = GetNativeCell(1);
	
	if (ID < 0 || ID > iHeroesAmount)
	{
		return false;
	}
	
	SetNativeString(2, iHeroes[ID][Hero_Description], MAX_HERO_DESCRIPTION_LENGTH);
	
	return true;
}

//Converts a Heroes ID to a Heroes Required level.
public int Native_GetHeroRequiredLevel(Handle hPlugin, int iParams)
{
	int ID = GetNativeCell(1);
	
	if (ID < 0 || ID > iHeroesAmount)
	{
		return 0;
	}
	
	return iHeroes[ID][Hero_RequiredLevel];
}

//Converts a Heroes ID to a Heroes Model.
public int Native_GetHeroModel(Handle hPlugin, int iParams)
{
	int ID = GetNativeCell(1);
	
	if (ID < 0 || ID > iHeroesAmount)
	{
		return false;
	}
	
	SetNativeString(2, iHeroes[ID][Hero_Model], PLATFORM_MAX_PATH);
	
	return true;
}

//Checks if a specific HeroID is valid or in use.
public int Native_IsHeroValid(Handle hPlugin, int iParams)
{
	int ID = GetNativeCell(1);
	
	if (ID < 0 || ID > iHeroesAmount || strlen(iHeroes[ID][Hero_Name]) == 0)
	{
		return false;
	}
	
	return true;
} 
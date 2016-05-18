#pragma semicolon 1

//Includes
#include <sourcemod>
#include <sdktools>
#include <SH_Core>
#include <SH_Abilities>
#include <SH_Logging>

//New Syntax
#pragma newdecls required

//Defines
#define PLUGIN_AUTHOR "Keith Warren(Drixevel)"
#define PLUGIN_VERSION "1.0.0"

//#define DEBUG				//Enable/Disable Debugs
#define CONVAR_NUMBER 2		//Number of ConVars for this plugin.

//////////////////
//Globals

Handle hConVars[CONVAR_NUMBER];
bool cv_bStatus; int cv_iMaxBinds;

enum BindsData
{
	Input,
	String:Output[MAX_ABILITY_COMMAND_LENGTH]
}

//new iBinds[MAXPLAYERS + 1][BindsData];

bool bIsBinding[MAXPLAYERS + 1];
int iBind[MAXPLAYERS + 1];

bool bIsLateLoad;

//Plugin Info
public Plugin myinfo =
{
	name = "[SuperHeroes] Bindings",
	author = PLUGIN_AUTHOR,
	description = "Allows players to create and manage binds for abilities.",
	version = PLUGIN_VERSION,
	url = "http://www.drixevel.com/"
};

//Ask Plugin Load 2
public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrorSize)
{
	//CreateNative("SH_", Native_);
	
	RegPluginLibrary("SH_Bindings");
	
	bIsLateLoad = bLate;
	return APLRes_Success;
}

//On Plugin Start
public void OnPluginStart()
{
	hConVars[0] = CreateConVar("sm_superheroes_binds_status", "1", "Status of the plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[1] = CreateConVar("sm_superheroes_binds_max_binds", "6", "Maximum binds per client allowed.", FCVAR_NOTIFY, true, 1.0);
	
	for (int i = 0; i < sizeof(hConVars); i++)
	{
		HookConVarChange(hConVars[i], OnConVarsChanged);
	}
	
	RegConsoleCmd("sm_binds", OpenBinds);
	
	AutoExecConfig(true, "SH_Bindings", "superheroes");
}

//On Configs Executed
public void OnConfigsExecuted()
{
	cv_bStatus = GetConVarBool(hConVars[0]);
	cv_iMaxBinds = GetConVarInt(hConVars[1]);
	
	if (bIsLateLoad)
	{
		
		bIsLateLoad = false;
	}
}

//ConVar Changes
public void OnConVarsChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StrEqual(oldValue, newValue))
	{
		return;
	}
	
	int value = StringToInt(newValue);
	
	if (convar == hConVars[0])
	{
		cv_bStatus = view_as<bool>(value);
	}
	else if (convar == hConVars[1])
	{
		cv_iMaxBinds = value;
	}
}

//On Player Run Cmd
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (cv_bStatus && bIsBinding[client])
	{
		iBind[client] = buttons;
	}
}

public Action OpenBinds(int client, int args)
{
	OpenBindsMenu(client);
	return Plugin_Handled;
}

void OpenBindsMenu(int client)
{
	if (!cv_bStatus)
	{
		return;
	}
	
	Handle hMenu = CreateMenu(PlayerBindsMenuHandle);
	SetMenuTitle(hMenu, "SuperHero Binds");
	SetMenuExitBackButton(hMenu, true);
	
	AddMenuItem(hMenu, "Manage", "Manage Current Binds");
	AddMenuItem(hMenu, "Create", "Create New Binds");
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int PlayerBindsMenuHandle(Handle menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
			GetMenuItem(menu, slot, sInfo, sizeof(sInfo));
			
			if (StrEqual(sInfo, "Manage"))
			{
				Handle hMenu = CreateMenu(ManageBindsMenuHandle);
				SetMenuTitle(hMenu, "Current Binds");
				SetMenuExitBackButton(hMenu, true);
				
				for (int i = 0; i < cv_iMaxBinds; i++)
				{
					AddMenuItem(hMenu, "", "(empty)");
				}
				
				DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(sInfo, "Create"))
			{
				Handle hMenu = CreateMenu(CreateBindsMenuHandle);
				SetMenuExitBackButton(hMenu, true);
				
				AddMenuItem(hMenu, "", "Click on the key you would like to bind.", ITEMDRAW_DISABLED);
				
				DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
				
				bIsBinding[client] = true;
			}
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

public int ManageBindsMenuHandle(Handle menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
			GetMenuItem(menu, slot, sInfo, sizeof(sInfo));
			
		}
		
		case MenuAction_Cancel:
		{
			if (slot == MenuCancel_ExitBack)
			{
				OpenBindsMenu(client);
			}
		}
		
		case MenuAction_End:CloseHandle(menu);
	}
}

public int CreateBindsMenuHandle(Handle menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
			GetMenuItem(menu, slot, sInfo, sizeof(sInfo));
			
		}
		
		case MenuAction_Cancel:
		{
			if (slot == MenuCancel_ExitBack)
			{
				OpenBindsMenu(client);
			}
		}
		
		case MenuAction_End:CloseHandle(menu);
	}
}
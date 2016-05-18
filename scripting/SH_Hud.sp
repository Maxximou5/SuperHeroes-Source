#pragma semicolon 1

//Includes
#include <sourcemod>
#include <sdktools>
#include <SH_Core>
#include <SH_Progression>
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
bool cv_bStatus; int cv_iUpdateTime;

bool bIsLateLoad;

Handle hHudSync;

//Plugin Info
public Plugin myinfo =
{
	name = "[SuperHeroes] Hud",
	author = PLUGIN_AUTHOR,
	description = "Handles player hud elements and displays them.",
	version = PLUGIN_VERSION,
	url = "http://www.drixevel.com/"
};

//Ask Plugin Load 2
public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrorSize)
{
	//CreateNative("SH_", Native_);
	
	RegPluginLibrary("SH_Hud");
	
	bIsLateLoad = bLate;
	return APLRes_Success;
}

//On Plugin Start
public void OnPluginStart()
{
	hConVars[0] = CreateConVar("sm_superheroes_hud_status", "1", "Status of the plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[1] = CreateConVar("sm_superheroes_hud_update_time", "1", "Number of seconds to update HUD.", FCVAR_NOTIFY, true, 0.01);
	
	for (int i = 0; i < sizeof(hConVars); i++)
	{
		HookConVarChange(hConVars[i], OnConVarsChanged);
	}
	
	hHudSync = CreateHudSynchronizer();
	
	AutoExecConfig(true, "SH_Hud", "superheroes");
}

//On Configs Executed
public void OnConfigsExecuted()
{
	cv_bStatus = GetConVarBool(hConVars[0]);
	cv_iUpdateTime = GetConVarInt(hConVars[1]);
	
	if (bIsLateLoad)
	{
		
		bIsLateLoad = false;
	}
	
	if (cv_bStatus)
	{
		CreateTimer(float(cv_iUpdateTime), DisplayScreenHud, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
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
		cv_iUpdateTime = value;
	}
}

public Action DisplayScreenHud(Handle hTimer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!SH_IsValidPlayer(i, true))
		{
			continue;
		}
		
		DisplayClientHud(i);
	}
}

void DisplayClientHud(int client)
{
	char sHUD[64];
	Format(sHUD, sizeof(sHUD), "Level: %i", SH_GetClientLevel(client));
	
	SetHudTextParams(0.14, 0.90, 1.95, 100, 200, 255, 150, 0, 0.0, 0.0, 0.0);
	ShowSyncHudText(client, hHudSync, sHUD);
	
	PrintHintText(client, sHUD);
} 
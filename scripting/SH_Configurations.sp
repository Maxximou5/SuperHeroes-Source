#pragma semicolon 1

//Includes
#include <sourcemod>
#include <sdktools>
#include <SH_Core>
#include <SH_Configurations>
#include <SH_Logging>

//New Syntax
#pragma newdecls required

//Defines
#define PLUGIN_AUTHOR "Keith Warren(Drixevel)"
#define PLUGIN_VERSION "1.0.0"

//#define DEBUG				//Enable/Disable Debugs
#define CONVAR_NUMBER 4		//Number of ConVars for this plugin.

//////////////////
//Globals

Handle hConVars[CONVAR_NUMBER];
bool cv_bStatus; bool cv_bLoadType; char cv_sConfigLocation[PLATFORM_MAX_PATH]; char cv_sConfigurationName[256];

bool bIsLateLoad;

Handle hKV;

//Plugin Info
public Plugin myinfo =
{
	name = "[SuperHeroes] Configurations",
	author = PLUGIN_AUTHOR,
	description = "Allows hero modules to create and manage configurations.",
	version = PLUGIN_VERSION,
	url = "http://www.drixevel.com/"
};

//Ask Plugin Load 2
public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrorSize)
{
	CreateNative("SH_CreateConfig", Native_CreateConfig);
	
	RegPluginLibrary("SH_Configurations");
	
	bIsLateLoad = bLate;
	return APLRes_Success;
}

//On Plugin Start
public void OnPluginStart()
{
	hConVars[0] = CreateConVar("sm_superheroes_configs_status", "1", "Status of the plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[1] = CreateConVar("sm_superheroes_configs_loadtype", "0", "Method of loading configs and using them: (1 = config per hero plugin, 0 = one config for all)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[2] = CreateConVar("sm_superheroes_configs_location", "superheroes/", "Location of the configs folder. (relative to the configs folder)", FCVAR_NOTIFY);
	hConVars[3] = CreateConVar("sm_superheroes_configs_config_name", "superhero_configurations", "Name of the config to create & use if loadtype is 0.", FCVAR_NOTIFY);
	
	for (int i = 0; i < sizeof(hConVars); i++)
	{
		HookConVarChange(hConVars[i], OnConVarsChanged);
	}
	
	AutoExecConfig(true, "SH_Configurations", "superheroes");
}

//On Configs Executed
public void OnConfigsExecuted()
{
	cv_bStatus = GetConVarBool(hConVars[0]);
	cv_bLoadType = GetConVarBool(hConVars[1]);
	GetConVarString(hConVars[2], cv_sConfigLocation, sizeof(cv_sConfigLocation));
	GetConVarString(hConVars[3], cv_sConfigurationName, sizeof(cv_sConfigurationName));
	
	if (!cv_bStatus)
	{
		return;
	}
	
	if (bIsLateLoad || cv_bLoadType)
	{
		
		bIsLateLoad = false;
	}
	
	char sBuffer[PLATFORM_MAX_PATH];
	Format(sBuffer, sizeof(sBuffer), "configs/");
	
	if (strlen(cv_sConfigLocation) != 0)
	{
		Format(sBuffer, sizeof(sBuffer), "%s%s/", sBuffer, cv_sConfigLocation);
	}
	
	if (strlen(cv_sConfigurationName) != 0)
	{
		Format(sBuffer, sizeof(sBuffer), "%s%s.cfg", sBuffer, cv_sConfigurationName);
	}
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), sBuffer);
	
	hKV = CreateKeyValues("SuperHero_Configurations");
	KeyValuesToFile(hKV, sPath);
}

//ConVar Changes
public void OnConVarsChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	int value = StringToInt(newValue);
	
	if (convar == hConVars[0])
	{
		cv_bStatus = view_as<bool>value;
	}
	else if (convar == hConVars[1])
	{
		cv_bLoadType = view_as<bool>value;
	}
	else if (convar == hConVars[2])
	{
		strcopy(cv_sConfigLocation, sizeof(cv_sConfigLocation), newValue);
	}
	else if (convar == hConVars[3])
	{
		strcopy(cv_sConfigurationName, sizeof(cv_sConfigurationName), newValue);
	}
}

//OnPluginEnd
public void OnPluginEnd()
{
	CloseHandle(hKV);
}

void AddHeroConfig(Handle config, const char[] sName)
{
	KvJumpToKey(config, sName, true);
}

//////////////////
//Natives

//Register new heroes with this function then handle the new hero with other functions.
public int Native_CreateConfig(Handle hPlugin, int iParams)
{
	char sName[64];
	GetNativeString(0, sName, sizeof(sName));
	
	AddHeroConfig(hKV, sName);
}
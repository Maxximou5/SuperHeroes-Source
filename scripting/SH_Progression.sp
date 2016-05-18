#pragma semicolon 1

//Includes
#include <sourcemod>
#include <sdktools>
#include <SH_Core>
#include <SH_Heroes>
#include <SH_Progression>
#include <SH_Logging>

//New Syntax
#pragma newdecls required

//Defines
#define PLUGIN_AUTHOR "Keith Warren(Drixevel)"
#define PLUGIN_VERSION "1.0.0"

//#define DEBUG				//Enable/Disable Debugs
#define CONVAR_NUMBER 6		//Number of ConVars for this plugin.

//////////////////
//Globals

Handle hConVars[CONVAR_NUMBER];
bool cv_bStatus; char cv_sTableName[256]; bool cv_bSaveHeroes; int cv_iListHeroes; char cv_sConfigLocation[PLATFORM_MAX_PATH]; char cv_sConfigurationName[256];

bool bIsLateLoad;

//Query Strings
char sQ_Auth_Check[] = "SELECT level, experience FROM `%s` WHERE steamid = '%s';";
char sQ_Auth_Insert[] = "INSERT INTO `%s` (name, steamid, level, experience) VALUES ('%s', '%s', '%i', '0');";
char sQ_Auth_CreateTable[] = "CREATE TABLE IF NOT EXISTS `%s` (`id` int(11) NOT NULL auto_increment, `name` varchar(32) NOT NULL, `steamid` varchar(32) default NULL, `level` int(11) default NULL, `experience` int(11) default NULL, PRIMARY KEY  (`id`)) ENGINE = MyISAM  DEFAULT CHARSET = utf8;";
char sQ_Disc_Save[] = "UPDATE `%s` SET level = '%i', experience = '%i' WHERE steamid = '%s';";
char sQ_SaveHeroes_Start[] = "INSERT INTO `%s` VALUES (%s";
char sQ_SaveHeroes_End[] = "%s);";

int iLevel[MAXPLAYERS + 1];
int iExperience[MAXPLAYERS + 1];

Handle hExperience_Cache;
int iStartingLevel;
int iMaxLevel;

int iXP_Kill; int iXP_Death; int iXP_Assist;

//Plugin Info
public Plugin myinfo =
{
	name = "[SuperHeroes] Progression",
	author = PLUGIN_AUTHOR,
	description = "Module that handles player progression and saves it to database and/or configs.",
	version = PLUGIN_VERSION,
	url = "http://www.drixevel.com/"
};

//Ask Plugin Load 2
public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrorSize)
{
	CreateNative("SH_GetClientLevel", Native_GetClientLevel);
	CreateNative("SH_GetClientExperience", Native_GetClientExperience);
	CreateNative("SH_AddExperience", Native_AddExperience);
	CreateNative("SH_GetStartingLevel", Native_GetStartingLevel);
	CreateNative("SH_GetMaxLevel", Native_GetMaxLevel);
	CreateNative("SH_SaveClientHeroes", Native_SaveClientHeroes);
	
	RegPluginLibrary("SH_Progression");
	
	bIsLateLoad = bLate;
	return APLRes_Success;
}

//On Plugin Start
public void OnPluginStart()
{
	hConVars[0] = CreateConVar("sm_superheroes_progress_status", "1", "Status of the plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[1] = CreateConVar("sm_superheroes_progress_table_progression", "superheroes_progression", "Name of the table to use for level progression.", FCVAR_NOTIFY);
	hConVars[2] = CreateConVar("sm_superheroes_progress_save_heroes", "1", "Save clients current heroes and make them those heroes on reconnect.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[3] = CreateConVar("sm_superheroes_progress_list_heroes", "1", "Method of listing heroes with the plugin. (1 = menu, 2 = chat)", FCVAR_NOTIFY, true, 1.0, true, 2.0);
	hConVars[4] = CreateConVar("sm_superheroes_progress_location", "superheroes/", "Location of the configs folder. (relative to the configs folder)", FCVAR_NOTIFY);
	hConVars[5] = CreateConVar("sm_superheroes_progress_config_name", "superhero_progression", "Name of the config to create and use if loadtype is 0.", FCVAR_NOTIFY);
	
	for (int i = 0; i < sizeof(hConVars); i++)
	{
		HookConVarChange(hConVars[i], OnConVarsChanged);
	}
	
	RegConsoleCmd("sm_progress", ShowClientProgress);
	RegAdminCmd("sm_givexp", GiveClientExperience, ADMFLAG_ROOT);
	RegAdminCmd("sm_setlevel", SetLevel, ADMFLAG_ROOT);
	
	HookEvent("player_death", OnPlayerDeath);
	
	hExperience_Cache = CreateTrie();
	
	AutoExecConfig(true, "SH_Progression", "superheroes");
}

//On Configs Executed
public void OnConfigsExecuted()
{
	cv_bStatus = GetConVarBool(hConVars[0]);
	GetConVarString(hConVars[1], cv_sTableName, sizeof(cv_sTableName));
	cv_bSaveHeroes = GetConVarBool(hConVars[2]);
	cv_iListHeroes = GetConVarInt(hConVars[3]);
	GetConVarString(hConVars[4], cv_sConfigLocation, sizeof(cv_sConfigLocation));
	GetConVarString(hConVars[5], cv_sConfigurationName, sizeof(cv_sConfigurationName));
	
	if (!cv_bStatus)
	{
		return;
	}
	
	if (bIsLateLoad)
	{
		
		bIsLateLoad = false;
	}
	
	CreateLevelProgression();
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
	else if (convar == hConVars[0])
	{
		strcopy(cv_sTableName, sizeof(cv_sTableName), newValue);
	}
	else if (convar == hConVars[1])
	{
		cv_bSaveHeroes = view_as<bool>(value);
	}
	else if (convar == hConVars[2])
	{
		cv_iListHeroes = value;
	}
	else if (convar == hConVars[3])
	{
		strcopy(cv_sConfigLocation, sizeof(cv_sConfigLocation), newValue);
	}
	else if (convar == hConVars[4])
	{
		strcopy(cv_sConfigurationName, sizeof(cv_sConfigurationName), newValue);
	}
}

//On All Plugins Loaded
public void OnAllPluginsLoaded()
{
	SH_AddMainMenuItem("Progress", _, Menu_Progress, 3);
}

public void Menu_Progress(int client, const char[] value)
{
	ShowProgressMenu(client);
}

void ShowProgressMenu(int client)
{
	Handle hMenu = CreateMenu(ProgressMenuHandle);
	SetMenuTitle(hMenu, "Your Progress");
	SetMenuExitBackButton(hMenu, true);
	
	char sLevel[64];
	IntToString(iLevel[client], sLevel, sizeof(sLevel));
	
	int XP_Req;
	GetTrieValue(hExperience_Cache, sLevel, XP_Req);
	
	char sDisplay[64];
	
	Format(sDisplay, sizeof(sDisplay), "Next Level: [%i/%i]", iExperience[client], XP_Req);
	AddMenuItem(hMenu, "", sDisplay);
	
	Format(sDisplay, sizeof(sDisplay), "Current Level: %i", iLevel[client]);
	AddMenuItem(hMenu, "", sDisplay);
	
	Format(sDisplay, sizeof(sDisplay), "List Heroes");
	AddMenuItem(hMenu, "ListHeroes", sDisplay);
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int ProgressMenuHandle(Handle menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
			GetMenuItem(menu, slot, sInfo, sizeof(sInfo));
			
			if (StrEqual(sInfo, "ListHeroes"))
			{
				ListHeroes(client);
			}
			else
			{
				ShowProgressMenu(client);
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

void ListHeroes(int client)
{
	switch (cv_iListHeroes)
	{
		case 1:
		{
			Handle hMenu = CreateMenu(ListHeroesMenuHandle);
			SetMenuTitle(hMenu, "Current Heroes");
			SetMenuExitButton(hMenu, true);
			
			int heroes[MAX_HEROES]; int amount;
			if (SH_GetClientHeroes(client, heroes, amount))
			{
				for (int i = 0; i < amount; i++)
				{
					char sName[MAX_HERO_NAME_LENGTH];
					SH_GetHeroName(heroes[i], sName, sizeof(sName));
					
					char sDescription[MAX_HERO_NAME_LENGTH];
					SH_GetHeroDescription(heroes[i], sDescription, sizeof(sDescription));
					
					AddMenuItem(hMenu, sDescription, sName);
				}
				
				DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
			}
		}
		
		case 2:
		{
			int heroes[MAX_HEROES]; int amount;
			if (SH_GetClientHeroes(client, heroes, amount))
			{
				char sBuffer[1024];
				Format(sBuffer, sizeof(sBuffer), "Current Heroes: ");
				
				int inx = 0;
				for (int i = 0; i < amount; i++)
				{
					char sName[MAX_HERO_NAME_LENGTH];
					SH_GetHeroName(heroes[i], sName, sizeof(sName));
					
					if (inx > 0)
					{
						Format(sBuffer, sizeof(sBuffer), "%s, %s", sBuffer, sName);
					}
					else
					{
						Format(sBuffer, sizeof(sBuffer), "%s%s", sBuffer, sName);
						inx++;
					}
				}
				
				PrintToChat(client, sBuffer);
			}
			else
			{
				PrintToChat(client, "You currently have no heroes equipped.");
			}
		}
	}
}

public int ListHeroesMenuHandle(Handle menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
			GetMenuItem(menu, slot, sInfo, sizeof(sInfo));
			
			PrintToChat(client, "Description: %s", sInfo);
			ListHeroes(client);
		}
		
		case MenuAction_End:CloseHandle(menu);
	}
}

public void SH_OnDatabaseConnected()
{
	char sQuery[MAX_QUERY_SIZE];
	Format(sQuery, sizeof(sQuery), sQ_Auth_CreateTable, cv_sTableName);
	SH_Query(sQuery);
}

public void OnPlayerDeath(Handle hEvent, char[] sName, bool bBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	int assister = GetClientOfUserId(GetEventInt(hEvent, "assister"));
	
	if (client == attacker)
	{
		return;
	}
	
	char sLevel[64]; char sNegOrPos[32]; int XP_Req;
	
	//Kills
	if (!IsFakeClient(attacker) && iXP_Kill != 0)
	{
		IntToString(iLevel[attacker], sLevel, sizeof(sLevel));
		GetTrieValue(hExperience_Cache, sLevel, XP_Req);
		
		Format(sNegOrPos, sizeof(sNegOrPos), "%s", view_as<bool>(iXP_Kill > -1) ? "gained" : "lost");
		
		AddClientExperience(attacker, iXP_Kill);
		PrintToChat(attacker, "You have %s %i experience for killing %N. Current Level: %i - Next Level: [%i/%i]", sNegOrPos, iXP_Kill, client, iLevel[attacker], iExperience[attacker], XP_Req);
	}
	
	//Assists
	if (assister != 0 && !IsFakeClient(assister) && iXP_Assist != 0)
	{
		IntToString(iLevel[assister], sLevel, sizeof(sLevel));
		GetTrieValue(hExperience_Cache, sLevel, XP_Req);
		
		Format(sNegOrPos, sizeof(sNegOrPos), "%s", view_as<bool>(iXP_Assist > -1) ? "gained" : "lost");
		
		AddClientExperience(assister, iXP_Assist);
		PrintToChat(assister, "You have %s %i experience for assisting %N to killing %N. Current Level: %i - Next Level: [%i/%i]", sNegOrPos, iXP_Assist, attacker, client, iLevel[assister], iExperience[assister], XP_Req);
	}
	
	//Deaths
	if (!IsFakeClient(client) && iXP_Death != 0)
	{
		IntToString(iLevel[client], sLevel, sizeof(sLevel));
		GetTrieValue(hExperience_Cache, sLevel, XP_Req);
		
		Format(sNegOrPos, sizeof(sNegOrPos), "%s", view_as<bool>(iXP_Death > -1) ? "gained" : "lost");
		
		AddClientExperience(client, iXP_Death);
		PrintToChat(client, "You have %s %i experience for dying to %N. Current Level: %i - Next Level: [%i/%i]", sNegOrPos, iXP_Death, attacker, iLevel[client], iExperience[client], XP_Req);
	}
}

public void OnClientAuthorized(int client, const char[] sAuth)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	Handle hPack = CreateDataPack();
	WritePackCell(hPack, GetClientUserId(client));
	WritePackString(hPack, sAuth);
	
	char sQuery[MAX_QUERY_SIZE];
	Format(sQuery, sizeof(sQuery), sQ_Auth_Check, cv_sTableName, sAuth);
	SH_TQuery(ParseClientSHData, sQuery, hPack);
}

public int ParseClientSHData(Handle owner, Handle hndl, const char[] sError, any data)
{
	ResetPack(data);
	
	int client = GetClientOfUserId(ReadPackCell(data));
	
	char sAuth[32];
	ReadPackString(data, sAuth, sizeof(sAuth));
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("Error parsing SQL data for client '%L': %s", client, sError);
		CloseHandle(data);
		return;
	}
	
	if (SQL_FetchRow(hndl))
	{
		iLevel[client] = SQL_FetchInt(hndl, 0);
		iExperience[client] = SQL_FetchInt(hndl, 1);
		
		if (SH_IsValidPlayer(client, true))
		{
			PrintToChat(client, "Progression data retrieved successfully!");
		}
		
		SH_Log("Client '%L' connected successfully with level %i.", client, iLevel[client]);
		CloseHandle(data);
	}
	else
	{
		char sName[MAX_NAME_LENGTH];
		GetClientName(client, sName, sizeof(sName));
		
		char sQuery[MAX_QUERY_SIZE];
		Format(sQuery, sizeof(sQuery), sQ_Auth_Insert, cv_sTableName, sName, sAuth, iStartingLevel);
		SH_TQuery(CreateClientSHData, sQuery, data);
	}
}

public int CreateClientSHData(Handle owner, Handle hndl, const char[] sError, any data)
{
	ResetPack(data);
	
	int client = GetClientOfUserId(ReadPackCell(data));
	
	char sAuth[32];
	ReadPackString(data, sAuth, sizeof(sAuth));
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("Error creating SQL data for client '%L': %s", client, sError);
		CloseHandle(data);
		return;
	}
	
	iLevel[client] = iStartingLevel;
	
	char sQuery[MAX_QUERY_SIZE];
	Format(sQuery, sizeof(sQuery), sQ_Auth_Check, cv_sTableName, sAuth);
	SH_TQuery(ParseClientSHData, sQuery, data);
}

public void OnClientDisconnect(int client)
{
	int heroes[MAX_HEROES]; int amount;
	if (SH_GetClientHeroes(client, heroes, amount))
	{
		SaveClientCurrentHeroes(client, heroes, amount);
	}
	
	if (!IsFakeClient(client))
	{
		char sAuth[32];
		GetClientAuthId(client, AuthId_Steam2, sAuth, sizeof(sAuth));
		
		char sQuery[MAX_QUERY_SIZE];
		Format(sQuery, sizeof(sQuery), sQ_Disc_Save, cv_sTableName, iLevel[client], iExperience[client], sAuth);
		SH_TQuery(SaveClientSHData, sQuery);
	}
}

public int SaveClientSHData(Handle owner, Handle hndl, const char[] sError, any data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Error saving SQL data: %s", sError);
	}
}

//Saves a clients current hero to database.
void SaveClientCurrentHeroes(int client, int[] heroes, int amount)
{
	if (!cv_bSaveHeroes || IsFakeClient(client))
	{
		return;
	}
	
	char sAuthID[32];
	GetClientAuthId(client, AuthId_Steam2, sAuthID, sizeof(sAuthID));
	
	char sQuery[MAX_QUERY_SIZE];
	Format(sQuery, sizeof(sQuery), sQ_SaveHeroes_Start, cv_sTableName, sAuthID);
	
	for (int i = 0; i < amount; i++)
	{
		char sName[MAX_HERO_NAME_LENGTH];
		SH_GetHeroName(heroes[i], sName, sizeof(sName));
		
		Format(sQuery, sizeof(sQuery), "%s, %s", sQuery, sName);
	}
	
	Format(sQuery, sizeof(sQuery), sQ_SaveHeroes_End, sQuery);
	SH_Query(sQuery);
}

public Action ShowClientProgress(int client, int args)
{
	PrintToChat(client, "Level: %i, Experience: %i", iLevel[client], iExperience[client]);
	return Plugin_Handled;
}

public Action GiveClientExperience(int client, int args)
{
	char sArg[64];
	GetCmdArg(1, sArg, sizeof(sArg));
	
	char sArg2[64];
	GetCmdArg(2, sArg2, sizeof(sArg2));
	
	char sTargetName[MAX_TARGET_LENGTH]; int iList[MAXPLAYERS]; bool bML;
	int iCount = ProcessTargetString(sArg, client, iList, MAXPLAYERS, COMMAND_FILTER_ALIVE, sTargetName, sizeof(sTargetName), bML);
	
	if (iCount <= 0)
	{
		ReplyToTargetError(client, iCount);
		return Plugin_Handled;
	}
	
	int experience = StringToInt(sArg2);
	
	for (int i = 0; i < iCount; i++)
	{
		AddClientExperience(iList[i], experience);
	}
	
	PrintToChat(client, "Client(s) have had %i added to their experience.", experience);
	
	return Plugin_Handled;
}

public Action SetLevel(int client, int args)
{
	char sArg[64];
	GetCmdArg(1, sArg, sizeof(sArg));
	
	char sArg2[64];
	GetCmdArg(2, sArg2, sizeof(sArg2));
	
	char sTargetName[MAX_TARGET_LENGTH]; int iList[MAXPLAYERS]; bool bML;
	int iCount = ProcessTargetString(sArg, client, iList, MAXPLAYERS, COMMAND_FILTER_ALIVE, sTargetName, sizeof(sTargetName), bML);
	
	if (iCount <= 0)
	{
		ReplyToTargetError(client, iCount);
		return Plugin_Handled;
	}
	
	int level = StringToInt(sArg2);
	
	for (int i = 0; i < iCount; i++)
	{
		SetClientLevel(iList[i], level);
	}
	
	PrintToChat(client, "Client(s) have been set to level %i.", level);
	
	return Plugin_Handled;
}

void CreateLevelProgression()
{
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
	
	Handle hKV = CreateKeyValues("SuperHero_Progression");
	
	if (!FileToKeyValues(hKV, sPath))
	{
		LogError("Error parsing keyvalues, please verify config integrity.");
		return;
	}
	
	iStartingLevel = KvGetNum(hKV, "starting_level", 1);
	iMaxLevel = KvGetNum(hKV, "maximum_level", 1);
	
	if (KvJumpToKey(hKV, "experience") && KvGotoFirstSubKey(hKV, false))
	{
		do {
			char sLevel[32];
			KvGetSectionName(hKV, sLevel, sizeof(sLevel));
			
			int iExp = KvGetNum(hKV, NULL_STRING);
			
			SetTrieValue(hExperience_Cache, sLevel, iExp);
			
		} while (KvGotoNextKey(hKV, false));
		
		KvRewind(hKV);
	}
	else
	{
		LogError("Error parsing experience keyvalues, please verify config integrity.");
	}
	
	if (KvJumpToKey(hKV, "progression"))
	{
		iXP_Kill = KvGetNum(hKV, "kills", 20);
		iXP_Death = KvGetNum(hKV, "deaths", 0);
		iXP_Assist = KvGetNum(hKV, "assists", 5);
		
		KvGoBack(hKV);
	}
	else
	{
		LogError("Error parsing progression keyvalues, please verify config integrity.");
	}
	
	CloseHandle(hKV);
}

void AddClientExperience(int client, int XP)
{
	if (!SH_IsValidPlayer(client, true) || XP == 0 || iLevel[client] == iMaxLevel)
	{
		return;
	}
	
	iExperience[client] += XP;
	
	char sLevel[64];
	IntToString(iLevel[client], sLevel, sizeof(sLevel));
	
	int XP_Req;
	GetTrieValue(hExperience_Cache, sLevel, XP_Req);
	
	if (iExperience[client] < 0)
	{
		iExperience[client] = 0;
	}
	else if (iExperience[client] > XP_Req)
	{
		iExperience[client] -= XP_Req;
		iLevel[client]++;
		
		PrintToChat(client, "You have reached level %i!", iLevel[client]);
	}
}

void SetClientLevel(int client, int Level)
{
	if (!SH_IsValidPlayer(client, true) || Level <= 0 || Level > iMaxLevel)
	{
		return;
	}
	
	iLevel[client] = Level;
	PrintToChat(client, "Your level has been set to %i.", Level);
}

//////////////////
//Natives

//Retrieves the clients current level.
public int Native_GetClientLevel(Handle hPlugin, int iParams)
{
	int client = GetNativeCell(1);
	
	if (!SH_IsValidPlayer(client, true))
	{
		return -1;
	}
	
	return iLevel[client];
}

//Retrieves the clients current experience.
public int Native_GetClientExperience(Handle hPlugin, int iParams)
{
	int client = GetNativeCell(1);
	
	if (!SH_IsValidPlayer(client, true))
	{
		return -1;
	}
	
	return iExperience[client];
}

//Gives a player experience, handles all the data if they level up or not, etc.
public int Native_AddExperience(Handle hPlugin, int iParams)
{
	int client = GetNativeCell(1);
	
	if (!SH_IsValidPlayer(client, true))
	{
		return;
	}
	
	AddClientExperience(client, GetNativeCell(2));
}

//Retrieve the starting level defined by the config entry for players to start at.
public int Native_GetStartingLevel(Handle hPlugin, int iParams)
{
	return iStartingLevel;
}

//Retrieves the maximum level defined by the config that players can reach.
public int Native_GetMaxLevel(Handle hPlugin, int iParams)
{
	return iMaxLevel;
}

//Saves all client heroes to database.
public int Native_SaveClientHeroes(Handle hPlugin, int iParams)
{
	int client = GetNativeCell(1);
	
	int heroes[MAX_HEROES]; int amount;
	if (SH_GetClientHeroes(client, heroes, amount))
	{
		SaveClientCurrentHeroes(client, heroes, amount);
		
		return true;
	}
	
	return false;
}
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <SH_Heroes>
#include <SH_Abilities>

//New Syntax
#pragma newdecls required

//Globals
int Hero;
int Ability;
bool change[MAXPLAYERS + 1];
char sCurrent[MAXPLAYERS + 1][PLATFORM_MAX_PATH];

Handle hCounterTerroristModels;
Handle hTerroristModels;

public void OnPluginStart()
{
	hCounterTerroristModels = CreateArray(ByteCountToCells(PLATFORM_MAX_PATH));
	hTerroristModels = CreateArray(ByteCountToCells(PLATFORM_MAX_PATH));
	
	HookEvent("player_spawn", OnPlayerSpawn);
}

public void OnMapStart()
{
	ClearArray(hCounterTerroristModels);
	ClearArray(hTerroristModels);
}

public void SH_OnReady()
{
	SH_RegisterHero(OnHeroCreated, "Mystique", "Allows you to shapeshift into different forms.", 1, "", "");
}

public void OnHeroCreated(int HeroID, const char[] sName, const char[] sDescription, int iRequiredLevel, const char[] sModel, const char[] sFlags)
{
	Hero = HeroID;
	
	Ability = SH_RegisterAbility("Shapeshifting", "Shapeshifting", "Allows you to shapeshift into different forms.", 15, OnAbilityUse);
	SH_AssignHeroAbility(Hero, Ability);
	
	SH_CreateAbilityCommand(Ability, "Shapeshifting");
}

public void OnAbilityUse(int client, int HeroID, const char[] sName, const char[] sDisplayName, const char[] sDescription)
{
	switch (GetClientTeam(client))
	{
		//Terrorist
		case 2:
		{
			if (change[client])
			{
				SetEntityModel(client, sCurrent[client]);
				change[client] = false;
			}
			else
			{
				int arraysize = GetArraySize(hTerroristModels);
				
				if (arraysize == 0)
				{
					return;
				}
				
				GetClientModel(client, sCurrent[client], PLATFORM_MAX_PATH);
				
				int random = GetRandomInt(0, arraysize);
				
				char sNewModel[PLATFORM_MAX_PATH];
				GetArrayString(hTerroristModels, random, sNewModel, sizeof(sNewModel));
				
				SetEntityModel(client, sNewModel);
				change[client] = true;
			}
		}
		//Counter-Terrorist
		case 3:
		{
			if (change[client])
			{
				SetEntityModel(client, sCurrent[client]);
				change[client] = false;
			}
			else
			{
				int arraysize = GetArraySize(hCounterTerroristModels);
				
				if (arraysize == 0)
				{
					return;
				}
				
				GetClientModel(client, sCurrent[client], PLATFORM_MAX_PATH);
				
				int random = GetRandomInt(0, arraysize);
				
				char sNewModel[PLATFORM_MAX_PATH];
				GetArrayString(hCounterTerroristModels, random, sNewModel, sizeof(sNewModel));
				
				SetEntityModel(client, sNewModel);
				change[client] = true;
			}
		}
	}
	
	PrintHintText(client, "Disguise : %s", change[client] ? "On" : "Off");
}

public void OnPlayerSpawn(Handle hEvent, char[] sName, bool bBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		char sPlayerModel[PLATFORM_MAX_PATH];
		GetClientModel(client, sPlayerModel, sizeof(sPlayerModel));
		
		switch (GetClientTeam(client))
		{
			//Terrorist
			case 2:
			{
				if (!FindStringInArray(hTerroristModels, sPlayerModel))
				{
					PushArrayString(hTerroristModels, sPlayerModel);
				}
			}
			//Counter-Terrorist
			case 3:
			{
				if (!FindStringInArray(hCounterTerroristModels, sPlayerModel))
				{
					PushArrayString(hCounterTerroristModels, sPlayerModel);
				}
			}
		}
	}
}
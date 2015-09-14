#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <SH_Core>
#include <SH_Heroes>
#include <SH_Abilities>

//New Syntax
#pragma newdecls required

//Globals
int Hero;
int Ability;
bool bDucking[MAXPLAYERS + 1];
float burypos[MAXPLAYERS + 1][3];
float oldpos[MAXPLAYERS + 1][3];

public void OnPluginStart()
{
	
}

public void SH_OnReady()
{
	Hero = SH_RegisterHero("Sandman", "Bury your enemies for 5 seconds.", 1, "", "");
	
	Ability = SH_RegisterAbility("BuryEnemies", "Bury Enemies", "Bury enemies in the ground.", 5, OnAbilityUse);
	SH_AssignHeroAbility(Hero, Ability);
	
	SH_CreateAbilityCommand(Ability, "buryenemies");
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	bDucking[client] = (buttons & IN_DUCK) ? true : false;
	return Plugin_Continue;
}

public void OnAbilityUse(int client, int HeroID, const char[] sName, const char[] sDisplayName, const char[] sDescription)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!SH_IsValidPlayer(i, true) || bDucking[i])
		{
			continue;
		}
		
		if (SH_GetTargetInViewCone(client, i, 23.0, 800.0))
		{
			GetClientAbsOrigin(i, oldpos[i]);
			GetClientAbsOrigin(i, burypos[i]);
			
			CreateTimer(0.1, GetBuriedSon, GetClientUserId(i), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			
			SetEntPropFloat(i, Prop_Data, "m_flSpeed", 0.0);
			
			SetEntityRenderColor(i, 255, 200, 0, 255);
		}
	}
}

public Action GetBuriedSon(Handle hTimer, any data)
{
	int client = GetClientOfUserId(data);
	
	if (!SH_IsValidPlayer(client, true))
	{
		return Plugin_Stop;
	}
	
	burypos[client][2]--;
	TeleportEntity(client, burypos[client], NULL_VECTOR, NULL_VECTOR);
	
	if (burypos[client][2] > oldpos[client][2] - 55 && IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	else
	{
		CreateTimer(4.0, GetTheFuckOutOfTheGround, data);
		return Plugin_Stop;
	}
}

public Action GetTheFuckOutOfTheGround(Handle hMenu, any data)
{
	int client = GetClientOfUserId(data);
	
	if (SH_IsValidPlayer(client, true))
	{
		TeleportEntity(client, oldpos[client], NULL_VECTOR, NULL_VECTOR);
		SetEntPropFloat(client, Prop_Data, "m_flSpeed", 1.0);
	}
}
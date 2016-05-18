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

public void OnPluginStart()
{
	
}

public void SH_OnReady()
{
	SH_RegisterHero(OnHeroCreated, "Sandman", "Bury your enemies for 5 seconds.");
}

public void OnHeroCreated(int HeroID, const char[] sName, const char[] sDescription, int iRequiredLevel, const char[] sModel, const char[] sFlags)
{
	Hero = HeroID;
	
	Ability = SH_RegisterAbility("BuryEnemies", "Bury Enemies", "Bury enemies in the ground.", 5, OnAbilityUse);
	SH_AssignHeroAbility(Hero, Ability);
	
	SH_CreateAbilityCommand(Ability, "buryenemies");
}

public void OnAbilityUse(int client, int HeroID, const char[] sName, const char[] sDisplayName, const char[] sDescription)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && client != i && GetClientTeam(client) != GetClientTeam(i) && SH_GetTargetInViewCone(client, i, 23.0, 800.0))
		{
			float fPos[3];
			GetClientAbsOrigin(i, fPos);
			
			fPos[2] -= 5.0;
			TeleportEntity(i, fPos, NULL_VECTOR, NULL_VECTOR);
			
			CreateTimer(5.0, UnburyClient, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action UnburyClient(Handle hTimer, any data)
{
	int client = GetClientOfUserId(data);
	
	if (SH_IsValidPlayer(client, false, true))
	{
		float fPos[3];
		GetClientAbsOrigin(client, fPos);
		
		fPos[2] += 5.0;
		TeleportEntity(client, fPos, NULL_VECTOR, NULL_VECTOR);
	}
}
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
bool bNoclip[MAXPLAYERS + 1];
float oldpos[66][3];
float newpos[66][3];
float sectemp[66];
float skill_sec=6.0;

public void OnPluginStart()
{
	
}

public void SH_OnReady()
{
	SH_RegisterHero(OnHeroCreated, "Nightcrawler", "Teleport through walls.");
}

public void OnHeroCreated(int HeroID, const char[] sName, const char[] sDescription, int iRequiredLevel, const char[] sModel, const char[] sFlags)
{
	Hero = HeroID;
	
	Ability = SH_RegisterAbility("TeleportNoclip", "Teleport Noclip", "Teleport thorugh walls.", 15, OnAbilityUse);
	SH_AssignHeroAbility(Hero, Ability);
	
	SH_CreateAbilityCommand(Ability, "teleportnoclip");
}

public void OnAbilityUse(int client, int HeroID, const char[] sName, const char[] sDisplayName, const char[] sDescription)
{
	if (!bNoclip[client])
	{
		GetClientAbsOrigin(client, oldpos[client]);
		bNoclip[client] = true;
		sectemp[client] = skill_sec;
		SetEntityMoveType(client, MOVETYPE_NOCLIP);
		CreateTimer(0.0, TurnNoClip, client);
	}
}

public Action TurnNoClip(Handle hTimer, any client)
{
	if (sectemp[client] < 1.0)
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
		GetClientAbsOrigin(client, newpos[client]);
		newpos[client][2] += 1.0;
		TeleportEntity(client, newpos[client], NULL_VECTOR, NULL_VECTOR);
		bNoclip[client] = false;
		CreateTimer(0.1, ChkStuck, client);
	}
	else
	{
		PrintCenterText(client, "Warning: Time limit : %.0f sec", sectemp[client]);
		sectemp[client] -= 1.0;
		CreateTimer(1.0, TurnNoClip, client);
	}
}

public Action ChkStuck(Handle hTimer, any client)
{
	float location[3];
	GetClientAbsOrigin(client, location);
	
	if (GetVectorDistance(newpos[client], location) < 0.001)
	{
		PrintHintText(client, "You stucked, Teleport Old position");
		TeleportEntity(client, oldpos[client], NULL_VECTOR, NULL_VECTOR);
	}
}
#pragma semicolon 1

#include <sourcemod>
#include <SH_Heroes>

//New Syntax
#pragma newdecls required

//Globals
int Hero;

public void OnPluginStart()
{
	HookEvent("player_spawn", OnPlayerSpawn);
}

public void SH_OnReady()
{
	Hero = SH_RegisterHero("Flash", "Allows you to run faster.", 1, "", "");
}

public void SH_OnAssignedHero(int client, int HeroID, const char[] sName, const char[] sDescription, int iRequiredLevel, const char[] sModel)
{
	if (HeroID == Hero)
	{
		SetClientSpeed(client, 2.0);
	}
}

public void SH_OnUnassignedHero(int client, int HeroID)
{
	if (HeroID == Hero)
	{
		SetClientSpeed(client, 1.0);
	}
}

public void OnPlayerSpawn(Handle hEvent, char[] sName, bool bBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (!SH_IsClientHero(client, Hero))
	{
		SetClientSpeed(client, 1.0);
		return;
	}
	
	SetClientSpeed(client, 2.0);
}

void SetClientSpeed(int client, float speed)
{
    SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed);
}
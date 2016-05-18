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
	Hero = SH_RegisterHero(INVALID_FUNCTION, "Flash", "Allows you to run faster.");
}

public void SH_OnAssignedHero(int client, int HeroID, const char[] sName, const char[] sDescription, int iRequiredLevel, const char[] sModel)
{
	if (HeroID == Hero)
	{
		SetClientSpeed(client, 1.5);
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
	
	SetClientSpeed(client, 1.5);
}

void SetClientSpeed(int client, float speed)
{
    SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed);
}
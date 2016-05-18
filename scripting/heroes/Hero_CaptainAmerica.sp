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

public void OnPluginStart()
{
	
}

public void SH_OnReady()
{
	Hero = SH_RegisterHero(INVALID_FUNCTION, "Captain America", "Block damage from enemies at random.");
}

public Action SH_OnTakeDamage(int client, int attacker, int inflictor, float damage, int damagetype, int weapon, float damageForce[3], float damagePosition[3])
{
	if (SH_IsValidPlayer(client, true, true) && SH_IsValidPlayer(attacker) && client != attacker && GetClientTeam(client) != GetClientTeam(attacker) && SH_IsClientHero(client, Hero))
	{
		if (GetRandomFloat(0.0, 1.0) <= 0.3)
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}
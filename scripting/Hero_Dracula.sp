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
int BeamSprite;

public void OnPluginStart()
{
	
}

public void SH_OnReady()
{
	Hero = SH_RegisterHero("Dracula", "Gain a percentage of health from damaged enemies.", 1, "", "");
}

public void OnMapStart()
{
	BeamSprite = PrecacheModel("materials/sprites/lgtning.vmt");
}

public void SH_OnTakeDamage_Post(int client, int attacker, int inflictor, float damage, int damagetype, int weapon, float damageForce[3], float damagePosition[3])
{
	if (SH_IsValidPlayer(client, true, true) && SH_IsValidPlayer(attacker, true) && client != attacker && GetClientTeam(client) != GetClientTeam(attacker))
	{
		if (!SH_IsClientHero(client, Hero))
		{
			return;
		}
		
		float percent_health = 0.25;
		int leechhealth = RoundToFloor(damage * percent_health);
		
		if (leechhealth > 40)
		{
			leechhealth = 40;
		}
		
		float fClientOrigin[3];
		GetClientAbsOrigin(client, fClientOrigin);
		fClientOrigin[2] += 15.0;
		
		float fAttackerOrigin[3];
		GetClientAbsOrigin(attacker, fAttackerOrigin);
		fAttackerOrigin[2] += 15.0;
		
		TE_SetupBeamPoints(fAttackerOrigin, fClientOrigin, BeamSprite, 0, 0, 0, 0.75, 1.5, 2.0, 10, 4.0, {238, 44, 44, 255}, 20);
		TE_SendToAll();
		
		GiveHealth(attacker, leechhealth);
	}
}

void GiveHealth(int client, int add_health)
{
	int health = GetClientHealth(client);
	int max_health = GetEntProp(client, Prop_Data, "m_iMaxHealth");
	
	int total_health = health + add_health;
	
	if (total_health >= max_health)
	{
		total_health = max_health;
	}
	
	SetEntProp(client, Prop_Data, "m_iHealth", total_health);
}
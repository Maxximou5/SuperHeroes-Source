#pragma semicolon 1

#include <sourcemod>
#include <SH_Core>
#include <SH_Heroes>

//New Syntax
#pragma newdecls required

//Globals
int Hero;

public void OnPluginStart()
{
	HookEvent("player_death", OnPlayerDeath);
}

public void SH_OnReady()
{
	Hero = SH_RegisterHero(INVALID_FUNCTION, "Sylar", "When you kill someone, gain a percentage of their health.", 1, "", "");
}

public void OnPlayerDeath(Handle hEvent, char[] sName, bool bBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	if (SH_IsValidPlayer(client, true) && SH_IsValidPlayer(attacker, true) && client != attacker)
	{
		if (SH_IsClientHero(client, Hero) && GetEventBool(hEvent, "headshot"))
		{
			int addHealth = RoundFloat(FloatMul(float(GetEntProp(client, Prop_Data, "m_iMaxHealth")), 0.50));
			GiveHealth(attacker, addHealth);
		}
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
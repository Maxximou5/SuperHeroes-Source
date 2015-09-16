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
int BurnSprite;

public void OnPluginStart()
{
	
}

public void SH_OnReady()
{
	SH_RegisterHero(OnHeroCreated, "Torch", "The ability to shoot fire.", 1, "", "");
}

public void OnHeroCreated(int HeroID, const char[] sName, const char[] sDescription, int iRequiredLevel, const char[] sModel, const char[] sFlags)
{
	Hero = HeroID;
	
	Ability = SH_RegisterAbility("ShootFireballs", "Shoot Fireballs", "Allows heroes to shoot fireballs.", 5, OnAbilityUse);
	SH_AssignHeroAbility(Hero, Ability);
	
	SH_CreateAbilityCommand(Ability, "shootfireballs");
}

public void OnMapStart()
{
	BurnSprite = PrecacheModel("materials/sprites/fire1.vmt");
}

public void OnAbilityUse(int client, int HeroID, const char[] sName, const char[] sDisplayName, const char[] sDescription)
{
	float pos[3];
	GetClientAbsOrigin(client, pos);
	
	pos[2] += 30;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!SH_IsValidPlayer(i, true))
		{
			continue;
		}
		
		if (SH_GetTargetInViewCone(client, i, 5.0, 9999.0))
		{
			float targpos[3];
			GetClientAbsOrigin(i, targpos);
			
			TE_SetupBeamPoints(pos, targpos, BurnSprite, BurnSprite, 0, 8, 0.5, 10.0, 10.0, 10, 10.0, {255, 255, 255, 255}, 70); 
			TE_SendToAll();
			
			IgniteEntity(i, 3.0);
			targpos[2] += 50;
			
			TE_SetupGlowSprite(targpos, BurnSprite, 1.0, 1.9, 255);
			TE_SendToAll();
		}
		else
		{
			float targpos[3];
			SH_GetAimEndPoint(client, targpos);
			
			TE_SetupBeamPoints(pos, targpos, BurnSprite, BurnSprite, 0, 8, 0.5, 10.0, 10.0, 10, 10.0, {255, 255, 255, 255}, 70); 
			TE_SendToAll();
			
			targpos[2] += 50;
			
			TE_SetupGlowSprite(targpos, BurnSprite, 1.0, 1.9, 255);
			TE_SendToAll();
		}
	}
}
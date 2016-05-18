#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <SH_Core>
#include <SH_Heroes>
#include <SH_Abilities>

//New Syntax
#pragma newdecls required

//Globals
int Hero;
int Ability;

char sLaserBeam[] = "materials/sprites/laserbeam.vmt";
char sHalo[] = "materials/sprites/halo.vmt";

int BeamSprite;
int HaloSprite;

public void OnPluginStart()
{
	
}

public void SH_OnReady()
{
	SH_RegisterHero(OnHeroCreated, "Cyclops", "Allows you to shoot lasers.");
}

public void OnHeroCreated(int HeroID, const char[] sName, const char[] sDescription, int iRequiredLevel, const char[] sModel, const char[] sFlags)
{
	Hero = HeroID;
	
	Ability = SH_RegisterAbility("ShootLasers", "Shoot Lasers", "Allows heroes to shoot lasers.", 3, OnAbilityUse, INVALID_FUNCTION);
	SH_AssignHeroAbility(Hero, Ability);
	
	SH_CreateAbilityCommand(Ability, "shootlasers");
}

public void OnMapStart()
{
	BeamSprite = PrecacheModel(sLaserBeam);
	HaloSprite = PrecacheModel(sHalo);
}

public void OnAbilityUse(int client, int HeroID, const char[] sName, const char[] sDisplayName, const char[] sDescription)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!SH_IsValidPlayer(i))
		{
			continue;
		}
		
		if (SH_GetTargetInViewCone(client, i, 5.0, 9999.0))
		{
			float pos[3];
			GetClientEyePosition(client, pos);
			
			float otherpos[3];
			GetClientEyePosition(i, otherpos);
			
			pos[2] -= 30.0;
			otherpos[2] -= 30.0;
			pos[1] -= 10.0;
			otherpos[1] -= 10.0;
			pos[0] -= 10.0;
			otherpos[0] -= 10.0;
					
			SDKHooks_TakeDamage(i, client, client, 25.0, DMG_ENERGYBEAM);
			
			for (int x = 0; x < 30; x++)
			{
				TE_SetupBeamPoints(pos, otherpos, BeamSprite, HaloSprite, 0, 35, 0.5, 5.0, 5.0, 0, 0.0, {255, 0, 0, 255}, 700);
				TE_SendToAll();
			}
		}
	}
}
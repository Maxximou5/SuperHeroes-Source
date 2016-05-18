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

public void SH_OnReady()
{
	SH_RegisterHero(OnHeroCreated, "Torch", "The ability to shoot fire.");
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
	float fPos_Start[3];
	GetClientAbsOrigin(client, fPos_Start);
	
	float fPos_End[3];
	bool bNoClient = true;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (SH_IsValidPlayer(i, false, true) && SH_GetTargetInViewCone(client, i, 5.0, 9999.0))
		{
			GetClientAbsOrigin(i, fPos_End);
			FlameArea(fPos_Start, fPos_End);
			
			IgniteEntity(i, 3.0);
			bNoClient = false;
		}
	}
	
	if (bNoClient)
	{
		SH_GetAimEndPoint(client, fPos_End);
		FlameArea(fPos_Start, fPos_End);
	}
}

void FlameArea(float fPos_Start[3], float fPos_End[3])
{
	TE_SetupBeamPoints(fPos_Start, fPos_End, BurnSprite, BurnSprite, 0, 8, 0.5, 10.0, 10.0, 10, 10.0, {255, 255, 255, 255}, 70); 
	TE_SendToAll();
	
	fPos_End[2] += 50;
	
	TE_SetupGlowSprite(fPos_End, BurnSprite, 1.0, 1.9, 255);
	TE_SendToAll();	
}
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
char ThunderClapSound[] = "SH/ThunderClapCaster.wav";

int BeamSprite;
int HaloSprite;

public void OnPluginStart()
{
	
}

public void SH_OnReady()
{
	SH_RegisterHero(OnHeroCreated, "Hulk", "Stun your enemies and yourself.");
}

public void OnHeroCreated(int HeroID, const char[] sName, const char[] sDescription, int iRequiredLevel, const char[] sModel, const char[] sFlags)
{
	Hero = HeroID;
	
	Ability = SH_RegisterAbility("SmashEnemies", "Smash Enemies", "Allows heroes to smash your enemies.", 5, OnAbilityUse);
	SH_AssignHeroAbility(Hero, Ability);
	
	SH_CreateAbilityCommand(Ability, "smashenemies");
}

public void OnMapStart()
{
	BeamSprite = PrecacheModel(sLaserBeam);
	HaloSprite = PrecacheModel(sHalo);
	
	PrecacheSound(ThunderClapSound);
}

public void OnAbilityUse(int client, int HeroID, const char[] sName, const char[] sDisplayName, const char[] sDescription)
{
	float dist = 360.0;
	
	int ClaperTeam = GetClientTeam(client);
	
	float ClaperPos[3];
	GetClientAbsOrigin(client, ClaperPos);
	
	float VecPos[3];
	
	EmitSoundToAll(ThunderClapSound, client);
	
	TE_SetupBeamRingPoint(ClaperPos, 10.0, dist, BeamSprite, HaloSprite, 0, 15, 0.5, 50.0, 10.0, {255, 69, 0, 255}, 700, 0);
	TE_SendToAll();	
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (SH_IsValidPlayer(i) && GetClientTeam(i) != ClaperTeam)
		{
			GetClientAbsOrigin(i, VecPos);
			
			if (GetVectorDistance(ClaperPos, VecPos) <= dist)
			{
				SDKHooks_TakeDamage(i, client, client, 30.0, DMG_CLUB);
						
				SetEntPropFloat(i, Prop_Data, "m_flSpeed", 0.0);
				CreateTimer(3.0, EndStunned, i);
			}
		}
	}
}

public Action EndStunned(Handle timer, any client)
{
	if (SH_IsValidPlayer(client, true))
	{
		SetEntPropFloat(client, Prop_Data, "m_flSpeed", 1.0);
	}
}
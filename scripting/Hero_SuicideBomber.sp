#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <SH_Core>
#include <SH_Heroes>
#include <SH_Progression>

//New Syntax
#pragma newdecls required

#define	SHAKE_START					0
#define	SHAKE_STOP					1
#define	SHAKE_AMPLITUDE				2
#define	SHAKE_FREQUENCY				3
#define	SHAKE_START_RUMBLEONLY		4
#define	SHAKE_START_NORUMBLE		5

//Globals
int Hero;
bool bIsHero[MAXPLAYERS + 1];
float SuicideBomberRadius[5] = {0.0, 200.0, 233.0, 275.0, 333.0};
float SuicideBomberDamage[5] = {0.0, 166.0, 200.0, 233.0, 266.0};
float SuicideLocation[MAXPLAYERS + 1][3];
char explosionSound1[] = "war3source/particle_suck1.wav";
int ExplosionModel;
int BeamSprite;
int HaloSprite;

public void OnPluginStart()
{
	HookEvent("player_death", OnPlayerDeath);
}

public void SH_OnReady()
{
	Hero = SH_RegisterHero(INVALID_FUNCTION, "Suicide Bomber", "Explode when you die.", 1, "", "");
}

public void OnMapStart()
{
	ExplosionModel = PrecacheModel("materials/sprites/zerogxplode.vmt", false);
	PrecacheSound("weapons/explode5.wav", false);
	
	BeamSprite = PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	
	PrecacheSound(explosionSound1, false);
}

public void SH_OnAssignedHero(int client, int HeroID, const char[] sName, const char[] sDescription, int iRequiredLevel, const char[] sModel)
{
	if (HeroID == Hero)
	{
		bIsHero[client] = true;
	}
}

public void SH_OnUnassignedHero(int client, int HeroID)
{
	if (HeroID == Hero)
	{
		bIsHero[client] = false;
	}
}

public void OnPlayerDeath(Handle hEvent, char[] sName, bool bBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (bIsHero[client])
	{
		GetClientAbsOrigin(client, SuicideLocation[client]);
		SuicideBomber(client, SH_GetClientLevel(client));
	}
}

void SuicideBomber(int client, int level)
{
	int our_team = GetClientTeam(client); 
	float radius = SuicideBomberRadius[level];
	float client_location[3];
	
	for (int i = 0; i < 3; i++)
	{
		client_location[i] = SuicideLocation[client][i];
	}
	
	TE_SetupExplosion(client_location, ExplosionModel, 10.0, 1, 0, RoundToFloor(radius), 160);
	TE_SendToAll();
	
	client_location[2] -= 40.0;
	
	TE_SetupBeamRingPoint(client_location, 10.0, radius, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, {255, 255, 255, 33}, 120, 0);
	TE_SendToAll();
	
	int beamcolor[] = {0, 200, 255, 255};
	
	if (our_team == 2)
	{
		beamcolor[0] = 255;
		beamcolor[1] = 0;
		beamcolor[2] = 0;
	}
	
	TE_SetupBeamRingPoint(client_location, 20.0, radius + 10.0, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, beamcolor, 120, 0);
	TE_SendToAll();

	client_location[2] += 40.0;
	
	EmitSoundToAll(explosionSound1, client);
	EmitSoundToAll("weapons/explode5.wav", client);
	
	float location_check[3];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (SH_IsValidPlayer(i, true) && client != i && GetClientTeam(i) != our_team)
		{
			GetClientAbsOrigin(i, location_check);
			
			float distance = GetVectorDistance(client_location, location_check);
			
			if (distance > radius)
			{
				continue;
			}
			
			float factor = (radius - distance) / radius;
			float damage = SuicideBomberDamage[level] * factor;
			
			SDKHooks_TakeDamage(i, client, client, damage, DMG_BLAST);
			
			Client_Shake(i, SHAKE_START, 250.0 * factor, 30.0, 3.0 * factor);
		}
	}
}

//FROM SMLIB, NO CREDIT
bool Client_Shake(int client, int command = SHAKE_START, float amplitude = 50.0, float frequency = 150.0, float duration = 3.0)
{
	if (command == SHAKE_STOP)
	{
		amplitude = 0.0;
	}
	else if (amplitude <= 0.0)
	{
		return false;
	}
	
	Handle userMessage = StartMessageOne("Shake", client);
	
	if (userMessage == INVALID_HANDLE)
	{
		return false;
	}
	
	if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
	{
		PbSetInt(userMessage,   "command",         command);
		PbSetFloat(userMessage, "local_amplitude", amplitude);
		PbSetFloat(userMessage, "frequency",       frequency);
		PbSetFloat(userMessage, "duration",        duration);
	}
	else
	{
		BfWriteByte(userMessage,	command);
		BfWriteFloat(userMessage,	amplitude);
		BfWriteFloat(userMessage,	frequency);
		BfWriteFloat(userMessage,	duration);
	}

	EndMessage();

	return true;
}
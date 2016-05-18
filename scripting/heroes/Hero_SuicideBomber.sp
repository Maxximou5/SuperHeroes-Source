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

#define EXPLODE_BOOM "ambient/explosions/explode_8.wav"

//Globals
int Hero;
bool bIsHero[MAXPLAYERS + 1];
int g_ExplosionSprite;
int g_fire;
int g_HaloSprite;

public void OnPluginStart()
{
	HookEvent("player_death", OnPlayerDeath);
}

public void SH_OnReady()
{
	Hero = SH_RegisterHero(INVALID_FUNCTION, "Suicide Bomber", "Explode when you die.");
}

public void OnMapStart()
{
	PrecacheSound(EXPLODE_BOOM, true);
	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	g_fire = PrecacheModel("materials/sprites/fire2.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
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
		CreateExplosion(client);
	}
}

void CreateExplosion(int client)
{
	float fPos[3];
	GetClientAbsOrigin(client, fPos);
	
	int radius = 600;
	
	int color[4] =  { 188, 220, 255, 200 };
	EmitAmbientSound(EXPLODE_BOOM, fPos, SOUND_FROM_WORLD, SNDLEVEL_RAIDSIREN);
	TE_SetupExplosion(fPos, g_ExplosionSprite, 10.0, 1, 0, radius, 5000);
	TE_SendToAll();
	TE_SetupBeamRingPoint(fPos, 10.0, float(radius), g_fire, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, color, 10, 0);
	TE_SendToAll();
	
	for (int i = 1; i < MaxClients; ++i)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || client == i || GetClientTeam(client) == GetClientTeam(i))
		{
			continue;
		}
		
		float pos[3];
		GetClientEyePosition(i, pos);
		
		float distance = GetVectorDistance(fPos, pos);
		if (distance > radius)
		{
			continue;
		}
		
		float damage = 220.0;
		damage = damage * (radius - distance) / radius;
		SDKHooks_TakeDamage(i, client, client, damage, DMG_BLAST, -1, view_as<float>( { 0.0, 0.0, 0.0 } ), fPos);
		TE_SetupExplosion(pos, g_ExplosionSprite, 0.05, 1, 0, 1, 1);
		TE_SendToAll();
		
		Client_Shake(i, SHAKE_START, 50.0, 150.0, 3.0);
	}
	
	fPos[2] += 10;
	EmitAmbientSound(EXPLODE_BOOM, fPos, SOUND_FROM_WORLD, SNDLEVEL_RAIDSIREN);
	TE_SetupExplosion(fPos, g_ExplosionSprite, 10.0, 1, 0, radius, 5000);
	TE_SendToAll();
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
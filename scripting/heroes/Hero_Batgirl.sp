#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <SH_Heroes>
#include <SH_Abilities>

//New Syntax
#pragma newdecls required

//Globals
int Hero;
int Ability;

char sSoundEffect[] = "training/popup.wav";

bool isHooked[MAXPLAYERS + 1];
float hookOrigin[MAXPLAYERS + 1][3];
int traceDeny;
int beamPrecache;
bool canHook;

public void OnPluginStart()
{
	HookEvent("round_freeze_end", RoundStart);
	HookEvent("round_end", RoundEnd);
}

public void SH_OnReady()
{
	SH_RegisterHero(OnHeroCreated, "Batgirl", "Allows you to stream-line walls.");
}

public void OnHeroCreated(int HeroID, const char[] sName, const char[] sDescription, int iRequiredLevel, const char[] sModel, const char[] sFlags)
{
	Hero = HeroID;
	
	Ability = SH_RegisterAbility("Streamline", "Stream-Line", "Allows heroes to stream-line from walls.", 0, OnAbilityPress, OnAbilityRelease);
	SH_AssignHeroAbility(Hero, Ability);
	
	SH_CreateAbilityCommand(Ability, "streamline");
}

public void OnClientDisconnect(int client)
{
	isHooked[client] = false;
}

public void OnMapStart()
{
	PrecacheSound(sSoundEffect);
	beamPrecache = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public void RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	canHook = true;
}

public void RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	canHook = false;
}

public void OnAbilityPress(int client, int HeroID, const char[] sName, const char[] sDisplayName, const char[] sDescription)
{
	if (!isHooked[client] && canHook)
	{
		Bat_Attach(client);
	}
}

public void OnAbilityRelease(int client, int HeroID, const char[] sName, const char[] sDisplayName, const char[] sDescription)
{
	if (isHooked[client])
	{
		isHooked[client] = false;
	}
}

void Bat_Attach(int client)
{
	float eyepos[3];
	GetClientEyePosition(client, eyepos);
	
	float angle[3];
	GetClientEyeAngles(client, angle);
	
	float origin[3];
	GetClientAbsOrigin(client, origin);
	
	traceDeny = client;
	TR_TraceRayFilter(eyepos, angle, MASK_SOLID, RayType_Infinite, TraceFilter);
	
	if (TR_DidHit())
	{
		isHooked[client] = true;
		
		float end[3];
		TR_GetEndPosition(end);
		
		hookOrigin[client] = end;
		
		SetEntityGravity(client, 0.001);
		EmitSoundToAll(sSoundEffect, client);
		
		origin[2] += 20.0;

		DrawBeam(origin, hookOrigin[client]);
		
		origin[2] -= 20.0;
		
		float velocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
		
		velocity[2] += 70.0;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
		
		CreateTimer(0.1, HookTask, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action HookTask(Handle timer, any client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		isHooked[client] = false;
		return Plugin_Stop;
	}
	
	if (!isHooked[client] || !canHook)
	{
		isHooked[client] = false;
		SetEntityGravity(client, 1.0);
		return Plugin_Stop;
	}
	
	float origin[3];
	GetClientAbsOrigin(client, origin);

	origin[2] += 20.0;
	
	DrawBeam(origin, hookOrigin[client]);
	origin[2] -= 20.0;
	
	float velocity[3];
	SubtractVectors(hookOrigin[client], origin, velocity);
	NormalizeVector(velocity, velocity);
	
	float distance = GetVectorDistance(hookOrigin[client], origin);
	if (distance < 100.0)
	{
		float scale = (1200.0 * (100.0 - distance * 4.0) / 100.0);	//600.0 = speed
		ScaleVector(velocity, (scale > 10.0) ? scale : 10.0);
	}
	else
	{
		ScaleVector(velocity, 300.0);
	}
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
	
	return Plugin_Continue;
}

void DrawBeam(float tplayerorigin[3], float thookorigin[3])
{
	int r = 255; int g = 255; int b = 255; int a = 255;
	
	int color[4];
	color[0] = r; color[1] = g; color[2] = b; color[3] = a;
	
	TE_SetupBeamPoints(tplayerorigin, thookorigin, beamPrecache,0, 1, 10, 0.2, 10.0 ,1.0, 0, 0.0, color, 50);
	TE_SendToAll(0.0);
}

public bool TraceFilter(int entity, int mask)
{
	return entity != traceDeny;
}
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
bool canHook;
float g_Location[MAXPLAYERS + 1][3];
int g_Targetindex[MAXPLAYERS + 1];
float g_Distance[MAXPLAYERS + 1];
bool g_Climbing[MAXPLAYERS + 1][2];

int GetVelocityOffset_x;
int GetVelocityOffset_y;
int GetVelocityOffset_z;

int precache_laser;

public void OnPluginStart()
{
	HookEvent("round_freeze_end", RoundStart);
	HookEvent("round_end", RoundEnd);

	GetVelocityOffset_x = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
	GetVelocityOffset_y = FindSendPropOffs("CBasePlayer", "m_vecVelocity[1]");
	GetVelocityOffset_z = FindSendPropOffs("CBasePlayer", "m_vecVelocity[2]");
}

public void SH_OnReady()
{
	Hero = SH_RegisterHero("Spiderman", "Allows you to swing from walls.", 1, "", "");
	
	Ability = SH_RegisterAbility("RopeSwing", "Rope Swing", "Allows heroes to swing from walls.", 0, OnAbilityPress, OnAbilityRelease);
	SH_AssignHeroAbility(Hero, Ability);
	
	SH_CreateAbilityCommand(Ability, "ropeswing");
}

public void OnMapStart()
{
	precache_laser = PrecacheModel("materials/sprites/laserbeam.vmt");
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
	if (canHook)
	{
		Action_Rope(client);
	}
}

public void OnAbilityRelease(int client, int HeroID, const char[] sName, const char[] sDisplayName, const char[] sDescription)
{
	Action_Detach(client);
}

void Action_Rope(int client)
{
	if (client > 0 && client <= MaxClients && IsPlayerAlive(client))
	{
		float clientloc[3]; float clientang[3];
		GetClientEyePosition(client, clientloc);
		GetClientEyeAngles(client, clientang);
		
		TR_TraceRayFilter(clientloc, clientang, MASK_ALL, RayType_Infinite, TraceRayTryToHit);
		TR_GetEndPosition(g_Location[client]);
		g_Targetindex[client] = TR_GetEntityIndex();
		
		g_Distance[client] = GetVectorDistance(clientloc, g_Location[client]);
		
		EmitSoundFromOrigin("hgr/hookhit.mp3", g_Location[client]);
		CreateTimer(0.1, Roping, client, TIMER_REPEAT);
	}
}

public bool TraceRayTryToHit(int entity, int mask)
{
	if (entity > 0 && entity <= MaxClients)
	{
		return false;
	}
	
	return true;
}

void EmitSoundFromOrigin(const char[] sound, const float orig[3])
{
	for (int i = 0; i < 3; i++)
	{
		EmitSoundToAll(sound, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, orig, NULL_VECTOR, true, 0.0);
	}
}

public Action Roping(Handle timer, any client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		float clientloc[3]; float velocity[3]; float direction[3]; float ascension[3]; float climb = 3.0;
		GetClientEyePosition(client, clientloc);
		SubtractVectors(g_Location[client], clientloc, direction);
		
		if (g_Climbing[client][0])
		{
			climb *= 5.0;
			g_Distance[client] -= climb;
			
			if (g_Distance[client] <= 10.0)
			{
					g_Distance[client] = 10.0;
			}
		}
		else if(g_Climbing[client][1])
		{
			climb *= -5.0;
			g_Distance[client] -= climb;
		}
		else
		{
			climb = 0.0;
		}
		
		if (GetVectorLength(direction) - 5 >= g_Distance[client])
		{
			GetVelocity(client, velocity);
			NormalizeVector(direction, direction);
			
			ascension[0] = direction[0] * climb;
			ascension[1] = direction[1] * climb;
			ascension[2] = direction[2] * climb;
			
			ScaleVector(direction, 5.0 * 60.0);
			
			velocity[0] += direction[0] + ascension[0];
			velocity[1] += direction[1] + ascension[1];
			
			if (ascension[2] > 0.0)
			{
				velocity[2] += direction[2] + ascension[2];
			}
			
			if (g_Location[client][2] - clientloc[2] >= g_Distance[client] && velocity[2] < 0.0)
			{
				velocity[2] *= -1;
			}
			
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
		}
		
		int color[4];
		clientloc[2] -= 10;
		GetBeamColor(client, color);
		BeamEffect(clientloc, g_Location[client], 0.2, 5.0, 5.0, color, 5.0, 0);
	}
	else
	{
		Action_Detach(client);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

void Action_Detach(int client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		g_Targetindex[client] = -1;
	}
}

public void GetVelocity(int client, float output[3])
{
	output[0] = GetEntDataFloat(client, GetVelocityOffset_x);
	output[1] = GetEntDataFloat(client, GetVelocityOffset_y);
	output[2] = GetEntDataFloat(client, GetVelocityOffset_z);
}

public void GetBeamColor(int client, int color[4])
{
	color[0]=255;
	color[1]=255;
	color[2]=255;
	color[3]=255;
}

void BeamEffect(float startvec[3], float endvec[3], float life, float width, float endwidth, const int color[4], float amplitude, int speed)
{
	TE_SetupBeamPoints(startvec, endvec, precache_laser, 0, 0, 66, life, width, endwidth, 0, amplitude, color, speed);
	TE_SendToAll();
}
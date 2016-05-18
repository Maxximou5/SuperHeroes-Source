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
	SH_RegisterHero(OnHeroCreated, "Spiderman", "Allows you to swing from walls.");
}

public void OnHeroCreated(int HeroID, const char[] sName, const char[] sDescription, int iRequiredLevel, const char[] sModel, const char[] sFlags)
{
	Hero = HeroID;
	
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
		float fPos[3];
		GetClientEyePosition(client, fPos);
		
		float fAng[3];
		GetClientEyeAngles(client, fAng);
		
		Handle hTrace = TR_TraceRayFilterEx(fPos, fAng, MASK_ALL, RayType_Infinite, TraceRayTryToHit);
		TR_GetEndPosition(g_Location[client], hTrace);
		
		g_Targetindex[client] = TR_GetEntityIndex(hTrace);
		g_Distance[client] = GetVectorDistance(fPos, g_Location[client]);
		
		for (int i = 0; i < 3; i++)
		{
			EmitSoundToAll("hgr/hookhit.mp3", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, g_Location[client], NULL_VECTOR, true, 0.0);
		}
		
		CreateTimer(0.1, Roping, GetClientUserId(client), TIMER_REPEAT);
		
		CloseHandle(hTrace);
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

public Action Roping(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if (g_Targetindex[client] == -1)
		{
			Action_Detach(client);
			return Plugin_Stop;
		}
		
		float climb = 3.0;
		
		float fPos[3];
		GetClientEyePosition(client, fPos);
		
		float direction[3];
		SubtractVectors(g_Location[client], fPos, direction);
		
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
			float fVel[3];
			GetVelocity(client, fVel);
			NormalizeVector(direction, direction);
			
			float ascension[3];
			ascension[0] = direction[0] * climb;
			ascension[1] = direction[1] * climb;
			ascension[2] = direction[2] * climb;
			
			ScaleVector(direction, 5.0 * 60.0);
			
			fVel[0] += direction[0] + ascension[0];
			fVel[1] += direction[1] + ascension[1];
			
			if (ascension[2] > 0.0)
			{
				fVel[2] += direction[2] + ascension[2];
			}
			
			if (g_Location[client][2] - fPos[2] >= g_Distance[client] && fVel[2] < 0.0)
			{
				fVel[2] *= -1;
			}
			
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVel);
		}
		
		fPos[2] -= 10;
		
		int color[4] = {255, 255, 255, 255};
		TE_SetupBeamPoints(fPos, g_Location[client], precache_laser, 0, 0, 66, 0.2, 5.0, 5.0, 0, 5.0, color, 0);
		TE_SendToAll();
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

public void OnGameFrame()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			int cl_buttons = GetClientButtons(i);
			
			if (cl_buttons & IN_JUMP)
			{
				if (!g_Climbing[i][0])
				{
					g_Climbing[i][0] = true;
					g_Climbing[i][1] = false;
				}
			}
			else
			{
				if (g_Climbing[i][0])
				{
					g_Climbing[i][0] = false;
				}
				
				if (cl_buttons & IN_DUCK)
				{
					if (!g_Climbing[i][1])
					{
						g_Climbing[i][1] = true;
					}
				}
				else if (g_Climbing[i][1])
				{
					g_Climbing[i][1] = false;
				}
			}
		}
	}
}
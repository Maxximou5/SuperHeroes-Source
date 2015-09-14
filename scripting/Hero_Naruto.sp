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
float oldpos[66][3];
int absincarray[] = {0,4, -4, 8, -8, 12, -12, 18, -18, 22, -22, 25, -25};

public void OnPluginStart()
{
	
}

public void SH_OnReady()
{
	Hero = SH_RegisterHero("Naruto", "Access to Rasengan.", 1, "", "");
	
	Ability = SH_RegisterAbility("Rasengan", "Rasengan", "Make copies of yourself.", 5, OnAbilityUse);
	SH_AssignHeroAbility(Hero, Ability);
	
	SH_CreateAbilityCommand(Ability, "rasengan");
}

public void OnAbilityUse(int client, int HeroID, const char[] sName, const char[] sDisplayName, const char[] sDescription)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!SH_IsValidPlayer(i, true))
		{
			continue;
		}
		
		if (SH_GetTargetInViewCone(client, i, 5.0, 9999.0))
		{
			GetClientAbsOrigin(client, oldpos[client]);
			
			TeleportToPlayer(client, i);
		}
	}
}

bool TeleportToPlayer(int client, int target)
{
	float clientpos[3];
	float targetpos[3];
	
	GetClientAbsOrigin(client, clientpos);
	GetClientAbsOrigin(target, targetpos);
	
	float distanceVector[3];
	SubtractVectors(targetpos, clientpos, distanceVector);
	
	float distance = GetVectorDistance(targetpos, clientpos);
	float newdistance = distance - 30.0;
	
	ScaleVector(distanceVector, newdistance / distance);
	
	float newpos[3];
	AddVectors(clientpos, distanceVector, newpos);
	
	float returnpos[3];
	getEmptyLocationHull(client, newpos, returnpos);
	
	if (GetVectorLength(returnpos) < 0.1)
	{
		return false;
	}
	else
	{
		TeleportEntity(client, returnpos, NULL_VECTOR, NULL_VECTOR);
	}
	
	return true;
}

public bool getEmptyLocationHull(int client, float originalpos[3], float returnpos[3])
{
	float mins[3];
	float maxs[3];
	
	GetClientMins(client, mins);
	GetClientMaxs(client, maxs);
	
	int absincarraysize = sizeof(absincarray);
	
	int limit = 5000;
	for (int x = 0; x < absincarraysize; x++)
	{
		if (limit > 0)
		{
			for (int y = 0; y <= x; y++)
			{
				if (limit > 0)
				{
					for (int z = 0; z <= y; z++)
					{
						float pos[3] = {0.0, 0.0, 0.0};
						AddVectors(pos, originalpos, pos);
						
						pos[0] += float(absincarray[x]);
						pos[1] += float(absincarray[y]);
						pos[2] += float(absincarray[z]);
						
						TR_TraceHullFilter(pos, pos, mins, maxs, MASK_SOLID, CanHitThis, client);
						
						if (!TR_DidHit(_))
						{
							AddVectors(view_as<float>{0.0, 0.0, 0.0}, pos, returnpos);
							limit =- 1;
							break;
						}
					
						if (limit --< 0)
						{
							break;
						}
					}
					
					if (limit --< 0)
					{
						break;
					}
				}
			}
			
			if (limit --< 0)
			{
				break;
			}
		}
	}
}

public bool CanHitThis(int entityhit, int mask, any data)
{
	if (entityhit == data)
	{
		return false;
	}
	
	if (SH_IsValidPlayer(entityhit) && SH_IsValidPlayer(data) && GetClientTeam(entityhit) == GetClientTeam(data))
	{
		return false;
	}
	
	return true;
}
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <SH_Heroes>

//New Syntax
#pragma newdecls required

//Globals
int Hero;
bool bInvisibleMan[MAXPLAYERS + 1];
bool bStoodStill[MAXPLAYERS + 1];

public void OnPluginStart()
{
	CreateTimer(1.0, CheckVisibility, _, TIMER_REPEAT);
}

public void SH_OnReady()
{
	Hero = SH_RegisterHero(INVALID_FUNCTION, "Invisible Man", "Stand still for 5 seconds to become invisible until you become active again.", 1, "", "");
}

public void SH_OnAssignedHero(int client, int HeroID, const char[] sName, const char[] sDescription, int iRequiredLevel, const char[] sModel)
{
	if (HeroID == Hero)
	{
		bInvisibleMan[client] = true;
	}
}

public void SH_OnUnassignedHero(int client, int HeroID)
{
	if (HeroID == Hero)
	{
		bInvisibleMan[client] = false;
	}
}

public void SH_OnHeroSpawn(int client, int HeroID)
{
	if (Hero != HeroID)
	{
		bInvisibleMan[client] = false;
		return;
	}
	
	bInvisibleMan[client] = true;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (bInvisibleMan[client])
	{
		bStoodStill[client] = false;
		Invisible(client, 1.0);
		CreateTimer(5.0, NotStoodStill, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action NotStoodStill(Handle hTimer, any data)
{
	int client = GetClientOfUserId(data);
	
	if (IsClientInGame(client))
	{
		bStoodStill[client] = true;
	}
}

public Action CheckVisibility(Handle hTimer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (bInvisibleMan[i] && bStoodStill[i])
		{
			Invisible(i, 0.2);
		}
	}
}

void Invisible(int client, float percent)
{
	int iColor[4] = {255, 255, 255, 0};
	
	if (percent >= 1 || percent < 0)
	{
		iColor[3] = 255;
	}
	else
	{
		iColor[3] = RoundFloat(FloatMul(255.0, percent));
	}
	
	SetEntityColor(client, iColor);
	
	for (int i = 0; i < 3; i++)
	{
		int iWeapon = GetPlayerWeaponSlot(client, i);
		
		if (iWeapon > MaxClients && IsValidEntity(iWeapon))
		{
			SetEntityColor(iWeapon, iColor);
		}
	}
    
	char strClass[32];
	for (int i = MaxClients + 1; i < GetMaxEntities(); i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, strClass, sizeof(strClass));
			
			if((strncmp(strClass, "tf_wearable", 11) == 0 || strncmp(strClass, "tf_powerup", 10) == 0) && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client)
			{
				SetEntityColor(i, iColor);
			}
		}
	}
	
	int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon");
	
	if(iWeapon > MaxClients && IsValidEntity(iWeapon))
	{
		SetEntityColor(iWeapon, iColor);
	}
}

void SetEntityColor(int iEntity, int iColor[4])
{
    SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
    SetEntityRenderColor(iEntity, iColor[0], iColor[1], iColor[2], iColor[3]);
}  
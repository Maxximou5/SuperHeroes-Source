#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <SH_Heroes>

//New Syntax
#pragma newdecls required

//Globals
int Hero;
bool bInvisibleMan[MAXPLAYERS + 1];
int iButtons[MAXPLAYERS + 1];

public void OnPluginStart()
{
	
}

public void SH_OnReady()
{
	Hero = SH_RegisterHero(INVALID_FUNCTION, "Invisible Man", "Stand still for 5 seconds to become invisible until you become active again.");
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
		if (iButtons[client] != buttons)
		{
			Invisible(client, 255);
		}
		else
		{
			Invisible(client, 150);
		}
		
		iButtons[client] = buttons;
	}
}

void Invisible(int client, int alpha)
{
	int iColor[4] = {255, 255, 255, 255};
	iColor[3] = alpha;
	
	SetEntityColor(client, iColor);
	
	for (int i = 0; i < 3; i++)
	{
		int iWeapon = GetPlayerWeaponSlot(client, i);
		
		if (iWeapon > MaxClients && IsValidEntity(iWeapon))
		{
			SetEntityColor(iWeapon, iColor);
		}
	}
}

void SetEntityColor(int iEntity, int iColor[4])
{
    SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
    SetEntityRenderColor(iEntity, iColor[0], iColor[1], iColor[2], iColor[3]);
}  
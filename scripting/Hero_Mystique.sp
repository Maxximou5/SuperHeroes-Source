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
bool change[MAXPLAYERS + 1];

public void OnPluginStart()
{
	
}

public void SH_OnReady()
{
	Hero = SH_RegisterHero("Mystique", "Allows you to shapeshift into different forms.", 1, "", "");
	
	Ability = SH_RegisterAbility("Shapeshifting", "Shapeshifting", "Allows you to shapeshift into different forms.", 15, OnAbilityUse);
	SH_AssignHeroAbility(Hero, Ability);
	
	SH_CreateAbilityCommand(Ability, "Shapeshifting");
}

public void OnAbilityUse(int client, int HeroID, const char[] sName, const char[] sDisplayName, const char[] sDescription)
{
	switch (GetClientTeam(client))
	{
		case 2:
		{
			if (change[client])
			{
				SetEntityModel(client, "models/player/ct_urban.mdl");
				change[client] = false;
				PrintHintText(client, "Disguise : Off");
			}
			else
			{
				SetEntityModel(client, "models/player/t_leet.mdl");
				change[client] = true;
				PrintHintText(client, "Disguise : On");
			}
		}
		case 3:
		{
			if (change[client])
			{
				SetEntityModel(client, "models/player/t_leet.mdl");
				change[client] = false;
				PrintHintText(client, "Disguise : Off");
			}
			else
			{
				SetEntityModel(client, "models/player/ct_urban.mdl");
				change[client] = true;
				PrintHintText(client, "Disguise : On");
			}
		}
	}
}
#if defined _SH_Heroes_included
#endinput
#endif
#define _SH_Heroes_included

//Cross-Module Defines
#define MAX_HEROES 512
#define MAX_HERO_NAME_LENGTH 64
#define MAX_HERO_DESCRIPTION_LENGTH 128

//Callback Typesets
typeset SH_OnHeroRegistered
{
	function void(int HeroID, const char[] sName, const char[] sDescription, int iRequiredLevel, const char[] sModel, const char[] sFlags);
}

//////////////////
//Natives

/**
 * Register new heroes with this function then handle the new hero with other functions.
 *
 * @param callback			Function called when the hero is created.
 * @param sName				Name of the Hero.
 * @param sDescription		Description for the Hero.
 * @param iRequiredLevel	Required level for this hero to be played.
 * @param sModel			Model to equip to the client as this hero. (Relative to the models folder)
 * @param sFlags			Flags to give a hero if flag requirements are enabled. (Empty means no flags)
 *
 * @return	index/id of the hero.
 **/
native int SH_RegisterHero(SH_OnHeroRegistered callback, const char[] sName, const char[] sDescription, int iRequiredLevel, const char[] sModel, const char[] sFlags);

/**
 * Retrieves the index/ID of the hero the client is playing. Since the array is filled with values, you will need the amount in order to pull the right amount from the array to use.
 *
 * @param client			Client index.
 * @param heroes			Array of hero indexes.
 * @param amount			Amount of heroes.
 *
 * @return	True if successful, false if client isn't valid and/or client has no heroes equipped.
 **/
native bool SH_GetClientHeroes(int client, int[] heroes, int &amount);

/**
 * Add a hero to the client.
 *
 * @param client			Client index.
 * @param slot				Slot ID to manage, -1 for any available. (returns false if -1 and none available)
 * @param HeroName			Name of the hero.
 * @param bCheckLevel		Checks a clients level and if they can be the hero or not.
 * @param bVerbose			Tell the client that their hero has been added.
 *
 * @return True if successful, false otherwise.
 **/
native bool SH_AddClientHero(int client, int slot, const char[] sHeroName, bool bCheckLevel = true, bool bVerbose = true);

/**
 * Remove a hero from a client.
 *
 * @param client			Client index.
 * @param slot				Slot ID to manage, -1 to search for sHeroName.
 * @param HeroName			Name of the hero. (Ignored if slot is not -1)
 * @param bVerbose			Tell the client that their hero has been stripped.
 *
 * @return True if successful, false otherwise.
 **/
native bool SH_RemoveClientHero(int client, int slot, const char[] sHeroName, bool bVerbose = true);

/**
 * Checks if a client is a specified hero. This searches through all the heroes.
 *
 * @param client			Client index.
 * @param HeroID			ID of the hero.
 *
 * @return True if yes, false otherwise.
 **/
native bool SH_IsClientHero(int client, int HeroID);

/**
 * Converts a Heroes Name to a Heroes ID.
 *
 * @param sHeroName			Name of the hero to retrieve the ID from.
 *
 * @return HeroID, -1 otherwise or not found.
 **/
native int SH_GetHeroID(const char[] sHeroName);

/**
 * Converts a Heroes ID to a Heroes Name.
 *
 * @param HeroID			ID of the Hero.
 * @param sName				Buffer to store string in.
 *
 * @return True if successful, false otherwise.
 **/
native bool SH_GetHeroName(HeroID, char[] sName, int size);

/**
 * Converts a Heroes ID to a Heroes Description.
 *
 * @param HeroID			ID of the Hero.
 * @param sDescription		Buffer to store string in.
 *
 * @return True if successful, false otherwise.
 **/
native bool SH_GetHeroDescription(int HeroID, char[] sDescription, int size);

/**
 * Converts a Heroes ID to a Heroes Required level.
 *
 * @param HeroID			ID of the Hero.
 *
 * @return Required Level, 0 otherwise. (0 = any client)
 **/
native int SH_GetHeroRequiredLevel(int HeroID);

/**
 * Converts a Heroes ID to a Heroes Model.
 *
 * @param HeroID			ID of the Hero.
 * @param sModel			Buffer to store string in.
 *
 * @return True if successful, false otherwise.
 **/
native bool SH_GetHeroModel(int HeroID, char[] sModel, int size);

/**
 * Checks if a specific HeroID is valid or in use.
 *
 * @param HeroID			ID of the Hero.
 *
 * @return	True if valid, false otherwise.
 **/
native bool SH_IsHeroValid(int HeroID);

//////////////////
//Stocks

//From SMLIB, used to fill client Hero arrays.
stock Array_Fill(any[] array, int size, any value, int start = 0)
{
	if (start < 0)
	{
		start = 0;
	}
	
	for (int i = start; i < size; i++)
	{
		array[i] = value;
	}
}

//////////////////
//Forwards

/**
 * Called when a player is assigned a specific hero.
 *
 * @param client			Client index.
 * @param HeroID			ID of the Hero.
 * @param sName				Name of the Hero.
 * @param sDescription		Description of the Hero.
 * @param iRequiredLevel	Required Level to play the Hero.
 * @param sModel			Model of the Hero.
 *
 * @noreturn
 **/
forward void SH_OnAssignedHero(int client, int HeroID, const char[] sName, const char[] sDescription, int iRequiredLevel, const char[] sModel);

/**
 * Called when a player is assigned a specific hero.
 *
 * @param client			Client index.
 * @param HeroID			ID of the Hero.
 *
 * @noreturn
 **/
forward void SH_OnUnassignedHero(int client, int HeroID);

#if !defined REQUIRE_PLUGIN
public __pl_SH_Heroes_SetNTVOptional()
{
	MarkNativeAsOptional("SH_RegisterHero");
	MarkNativeAsOptional("SH_GetClientHeroes");
	MarkNativeAsOptional("SH_AddClientHero");
	MarkNativeAsOptional("SH_RemoveClientHero");
	MarkNativeAsOptional("SH_IsClientHero");
	
	MarkNativeAsOptional("SH_GetHeroID");
	MarkNativeAsOptional("SH_GetHeroName");
	MarkNativeAsOptional("SH_GetHeroDescription");
	MarkNativeAsOptional("SH_GetHeroRequiredLevel");
	MarkNativeAsOptional("SH_GetHeroModel");
	
	MarkNativeAsOptional("SH_IsHeroValid");
}
#endif

public SharedPlugin __pl_SH_Heroes = 
{
	name = "SH_Heroes", 
	file = "SH_Heroes.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

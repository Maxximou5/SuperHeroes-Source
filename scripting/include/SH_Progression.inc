#if defined _SH_Progression_included
#endinput
#endif
#define _SH_Progression_included

//Cross-Module Defines

//Callback Typesets

//////////////////
//Natives

/**
 * Retrieves the clients current level.
 *
 * @param client			Client index.
 *
 * @return	client level, -1 otherwise.
 **/
native int SH_GetClientLevel(int client);

/**
 * Retrieves the clients current experience.
 *
 * @param client			Client index.
 *
 * @return	client experience, -1 otherwise.
 **/
native int SH_GetClientExperience(int client);

/**
 * Gives a player experience, handles all the data if they level up or not, etc.
 *
 * @param client			Client index.
 * @param XP				Experience to give clients.
 *
 * @return True if successful, false otherwise.
 **/
native bool SH_AddExperience(int client, int XP);

/**
 * Retrieve the starting level defined by the config entry for players to start at.
 *
 * @return Starting Level.
 **/
native int SH_GetStartingLevel();

/**
 * Retrieves the maximum level defined by the config that players can reach.
 *
 * @return Max Level.
 **/
native int SH_GetMaxLevel();

/**
 * Saves all client heroes to database.
 *
 * @param client			Client index.
 *
 * @return True if successful, false otherwise.
 **/
native bool SH_SaveClientHeroes(int client);


#if !defined REQUIRE_PLUGIN
public __pl_SH_Progression_SetNTVOptional()
{
	MarkNativeAsOptional("SH_GetClientLevel");
	MarkNativeAsOptional("SH_GetClientExperience");
	MarkNativeAsOptional("SH_AddExperience");
	MarkNativeAsOptional("SH_GetStartingLevel");
	MarkNativeAsOptional("SH_GetMaxLevel");
	MarkNativeAsOptional("SH_SaveClientHeroes");
}
#endif

public SharedPlugin __pl_SH_Progression = 
{
	name = "SH_Progression", 
	file = "SH_Progression.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if defined _SH_Abilities_included
#endinput
#endif
#define _SH_Abilities_included

//Cross-Module Defines
#define MAX_ABILITIES 512
#define MAX_ABILITY_NAME_LENGTH 64
#define MAX_ABILITY_DISPLAY_NAME_LENGTH 64
#define MAX_ABILITY_DESCRIPTION_LENGTH 128
#define MAX_ABILITY_COMMAND_LENGTH 32

//Callback Typesets
typeset SH_UseAbilityCallback
{
	function void(int client, int HeroID, const char[] sName, const char[] sDisplayName, const char[] sDescription);
}

//////////////////
//Natives

/**
 * Registers a new ability for Heroes to use. (YOU MUST ASSIGN AN ABILITY TO A COMMAND USING THE NATIVE 'SH_CreateAbilityCommand' OTHERWISE PEOPLE CAN'T USE IT)
 *
 * @param sName				Name of the ability. (Recommended to only use lowercase letters and numbers but not required)
 * @param sDisplayName		Display name of the ability.
 * @param sDescription		Description of the ability.
 * @param iCooldown			Amount in seconds an ability should be in cooldown. (0 = No Cooldown)
 * @param callback_press	Function to call when the ability is pressed.
 * @param callback_release	Function to call when the ability is released.
 *
 * @return	Index/Id of the ability.
 **/
native int SH_RegisterAbility(const char[] sName, const char[] sDisplayName, const char[] sDescription, int iCooldown = 0, SH_UseAbilityCallback callback_press, SH_UseAbilityCallback callback_release = INVALID_FUNCTION);

/**
 * Assigns a specific ability to a hero.
 *
 * @param HeroID			ID of the hero to assign the ability to.
 * @param AbilityID			ID of the ability to assign to the hero.
 *
 * @return	true on success, false otherwise including the ability not existing.
 **/
native bool SH_AssignHeroAbility(int HeroID, int AbilityID);

/**
 * Check for a name of an ability to see if it's valid or not.
 *
 * @param sName				Name of the ability. (NOT DISPLAY NAME)
 *
 * @return	true on valid, false otherwise.
 **/
native bool SH_IsValidAbility(const char[] sName);

/**
 * Assign an abilityID to a specific command.
 *
 * @param AbilityID			ID of the ability.
 * @param sName				Name of the command.
 * @param size				Size of the command string.
 *
 * @return	True if successful, false otherwise.
 **/
native bool SH_CreateAbilityCommand(int AbilityID, const char[] sName);

/**
 * Stock function if heroes want to use abilities that require cone targeting.
 *
 * @param client			Client index.
 * @param target			Target index.
 * @param angle				Angle of the cone.
 * @param distance			Distance of the cone.
 * @param heightcheck		Check Height.
 * @param negativeangle		Negative Angles.
 *
 * @return	Index/Id of the ability, -1 otherwise.
 **/
native int SH_GetTargetInViewCone(int client, int target, float angle = 90.0, float distance = 0.0, bool heightcheck = true, bool negativeangle = false);

/**
 * Stock function to retrieve the clients crosshair location.
 *
 * @param client			Client index.
 * @param fEndPosition		Location array to fill.
 *
 * @noreturn
 **/
native void SH_GetAimEndPoint(client, float fEndPosition[3]);

/**
 * Check for a name of an ability to see if it's valid or not.
 *
 * @param sName				Name of the ability. (NOT DISPLAY NAME)
 *
 * @return	Index/Id of the ability, -1 otherwise.
 **/
native int SH_GetAbilityID(const char[] sName);

/**
 * Converts an Ability ID to an Ability Name.
 *
 * @param HeroID			ID of the Hero.
 * @param sName				Buffer to store string in.
 *
 * @return True if successful, false otherwise.
 **/
native bool SH_GetAbilityName(int AbilityID, char[] sName, int size);

/**
 * Converts an Ability ID to an Ability Display Name.
 *
 * @param HeroID			ID of the Hero.
 * @param sName				Buffer to store string in.
 *
 * @return True if successful, false otherwise.
 **/
native bool SH_GetAbilityDisplayName(int AbilityID, char[] sName, int size);

/**
 * Converts an Ability ID to an Ability Description.
 *
 * @param HeroID			ID of the Hero.
 * @param sDescription		Buffer to store string in.
 *
 * @return True if successful, false otherwise.
 **/
native bool SH_GetAbilityDescription(int AbilityID, char[] sDescription, int size);

/**
 * Converts an Ability ID to the Abilities Cooldown.
 *
 * @param HeroID			ID of the Hero.
 *
 * @return Cooldown amount, 0 if no cooldown.
 **/
native int SH_GetAbilityCooldown(int AbilityID);

native bool SH_ListAbilities(int HeroID, int Method = 1, char[] sBuffer = "", int size, Handle hMenu = INVALID_HANDLE);

//////////////////
//Forwards

/**
 * Called when a player takes damage. This is a forward you can use so you don't have to hook into SDKHooks OnTakeDamage event yourself.
 *
 * @param client			Client index.
 * @param attacker			Attacker index.
 * @param inflictor			Inflictor index.
 * @param damage			Amount of damage given.
 * @param damagetype		Damage type.
 * @param weapon			Weapon index.
 * @param damageForce		Damage Force Array.
 * @param damagePosition	Damage Position Array.
 *
 * @return	(event - PLUGIN_HANDLED, PLUGIN_CONTINUE, etc).
 **/
forward Action SH_OnTakeDamage(int client, int attacker, int inflictor, float damage, int damagetype, int weapon, float damageForce[3], float damagePosition[3]);

/**
 * Called after a player takes damage. This is a forward you can use so you don't have to hook into SDKHooks OnTakeDamage event yourself.
 *
 * @param client			Client index.
 * @param attacker			Attacker index.
 * @param inflictor			Inflictor index.
 * @param damage			Amount of damage given.
 * @param damagetype		Damage type.
 * @param weapon			Weapon index.
 * @param damageForce		Damage Force Array.
 * @param damagePosition	Damage Position Array.
 *
 * @noreturn
 **/
forward void SH_OnTakeDamage_Post(int client, int attacker, int inflictor, float damage, int damagetype, int weapon, float damageForce[3], float damagePosition[3]);

#if !defined REQUIRE_PLUGIN
public __pl_SH_Abilities_SetNTVOptional()
{
	MarkNativeAsOptional("SH_RegisterAbility");
	MarkNativeAsOptional("SH_AssignHeroAbility");
	MarkNativeAsOptional("SH_IsValidAbility");
	MarkNativeAsOptional("SH_CreateAbilityCommand");
	
	MarkNativeAsOptional("SH_GetTargetInViewCone");
	MarkNativeAsOptional("SH_GetAimEndPoint");
	
	MarkNativeAsOptional("SH_GetAbilityID");
	MarkNativeAsOptional("SH_GetAbilityName");
	MarkNativeAsOptional("SH_GetAbilityDisplayName");
	MarkNativeAsOptional("SH_GetAbilityDescription");
	MarkNativeAsOptional("SH_GetAbilityCooldown");
	
	MarkNativeAsOptional("SH_ListAbilities");
}
#endif

public SharedPlugin __pl_SH_Abilities = 
{
	name = "SH_Abilities", 
	file = "SH_Abilities.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

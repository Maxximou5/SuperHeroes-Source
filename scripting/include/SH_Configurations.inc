#if defined _SH_Configurations_included
#endinput
#endif
#define _SH_Configurations_included

//Cross-Module Defines

//Callback Typesets

//////////////////
//Natives

/**
 * Registers a new section for configurations based on settings in the plugin.
 *
 * @param sName				Name of the configuration entry.
 *
 * @noreturn
 **/
native void SH_CreateConfig(const char[] sName);

#if !defined REQUIRE_PLUGIN
public __pl_SH_Configurations_SetNTVOptional()
{
	MarkNativeAsOptional("SH_CreateConfig");
}
#endif

public SharedPlugin __pl_SH_Configurations = 
{
	name = "SH_Configurations", 
	file = "SH_Configurations.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

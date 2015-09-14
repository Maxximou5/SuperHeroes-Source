#if defined _SH_Hud_included
#endinput
#endif
#define _SH_Hud_included

//Cross-Module Defines

//Callback Typesets

//////////////////
//Natives

#if !defined REQUIRE_PLUGIN
public __pl_SH_Hud_SetNTVOptional()
{
	MarkNativeAsOptional("");
}
#endif

public SharedPlugin __pl_SH_Hud = 
{
	name = "SH_Hud", 
	file = "SH_Hud.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

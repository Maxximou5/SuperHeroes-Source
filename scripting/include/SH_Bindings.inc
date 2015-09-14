#if defined _SH_Bindings_included
 #endinput
#endif
#define _SH_Bindings_included

//Cross-Module Defines
#define MAX_BINDINGS 32

//Callback Typesets

//////////////////
//Natives

#if !defined REQUIRE_PLUGIN
public __pl_SH_Bindings_SetNTVOptional()
{
	MarkNativeAsOptional("");
}
#endif

public SharedPlugin __pl_SH_Bindings =
{
	name = "SH_Bindings",
	file = "SH_Bindings.smx",
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};

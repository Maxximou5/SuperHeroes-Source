#if defined _SH_Core_included
 #endinput
#endif
#define _SH_Core_included

//Cross-Module Defines
#define MAX_QUERY_SIZE			2048
#define MAX_MAINMENU_ITEMS		32
#define MAX_MAINMENU_ITEM_SIZE	32

//Callback Typesets
typeset SH_MenuItemClickCallback
{
	function void(int client, const char[] value);
}

//////////////////
//Natives

/**
 * Executes threaded queries into SuperHeroes database and receive callbacks.
 *
 * @param callback		Callback to send data towards once completed.
 * @param sQuery		Query String to process.
 * @param data			Data to pass to the callback.
 * @param prio			Priority to give this particular query.
 *
 * @noreturn
 **/
native void SH_TQuery(SQLTCallback callback, const char[] query, any data = 0, DBPriority prio = DBPrio_Normal);

/**
 * Executes fast queries to the database with no callbacks.
 *
 * @param sQuery		Query String to process.
 *
 * @noreturn
 **/
native void SH_Query(const char[] query);

/**
 * Adds an item with a callback to the main menu.
 *
 * @param sDisplay		Name of the item in the menu.
 * @param sValue		Value sent to the callback.
 * @param callback		Callback to use once item is clicked.
 * @param iOrder		Preferred order in the main menu.
 *
 * @noreturn
 **/
native void SH_AddMainMenuItem(const char[] sDisplay, const char[] sValue = "", SH_MenuItemClickCallback callback, int iOrder = 32);

/**
 * Validates a client for you. You can check if a client is fake and/or alive as well.
 *
 * @param client		Client index.
 * @param bIsFakeClient	Check if the client is a fake client.
 * @param bIsAlive		Check if the client is alive.
 *
 * @noreturn
 **/
native bool SH_IsValidPlayer(int client, bool bIsFakeClient = false, bool bIsAlive = false);

/**
 * Opens the main menu for a client.
 *
 * @param client		Client index.
 *
 * @returne True if successful, false otherwise.
 **/
native bool SH_OpenMainMenu(int client);

//////////////////
//Forwards

/**
 * Create a forward call for when the database has connected.
 *
 * @noreturn
 **/
 forward void SH_OnDatabaseConnected();
 
 /**
 * Creates a forward call when the plugins are ready for registrations of heroes & abilities.
 *
 * @noreturn
 **/
 forward void SH_OnReady();
 
 /////////////////
 //Stocks
 stock void PushMenuCell(Handle hndl, const char[] id, int data)
{
	char DataString[64];
	IntToString(data, DataString, sizeof(DataString));
	AddMenuItem(hndl, id, DataString, ITEMDRAW_IGNORE);
}

 stock int GetMenuCell(Handle hndl, const char[] id, int DefaultValue = 0)
{
	int ItemCount = GetMenuItemCount(hndl);
	char info[64]; char data[64];
	
	for (int i = 0; i < ItemCount; i++)
	{
		GetMenuItem(hndl, i, info, sizeof(info), _, data, sizeof(data));
		
		if (StrEqual(info, id))
		{
			return StringToInt(data);
		}
	}
	
	return DefaultValue;
}

 stock bool AddMenuItemFormat(Handle &menu, const char[] info, int style = ITEMDRAW_DEFAULT, const char[] format, any...)
{
	char display[128];
	VFormat(display, sizeof(display), format, 5);
	
	return view_as<bool>AddMenuItem(menu, info, display, style);
} 


#if !defined REQUIRE_PLUGIN
public __pl_SH_Core_SetNTVOptional()
{
	MarkNativeAsOptional("SH_TQuery");
	MarkNativeAsOptional("SH_Query");
	MarkNativeAsOptional("SH_AddMainMenuItem");
	MarkNativeAsOptional("SH_IsValidPlayer");
	MarkNativeAsOptional("SH_OpenMainMenu");
}
#endif

public SharedPlugin __pl_SH_Core =
{
	name = "SH_Core",
	file = "SH_Core.smx",
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};

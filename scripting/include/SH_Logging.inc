#if defined _SH_Logging_included
  #endinput
#endif
#define _SH_Logging_included

/**
 * Logs a message to the SuperHeroes log file for default logs.
 *
 * @param format        A format string. See http://wiki.alliedmods.net/Format_Class_Functions_(SourceMod_Scripting)
 * @param ...           Variable number of format parameters.
 * @noreturn
 */
native void SH_Log(const char[] format , any ...);

/**
 * Logs a particularly low-level trace message to the SuperHeroes log file. Trace logs are low-level
 * messages primarily used by developers to trace the execution of their plugins. They typically
 * describe a position in the code and the value of surrounding parameters. Trace logs WILL generate
 * large volumes of data quickly.
 *
 * @param format        A format string. See http://wiki.alliedmods.net/Format_Class_Functions_(SourceMod_Scripting)
 * @param ...           Variable number of format parameters.
 * @noreturn
 */
native void SH_LogTrace(const char[] format , any ...);

/**
 * Logs a debug message to the SuperHeroes log file. Debug logs are low-level messages primarily used
 * by developers to debug the execution of their plugins. Debug logs typically describe the
 * parameters and outcome of some algorithmic computation, or some event that occured. Debug logs
 * may generate large volumes of data.
 *
 * @param format        A format string. See http://wiki.alliedmods.net/Format_Class_Functions_(SourceMod_Scripting)
 * @param ...           Variable number of format parameters.
 * @noreturn
 */
native void SH_LogDebug(const char[] format , any ...);

/**
 * Logs an info message to the SuperHeroes log file. Info messages should enable the server operator
 * to drill in and track activity that occured on his server in details. For example, client
 * dis/connections, client billing operations, awards granted to clients, etc.
 *
 * @param format        A format string. See http://wiki.alliedmods.net/Format_Class_Functions_(SourceMod_Scripting)
 * @param ...           Variable number of format parameters.
 * @noreturn
 */
native void SH_LogInfo(const char[] format , any ...);

/**
 * Logs a warning message to the SuperHeroes log file. Warnings should notify the server operator of
 * malfunctions that are not critical to the plugin's operation but do require attention. For
 * example, too much text disaplyed in a menu (and truncated).
 *
 * @param format        A format string. See http://wiki.alliedmods.net/Format_Class_Functions_(SourceMod_Scripting)
 * @param ...           Variable number of format parameters.
 * @noreturn
 */
native void SH_LogWarning(const char[] format , any ...);

/**
 * Logs an error message to the SuperHeroes log file. Error logs are either fatal unrecoverable errors
 * or notifications about major problems that significantly hinder a plugin's functionality. For
 * example, not being able to connect to the SuperHeroes service.
 *
 * @param format        A format string. See http://wiki.alliedmods.net/Format_Class_Functions_(SourceMod_Scripting)
 * @param ...           Variable number of format parameters.
 * @noreturn
 */
native void SH_LogError(const char[] format , any ...);

#if defined REQUIRE_PLUGIN
public __pl_SH_Logging_SetNTVOptional() 
{
	MarkNativeAsOptional("SH_Log");
	MarkNativeAsOptional("SH_LogTrace");
	MarkNativeAsOptional("SH_LogDebug");
	MarkNativeAsOptional("SH_LogInfo");
	MarkNativeAsOptional("SH_LogWarning");
	MarkNativeAsOptional("SH_LogError");
}
#endif

public SharedPlugin __pl_SH_Logging = 
{
	name = "SH_Logging",
	file = "SH_Logging.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
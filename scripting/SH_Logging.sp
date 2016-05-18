/*
	Special thanks to Bara20 for a base to work off of. I decided not to include his include with this plugin since It's fairly straight forward code.
	-https://github.com/Bara20/Extended-Logging/blob/master/addons/sourcemod/scripting/include/extended_logging.inc
	-https://forums.alliedmods.net/showthread.php?t=247769
	
	Ripped from the Store logging module, made by myself originally and Bara20, just easier this way.
*/
#pragma semicolon 1

//Includes
#include <sourcemod>
#include <SH_Core>
#include <SH_Logging>

//New Syntax
#pragma newdecls required

//Defines
#define PLUGIN_AUTHOR "Keith Warren(Drixevel)"
#define PLUGIN_VERSION "1.0.0"

//#define DEBUG				//Enable/Disable Debugs
#define CONVAR_NUMBER 17	//Number of ConVars for this plugin.

//////////////////
//Globals

//ConVar Globals
Handle hConVars[CONVAR_NUMBER];
bool cv_bStatus;
char cv_sPathing[PLATFORM_MAX_PATH]; char cv_sFileNames[256]; char cv_sDateFormat[32];
bool cv_bShow_Default = true; bool cv_bShow_Trace = true; bool cv_bShow_Debug = true; bool cv_bShow_Info = true; bool cv_bShow_Warning = true; bool cv_bShow_Error = true;
bool cv_bSubdirectories = true;
bool cv_bSub_Default = true; bool cv_bSub_Trace = true; bool cv_bSub_Debug = true; bool cv_bSub_Info = true; bool cv_bSub_Warning = true; bool cv_bSub_Error = true; 

//Enums
enum ELOG_LEVEL
{
	DEFAULT = 0,
	TRACE,
	DEBUG,
	INFO,
	WARN,
	ERROR
}

char g_sELogLevel[6][32] =
{
	"default",
	"trace",
	"debug",
	"info",
	"warn",
	"error"
};

//Plugin Info
public Plugin myinfo =
{
	name = "[SuperHeroes] Logging",
	author = PLUGIN_AUTHOR,
	description = "Handles logging for all modules/plugins to display information.",
	version = PLUGIN_VERSION,
	url = "http://www.drixevel.com/"
};

//Ask Plugin Load 2
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	CreateNative("SH_Log", Native_SH_Log);
	CreateNative("SH_LogTrace", Native_SH_LogTrace);
	CreateNative("SH_LogDebug", Native_SH_LogDebug);
	CreateNative("SH_LogInfo", Native_SH_LogInfo);
	CreateNative("SH_LogWarning", Native_SH_LogWarning);
	CreateNative("SH_LogError", Native_SH_LogError);
	
	RegPluginLibrary("SH_Logging");
	
	return APLRes_Success;
}

//On Plugin Start
public void OnPluginStart() 
{
	hConVars[0] = CreateConVar("sm_superheroes_logging_status", "1", "Status for this plugin module.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	hConVars[1] = CreateConVar("sm_superheroes_logging_path", "superheroes", "Path at which to store the logs in.", FCVAR_NOTIFY);
	hConVars[2] = CreateConVar("sm_superheroes_logging_filename", "superheroes", "File names to use when creating logs.", FCVAR_NOTIFY);
	hConVars[3] = CreateConVar("sm_superheroes_logging_date_format", "%Y-%m-%d", "Format to use when giving dates.", FCVAR_NOTIFY);
	
	hConVars[4] = CreateConVar("sm_superheroes_logging_show_default", "1", "Status to show default logs.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[5] = CreateConVar("sm_superheroes_logging_show_trace", "1", "Status to show trace logs.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[6] = CreateConVar("sm_superheroes_logging_show_debug", "1", "Status to show debug logs.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[7] = CreateConVar("sm_superheroes_logging_show_info", "1", "Status to show info logs.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[8] = CreateConVar("sm_superheroes_logging_show_warning", "1", "Status to show warning logs.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[9] = CreateConVar("sm_superheroes_logging_show_error", "1", "Status to show error logs.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	hConVars[10] = CreateConVar("sm_superheroes_logging_subfolders", "1", "Status to storing logs in subfolders.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	hConVars[11] = CreateConVar("sm_superheroes_logging_sub_default", "1", "Status of storing default logs in a subfolder.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[12] = CreateConVar("sm_superheroes_logging_sub_trace", "1", "Status of storing trace logs in a subfolder.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[13] = CreateConVar("sm_superheroes_logging_sub_debug", "1", "Status of storing debug logs in a subfolder.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[14] = CreateConVar("sm_superheroes_logging_sub_info", "1", "Status of storing info logs in a subfolder.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[15] = CreateConVar("sm_superheroes_logging_sub_warning", "1", "Status of storing warning logs in a subfolder.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[16] = CreateConVar("sm_superheroes_logging_sub_error", "1", "Status of storing error logs in a subfolder.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	for (int i = 0; i < sizeof(hConVars); i++)
	{
		HookConVarChange(hConVars[i], OnConVarsChanged);
	}
	
	RegServerCmd("sm_testshlogging", TestSHLogging);
	
	AutoExecConfig(true, "SH_Logging", "superheroes");
}

public void OnConfigsExecuted()
{
	cv_bStatus = GetConVarBool(hConVars[0]);
	
	GetConVarString(hConVars[1], cv_sPathing, sizeof(cv_sPathing));
	GetConVarString(hConVars[2], cv_sFileNames, sizeof(cv_sFileNames));
	GetConVarString(hConVars[3], cv_sDateFormat, sizeof(cv_sDateFormat));
	
	cv_bShow_Default = GetConVarBool(hConVars[4]);
	cv_bShow_Trace = GetConVarBool(hConVars[5]);
	cv_bShow_Debug = GetConVarBool(hConVars[6]);
	cv_bShow_Info = GetConVarBool(hConVars[7]);
	cv_bShow_Warning = GetConVarBool(hConVars[8]);
	cv_bShow_Error = GetConVarBool(hConVars[9]);
	
	cv_bSubdirectories = GetConVarBool(hConVars[10]);
	
	cv_bSub_Default = GetConVarBool(hConVars[11]);
	cv_bSub_Trace = GetConVarBool(hConVars[12]);
	cv_bSub_Debug = GetConVarBool(hConVars[13]);
	cv_bSub_Info = GetConVarBool(hConVars[14]);
	cv_bSub_Warning = GetConVarBool(hConVars[15]);
	cv_bSub_Error = GetConVarBool(hConVars[16]);
}

//ConVar Changes
public void OnConVarsChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StrEqual(oldValue, newValue))
	{
		return;
	}
	
	int value = StringToInt(newValue);
	
	if (convar == hConVars[0])
	{
		cv_bStatus = view_as<bool>(value);
	}
	else if (convar == hConVars[1])
	{
		strcopy(cv_sPathing, sizeof(cv_sPathing), newValue);
	}
	else if (convar == hConVars[2])
	{
		strcopy(cv_sFileNames, sizeof(cv_sFileNames), newValue);
	}
	else if (convar == hConVars[3])
	{
		strcopy(cv_sDateFormat, sizeof(cv_sDateFormat), newValue);
	}
	else if (convar == hConVars[4])
	{
		cv_bShow_Default = view_as<bool>(value);
	}
	else if (convar == hConVars[5])
	{
		cv_bShow_Trace = view_as<bool>(value);
	}
	else if (convar == hConVars[6])
	{
		cv_bShow_Debug = view_as<bool>(value);
	}
	else if (convar == hConVars[7])
	{
		cv_bShow_Info = view_as<bool>(value);
	}
	else if (convar == hConVars[8])
	{
		cv_bShow_Warning = view_as<bool>(value);
	}
	else if (convar == hConVars[9])
	{
		cv_bShow_Error = view_as<bool>(value);
	}
	else if (convar == hConVars[10])
	{
		cv_bSubdirectories = view_as<bool>(value);
	}
	else if (convar == hConVars[11])
	{
		cv_bSub_Default = view_as<bool>(value);
	}
	else if (convar == hConVars[12])
	{
		cv_bSub_Trace = view_as<bool>(value);
	}
	else if (convar == hConVars[13])
	{
		cv_bSub_Debug = view_as<bool>(value);
	}
	else if (convar == hConVars[14])
	{
		cv_bSub_Info = view_as<bool>(value);
	}
	else if (convar == hConVars[15])
	{
		cv_bSub_Warning = view_as<bool>(value);
	}
	else if (convar == hConVars[16])
	{
		cv_bSub_Error = view_as<bool>(value);
	}
}

public Action TestSHLogging(int args)
{
	SH_Log("Logging type: Default - Format: %i", 1);
	SH_LogTrace("Logging type: Trace - Format: %i", 1);
	SH_LogDebug("Logging type: Debug - Format: %i", 1);
	SH_LogInfo("Logging type: Info - Format: %i", 1);
	SH_LogWarning("Logging type: Warning - Format: %i", 1);
	SH_LogError("Logging type: Error - Format: %i", 1);
	
	PrintToServer("Test logs have been created.");
	
	return Plugin_Handled;
}

public int Native_SH_Log(Handle hPlugin, int iParams) 
{
	if (!cv_bStatus || !cv_bShow_Default) return;
	
	char sFormat[1024];
	FormatNativeString(0, 1, 2, sizeof(sFormat), _, sFormat);
	
	char sDate[24];
	FormatTime(sDate, sizeof(sDate), cv_sDateFormat, GetTime());
	
	Log_File(cv_sPathing, cv_sFileNames, sDate, DEFAULT, cv_bSub_Default, sFormat);
}

public int Native_SH_LogTrace(Handle hPlugin, int iParams) 
{
	if (!cv_bStatus || !cv_bShow_Trace) return;
	
	char sFormat[1024];
	FormatNativeString(0, 1, 2, sizeof(sFormat), _, sFormat);
	
	char sDate[24];
	FormatTime(sDate, sizeof(sDate), cv_sDateFormat, GetTime());
	
	Log_File(cv_sPathing, cv_sFileNames, sDate, TRACE, cv_bSub_Trace, sFormat);
}

public int Native_SH_LogDebug(Handle hPlugin, int iParams) 
{
	if (!cv_bStatus || !cv_bShow_Debug) return;
	
	char sFormat[1024];
	FormatNativeString(0, 1, 2, sizeof(sFormat), _, sFormat);
	
	char sDate[24];
	FormatTime(sDate, sizeof(sDate), cv_sDateFormat, GetTime());
	
	Log_File(cv_sPathing, cv_sFileNames, sDate, DEBUG, cv_bSub_Debug, sFormat);
}

public int Native_SH_LogInfo(Handle hPlugin, int iParams) 
{
	if (!cv_bStatus || !cv_bShow_Info) return;
	
	char sFormat[1024];
	FormatNativeString(0, 1, 2, sizeof(sFormat), _, sFormat);
	
	char sDate[24];
	FormatTime(sDate, sizeof(sDate), cv_sDateFormat, GetTime());
	
	Log_File(cv_sPathing, cv_sFileNames, sDate, INFO, cv_bSub_Info, sFormat);
}

public int Native_SH_LogWarning(Handle hPlugin, int iParams) 
{
	if (!cv_bStatus || !cv_bShow_Warning) return;
	
	char sFormat[1024];
	FormatNativeString(0, 1, 2, sizeof(sFormat), _, sFormat);
	
	char sDate[24];
	FormatTime(sDate, sizeof(sDate), cv_sDateFormat, GetTime());
	
	Log_File(cv_sPathing, cv_sFileNames, sDate, WARN, cv_bSub_Warning, sFormat);
}

public int Native_SH_LogError(Handle hPlugin, int iParams) 
{
	if (!cv_bStatus || !cv_bShow_Error) return;
	
	char sFormat[1024];
	FormatNativeString(0, 1, 2, sizeof(sFormat), _, sFormat);
	
	char sDate[24];
	FormatTime(sDate, sizeof(sDate), cv_sDateFormat, GetTime());
	
	Log_File(cv_sPathing, cv_sFileNames, sDate, ERROR, cv_bSub_Error, sFormat);
}

void Log_File(const char[] sPath = "superheroes", const char[] sFile = "superheroes", const char[] sDate = "", ELOG_LEVEL eLevel = DEFAULT, bool bLogToFolder = false, const char[] format, any ...)
{
	if (!cv_bSubdirectories && bLogToFolder)
	{
		bLogToFolder = false;
	}
	
	char sPath_Build[PLATFORM_MAX_PATH + 1]; char sLevelPath[PLATFORM_MAX_PATH + 1]; char sFile_Build[PLATFORM_MAX_PATH + 1]; char sBuffer[1024];

	if (strlen(sPath) != 0)
	{
		BuildPath(Path_SM, sPath_Build, sizeof(sPath_Build), "logs/%s", sPath);
		
		if(!DirExists(sPath_Build))
		{
			CreateDirectory(sPath_Build, 511);
		}
	}
	else
	{
		BuildPath(Path_SM, sPath_Build, sizeof(sPath_Build), "logs");
	}

	if (bLogToFolder)
	{
		Format(sLevelPath, sizeof(sLevelPath), "%s/%s", sPath_Build, g_sELogLevel[eLevel]);
	}
	else
	{
		Format(sLevelPath, sizeof(sLevelPath), "%s", sPath_Build);
	}

	
	if (!DirExists(sLevelPath))
	{
		CreateDirectory(sLevelPath, 511);
	}

	if (strlen(sDate) != 0)
	{
		Format(sFile_Build, sizeof(sFile_Build), "%s/%s_%s.log", sLevelPath, sFile, sDate);
	}
	else
	{
		Format(sFile_Build, sizeof(sFile_Build), "%s/%s.log", sLevelPath, sFile);
	}

	VFormat(sBuffer, sizeof(sBuffer), format, 7);
	Format(sBuffer, sizeof(sBuffer), "[SuperHeroes] %s", sBuffer);
	LogToFileEx(sFile_Build, sBuffer);
}
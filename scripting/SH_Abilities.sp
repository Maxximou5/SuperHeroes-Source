#pragma semicolon 1

//Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <SH_Core>
#include <SH_Heroes>
#include <SH_Abilities>
#include <SH_Logging>

//New Syntax
#pragma newdecls required

//Defines
#define PLUGIN_AUTHOR "Keith Warren(Drixevel)"
#define PLUGIN_VERSION "1.0.0"

//#define DEBUG				//Enable/Disable Debugs
#define CONVAR_NUMBER 1		//Number of ConVars for this plugin.

//////////////////
//Globals

Handle hConVars[CONVAR_NUMBER];
bool cv_bStatus;

Handle hF_OnTakeDamage;
Handle hF_OnTakeDamage_Post;

bool bIsLateLoad;

//Ability Registration Handlers
Handle hAbilityPacks;
Handle hAbilityTrie;
Handle hAbilityCommandTrie;

//Ability Assigned to Hero
int iHeroAbility[MAX_HEROES] =  { -1, ... };

//Client Globals
int iCooldowns[MAXPLAYERS + 1];
bool bNoAbility[MAXPLAYERS + 1];

//Plugin Info
public Plugin myinfo =
{
	name = "[SuperHeroes] Abilities",
	author = PLUGIN_AUTHOR,
	description = "Handles Hero Abilties and player binding settings.",
	version = PLUGIN_VERSION,
	url = "http://www.drixevel.com/"
};

//Ask Plugin Load 2
public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrorSize)
{
	CreateNative("SH_RegisterAbility", Native_RegisterAbility);
	CreateNative("SH_AssignHeroAbility", Native_AssignHeroAbility);
	CreateNative("SH_IsValidAbility", Native_IsValidAbility);
	CreateNative("SH_CreateAbilityCommand", Native_CreateAbilityCommand);
	
	CreateNative("SH_GetTargetInViewCone", Native_GetTargetInViewCone);
	CreateNative("SH_GetAimEndPoint", Native_GetAimEndPoint);
	
	CreateNative("SH_GetAbilityID", Native_GetAbilityID);
	CreateNative("SH_GetAbilityName", Native_GetAbilityName);
	CreateNative("SH_GetAbilityDisplayName", Native_GetAbilityDisplayName);
	CreateNative("SH_GetAbilityDescription", Native_GetAbilityDescription);
	CreateNative("SH_GetAbilityCooldown", Native_GetAbilityCooldown);
	
	CreateNative("SH_ListAbilities", Native_ListAbilities);
	
	hF_OnTakeDamage = CreateGlobalForward("SH_OnTakeDamage", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Cell, Param_Cell, Param_Array, Param_Array);
	hF_OnTakeDamage_Post = CreateGlobalForward("SH_OnTakeDamage_Post", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Cell, Param_Cell, Param_Array, Param_Array);
	
	RegPluginLibrary("SH_Abilities");
	
	bIsLateLoad = bLate;
	return APLRes_Success;
}

//On Plugin Start
public void OnPluginStart()
{
	hConVars[0] = CreateConVar("sm_superheroes_abilities_status", "1", "Status of the plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	for (int i = 0; i < sizeof(hConVars); i++)
	{
		HookConVarChange(hConVars[i], OnConVarsChanged);
	}
	
	hAbilityPacks = CreateArray();
	hAbilityTrie = CreateTrie();
	hAbilityCommandTrie = CreateTrie();
	
	AutoExecConfig(true, "SH_Abilities", "superheroes");
}

//On Configs Executed
public void OnConfigsExecuted()
{
	cv_bStatus = GetConVarBool(hConVars[0]);
	
	if (bIsLateLoad)
	{
		
		bIsLateLoad = false;
	}
}

//ConVar Changes
public void OnConVarsChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	int value = StringToInt(newValue);
	
	if (convar == hConVars[0])
	{
		cv_bStatus = view_as<bool>value;
	}
}

public void OnClientPutInServer(int client)
{
	if (!cv_bStatus)
	{
		return;
	}
	
	iCooldowns[client] = 0;
	bNoAbility[client] = false;
	
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamage_Post);
}

public void OnClientDisconnect(int client)
{
	if (!cv_bStatus)
	{
		return;
	}
	
	iCooldowns[client] = 0;
	bNoAbility[client] = false;
}

//Hooks OnTakeDamage from SDKHooks for a forward.
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (!cv_bStatus)
	{
		return Plugin_Continue;
	}
	
	//Called when a player takes damage. This is a forward you can use so you don't have to hook into SDKHooks OnTakeDamage event yourself.
	Call_StartForward(hF_OnTakeDamage);
	Call_PushCell(victim); //Client Index
	Call_PushCell(attacker); //Attacker Index
	Call_PushCell(inflictor); //Inflictor Index
	Call_PushFloat(damage); //Damage Float
	Call_PushCell(damagetype); //Damage Type
	Call_PushCell(weapon); //Weapon Index
	Call_PushArray(damageForce, sizeof(damageForce)); //Damage Force Array
	Call_PushArray(damagePosition, sizeof(damagePosition)); //Damage Position Array
	
	Action result = Plugin_Continue;
	Call_Finish(result);
	
	SH_LogTrace("[Call] SH_OnTakeDamage - victim:%i attacker:%i inflictor:%i damage:%f damagetype:%i weapon:%i damageForce:%f-%f-%f damagePosition:%f-%f-%f", victim, attacker, inflictor, damage, damagetype, weapon, damageForce[0], damageForce[1], damageForce[2], damagePosition[0], damagePosition[1], damagePosition[2]);
	
	return result;
}

//Hooks OnTakeDamagePost from SDKHooks for a forward.
public void OnTakeDamage_Post(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float[3] damageForce, const float[3] damagePosition)
{
	if (!cv_bStatus)
	{
		return;
	}
	
	//Called after a player takes damage. This is a forward you can use so you don't have to hook into SDKHooks OnTakeDamage event yourself.
	Call_StartForward(hF_OnTakeDamage_Post);
	Call_PushCell(victim); //Client Index
	Call_PushCell(attacker); //Attacker Index
	Call_PushCell(inflictor); //Inflictor Index
	Call_PushFloat(damage); //Damage Float
	Call_PushCell(damagetype); //Damage Type
	Call_PushCell(weapon); //Weapon Index
	Call_PushArray(damageForce, sizeof(damageForce)); //Damage Force Array
	Call_PushArray(damagePosition, sizeof(damagePosition)); //Damage Position Array
	
	SH_LogTrace("[Call] SH_OnTakeDamage_Post - victim:%i attacker:%i inflictor:%i damage:%f damagetype:%i weapon:%i damageForce:%f-%f-%f damagePosition:%f-%f-%f", victim, attacker, inflictor, damage, damagetype, weapon, damageForce[0], damageForce[1], damageForce[2], damagePosition[0], damagePosition[1], damagePosition[2]);
	
	bool result;
	Call_Finish(result);
}

//Timer to handle cooldown logic for abilities.
public Action AbilityCooldown(Handle hTimer, any data)
{
	if (!cv_bStatus)
	{
		return Plugin_Stop;
	}
	
	int client = GetClientOfUserId(client);
	
	if (!SH_IsValidPlayer(client, true, true))
	{
		return Plugin_Stop;
	}
	
	iCooldowns[client]--;
	
	if (iCooldowns[client] <= 0)
	{
		iCooldowns[client] = 0;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

//Registers a new ability, most of the logic for handling the ability is put into a pack which is then used later on usage or information being pulled.
int RegisterAbility(const char[] sName, const char[] sDisplayName, const char[] sDescription, SH_UseAbilityCallback callback_press = INVALID_FUNCTION, SH_UseAbilityCallback callback_release = INVALID_FUNCTION, int iCooldown = 0, Handle hPlugin)
{
	Handle hPack = CreateDataPack();
	WritePackCell(hPack, hPlugin);
	WritePackFunction(hPack, callback_press);
	WritePackFunction(hPack, callback_release);
	WritePackString(hPack, sName);
	WritePackString(hPack, sDisplayName);
	WritePackString(hPack, sDescription);
	WritePackCell(hPack, iCooldown);
	
	int index = PushArrayCell(hAbilityPacks, hPack);
	SetTrieValue(hAbilityTrie, sName, index);
	
	SH_LogInfo("New Ability Registered: Index:%i Name:%s Display Name:%s Description:%s Cooldown:%i", index, sName, sDisplayName, sDescription, iCooldown);
	
	return index;
}

//Checks if an ability exists.
bool IsValidAbility(const char[] sName)
{
	int value;
	for (int i = 0; i < GetTrieSize(hAbilityTrie); i++)
	{
		if (GetTrieValue(hAbilityTrie, sName, value))
		{
			return true;
		}
	}
	
	return false;
}

//Converts an abilities name to a valid ID, otherwise returns -1.
int GetAbilityID(const char[] sName)
{
	int value;
	for (int i = 0; i < GetTrieSize(hAbilityTrie); i++)
	{
		if (GetTrieValue(hAbilityTrie, sName, value))
		{
			return value;
		}
	}
	
	return -1;
}

//Retrieves an abilities name from its ID.
bool GetAbilityName(int AbilityID, char[] sAbilityName, int size)
{
	Handle hPack = CloneHandle(view_as<Handle>GetArrayCell(hAbilityPacks, AbilityID));
	ResetPack(hPack);
	
	ReadPackCell(hPack);
	ReadPackFunction(hPack);
	ReadPackFunction(hPack);
	
	char sName[MAX_ABILITY_NAME_LENGTH];
	ReadPackString(hPack, sName, sizeof(sName));
	
	char sDisplayName[MAX_ABILITY_DISPLAY_NAME_LENGTH];
	ReadPackString(hPack, sDisplayName, sizeof(sDisplayName));
	
	char sDescription[MAX_ABILITY_DESCRIPTION_LENGTH];
	ReadPackString(hPack, sDescription, sizeof(sDescription));
	
	ReadPackCell(hPack);
	
	CloseHandle(hPack);
	
	strcopy(sAbilityName, size, sName);
	
	return true;
}

//Retrieves an abilities display name from its ID.
bool GetAbilityDisplayName(int AbilityID, char[] sAbilityName, int size)
{
	Handle hPack = CloneHandle(view_as<Handle>GetArrayCell(hAbilityPacks, AbilityID));
	ResetPack(hPack);
	
	ReadPackCell(hPack);
	ReadPackFunction(hPack);
	ReadPackFunction(hPack);
	
	char sName[MAX_ABILITY_NAME_LENGTH];
	ReadPackString(hPack, sName, sizeof(sName));
	
	char sDisplayName[MAX_ABILITY_DISPLAY_NAME_LENGTH];
	ReadPackString(hPack, sDisplayName, sizeof(sDisplayName));
	
	char sDescription[MAX_ABILITY_DESCRIPTION_LENGTH];
	ReadPackString(hPack, sDescription, sizeof(sDescription));
	
	ReadPackCell(hPack);
	
	CloseHandle(hPack);
	
	strcopy(sAbilityName, size, sDisplayName);
	
	return true;
}

//Retrieves an abilities description from its ID.
bool GetAbilityDescription(int AbilityID, char[] sAbilityDescription, int size)
{
	Handle hPack = CloneHandle(view_as<Handle>GetArrayCell(hAbilityPacks, AbilityID));
	ResetPack(hPack);
	
	ReadPackCell(hPack);
	ReadPackFunction(hPack);
	ReadPackFunction(hPack);
	
	char sName[MAX_ABILITY_NAME_LENGTH];
	ReadPackString(hPack, sName, sizeof(sName));
	
	char sDisplayName[MAX_ABILITY_DISPLAY_NAME_LENGTH];
	ReadPackString(hPack, sDisplayName, sizeof(sDisplayName));
	
	char sDescription[MAX_ABILITY_DESCRIPTION_LENGTH];
	ReadPackString(hPack, sDescription, sizeof(sDescription));
	
	ReadPackCell(hPack);
	
	CloseHandle(hPack);
	
	strcopy(sAbilityDescription, size, sDescription);
	
	return true;
}

//Retrieves an abilities cooldown from its ID.
int GetAbilityCooldown(int AbilityID)
{
	Handle hPack = CloneHandle(view_as<Handle>GetArrayCell(hAbilityPacks, AbilityID));
	ResetPack(hPack);
	
	ReadPackCell(hPack);
	ReadPackFunction(hPack);
	ReadPackFunction(hPack);
	
	char sName[MAX_ABILITY_NAME_LENGTH];
	ReadPackString(hPack, sName, sizeof(sName));
	
	char sDisplayName[MAX_ABILITY_DISPLAY_NAME_LENGTH];
	ReadPackString(hPack, sDisplayName, sizeof(sDisplayName));
	
	char sDescription[MAX_ABILITY_DESCRIPTION_LENGTH];
	ReadPackString(hPack, sDescription, sizeof(sDescription));
	
	int iCooldown = ReadPackCell(hPack);
	
	CloseHandle(hPack);
	
	return iCooldown;
}

//Adds a console command for clients to use an ability.
void AddAbilityCommand(int AbilityID, const char[] sName)
{
	char sCommandPlus[MAX_ABILITY_COMMAND_LENGTH + 1];
	Format(sCommandPlus, sizeof(sCommandPlus), "+%s", sName);
	RegConsoleCmd(sCommandPlus, OnAbilityNativeUse);
	
	char sCommandMinus[MAX_ABILITY_COMMAND_LENGTH + 1];
	Format(sCommandMinus, sizeof(sCommandMinus), "-%s", sName);
	RegConsoleCmd(sCommandMinus, OnAbilityNativeUse);
	
	SetTrieValue(hAbilityCommandTrie, sName, AbilityID);
	
	SH_LogInfo("Command %s registered to the AbilityID %i. [%s-%s]", sName, AbilityID, sCommandPlus, sCommandMinus);
}

//Universal command registered to use abilities with binds.
public Action OnAbilityNativeUse(int client, int args)
{
	char sCommand[MAX_ABILITY_COMMAND_LENGTH];
	GetCmdArg(0, sCommand, sizeof(sCommand));
	
	bool bPress = view_as<bool>StrContains(sCommand, "+") != -1;
	
	int AbilityID;
	GetTrieValue(hAbilityCommandTrie, sCommand, AbilityID);
	
	UseAbility(client, AbilityID, bPress);
	
	return Plugin_Handled;
}

//Function to check and use an ability.
void UseAbility(int client, int AbilityID, bool bPress)
{
	int HeroID = AbilityIDToHeroID(AbilityID);
	
	if (!SH_IsClientHero(client, HeroID))
	{
		PrintToChat(client, "You are not currently this hero.");
		
		bNoAbility[client] = true;
		CreateTimer(10.0, NoAbilityTimer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		
		return;
	}
	
	Handle hPack = CloneHandle(view_as<Handle>GetArrayCell(hAbilityPacks, AbilityID));
	ResetPack(hPack);
	
	Handle plugin = view_as<Handle>ReadPackCell(hPack);
	SH_UseAbilityCallback callback_press = view_as<SH_UseAbilityCallback>ReadPackFunction(hPack);
	SH_UseAbilityCallback callback_release = view_as<SH_UseAbilityCallback>ReadPackFunction(hPack);
	
	char sName[MAX_ABILITY_NAME_LENGTH];
	ReadPackString(hPack, sName, sizeof(sName));
	
	char sDisplayName[MAX_ABILITY_DISPLAY_NAME_LENGTH];
	ReadPackString(hPack, sDisplayName, sizeof(sDisplayName));
	
	char sDescription[MAX_ABILITY_DESCRIPTION_LENGTH];
	ReadPackString(hPack, sDescription, sizeof(sDescription));
	
	int iCooldown = ReadPackCell(hPack);
	
	CloseHandle(hPack);
	
	if (iCooldown < iCooldowns[client])
	{
		PrintToChat(client, "Your hero ability is currently on cooldown: %i", iCooldowns[client]);
		return;
	}
	
	Call_StartFunction(plugin, bPress ? callback_press : callback_release);
	Call_PushCell(client);
	Call_PushString(sName);
	Call_PushString(sDisplayName);
	Call_PushString(sDescription);
	Call_Finish();
	
	iCooldowns[client] = iCooldown;
	CreateTimer(1.0, AbilityCooldown, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

//Re-enable the clients ability after cooldown is registered if the ability was successful.
public Action NoAbilityTimer(Handle hTimer, any data)
{
	int client = GetClientOfUserId(data);
	
	if (!SH_IsValidPlayer(client))
	{
		bNoAbility[client] = false;
	}
}

//Converts an AbilityID to a HeroID. (Garbage atm)
int AbilityIDToHeroID(int AbilityID)
{
	for (int i = 0; i < MAX_HEROES; i++)
	{
		if (iHeroAbility[i] == AbilityID)
		{
			return i;
		}
	}
	
	return -1;
}

//////////////////
//Natives

//Registers a new ability for Heroes to use.
public int Native_RegisterAbility(Handle hPlugin, int iParams)
{
	char sName[MAX_ABILITY_NAME_LENGTH];
	GetNativeString(1, sName, sizeof(sName));
	
	char sDisplayName[MAX_ABILITY_DISPLAY_NAME_LENGTH];
	GetNativeString(2, sDisplayName, sizeof(sDisplayName));
	
	char sDescription[MAX_ABILITY_DESCRIPTION_LENGTH];
	GetNativeString(3, sDescription, sizeof(sDescription));
	
	int iCooldown = GetNativeCell(4);
	
	return RegisterAbility(sName, sDisplayName, sDescription, view_as<SH_UseAbilityCallback>GetNativeFunction(5), view_as<SH_UseAbilityCallback>GetNativeFunction(6), iCooldown, hPlugin);
}

//Assigns a specific ability to a hero.
public int Native_AssignHeroAbility(Handle hPlugin, int iParams)
{
	int ID = GetNativeCell(1);
	
	if (!SH_IsHeroValid(ID))
	{
		return false;
	}
	
	iHeroAbility[ID] = GetNativeCell(2);
	
	SH_LogInfo("Hero %i has been assigned the ability %i.", ID, iHeroAbility[ID]);
	
	return true;
}

//Check for a name of an ability to see if it's valid or not.
public int Native_IsValidAbility(Handle hPlugin, int iParams)
{
	char sName[MAX_ABILITY_NAME_LENGTH];
	GetNativeString(1, sName, sizeof(sName));
	
	return IsValidAbility(sName);
}

//Creates and assigns a console command to the ability.
public int Native_CreateAbilityCommand(Handle hPlugin, int iParams)
{
	int AbilityID = GetNativeCell(1);
	
	char sName[MAX_ABILITY_COMMAND_LENGTH];
	GetNativeString(2, sName, sizeof(sName));
	
	AddAbilityCommand(AbilityID, sName);
}

//Stock function if heroes want to use abilities that require cone targeting.
public int Native_GetTargetInViewCone(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!SH_IsValidPlayer(client, false, true))
	{
		return false;
	}
	
	int target = GetNativeCell(2);
	
	if (SH_IsValidPlayer(target, false, true))
	{
		return false;
	}
	
	float angle = view_as<float>GetNativeCell(3);
	
	if (angle < 0.0 || angle > 360.0)
	{
		return false;
	}
	
	float distance = view_as<float>GetNativeCell(4);
	bool heightcheck = view_as<bool>GetNativeCell(5);
	bool negativeangle = view_as<bool>GetNativeCell(6);
	
	return IsTargetInSightRange(client, target, angle, distance, heightcheck, negativeangle);
}

bool IsTargetInSightRange(int client, int target, float angle = 90.0, float distance = 0.0, bool heightcheck = true, bool negativeangle = false)
{
	float targetvector[3]; float resultangle; float resultdistance;
	
	float anglevector[3];
	GetClientEyeAngles(client, anglevector);
	
	anglevector[0] = anglevector[2] = 0.0;
	
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	
	if (negativeangle)
	{
		NegateVector(anglevector);
	}
	
	float clientpos[3];
	GetClientAbsOrigin(client, clientpos);
	
	float targetpos[3];
	GetClientAbsOrigin(target, targetpos);
	
	if (heightcheck && distance > 0.0)
	{
		resultdistance = GetVectorDistance(clientpos, targetpos);
	}
	
	clientpos[2] = targetpos[2] = 0.0;
	MakeVectorFromPoints(clientpos, targetpos, targetvector);
	NormalizeVector(targetvector, targetvector);
	
	resultangle = RadToDeg(ArcCosine(GetVectorDotProduct(targetvector, anglevector)));
	
	if (resultangle <= angle / 2)
	{
		if (distance > 0)
		{
			if (!heightcheck)
			{
				resultdistance = GetVectorDistance(clientpos, targetpos);
			}
			
			if (distance >= resultdistance)
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		else
		{
			return true;
		}
	}
	else
	{
		return false;
	}
}

//Stock function to retrieve the clients crosshair location.
public int Native_GetAimEndPoint(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	float fAngle[3];
	GetClientEyeAngles(client, fAngle);
	
	float fPosition[3];
	GetClientEyePosition(client, fPosition);
	
	TR_TraceRayFilter(fPosition, fAngle, MASK_ALL, RayType_Infinite, AimTargetFilter);
	
	float fEndPosition[3];
	TR_GetEndPosition(fEndPosition);
	
	SetNativeArray(2, fEndPosition, 3);
}

public bool AimTargetFilter(int entity, int mask, any data)
{
	return view_as<bool>(entity != data);
}

//Check for a name of an ability to see if it's valid or not.
public int Native_GetAbilityID(Handle plugin, int numParams)
{
	char sName[MAX_ABILITY_NAME_LENGTH];
	GetNativeString(1, sName, sizeof(sName));
	
	return GetAbilityID(sName);
}

public int Native_GetAbilityName(Handle plugin, int numParams)
{
	int AbilityID = GetNativeCell(1);
	int size = GetNativeCell(3);
	
	char[] sName = new char[size];
	bool bReturn = GetAbilityName(AbilityID, sName, size);
	
	SetNativeString(2, sName, size);
	
	return bReturn;
}

public int Native_GetAbilityDisplayName(Handle plugin, int numParams)
{
	int AbilityID = GetNativeCell(1);
	int size = GetNativeCell(3);
	
	char[] sName = new char[size];
	bool bReturn = GetAbilityDisplayName(AbilityID, sName, size);
	
	SetNativeString(2, sName, size);
	
	return bReturn;
}

public int Native_GetAbilityDescription(Handle plugin, int numParams)
{
	int AbilityID = GetNativeCell(1);
	int size = GetNativeCell(3);
	
	char[] sDescription = new char[size];
	bool bReturn = GetAbilityDescription(AbilityID, sDescription, size);
	
	SetNativeString(2, sDescription, size);
	
	return bReturn;
}

public int Native_GetAbilityCooldown(Handle plugin, int numParams)
{
	int AbilityID = GetNativeCell(1);
	
	return GetAbilityCooldown(AbilityID);
}

//Retrieves a total list of abilities based on the HeroID given and the method used.
//Method: 1 = Menu Items, 2 = Character String
public int Native_ListAbilities(Handle plugin, int numParams)
{
	int HeroID = GetNativeCell(1);
	
	if (iHeroAbility[HeroID] == -1)
	{
		return false;
	}
	
	int Method = GetNativeCell(2);
	int size = GetNativeCell(4);
	Handle hMenu = view_as<Handle>GetNativeCell(5);
	
	switch (Method)
	{
		case 1:
		{
			RefillAbilitiesMenu(HeroID, hMenu);
		}
		case 2:
		{
			int AbilityID = iHeroAbility[HeroID];
			
			char sDisplayName[64];
			SH_GetAbilityDisplayName(AbilityID, sDisplayName, sizeof(sDisplayName));
			
			char sName[64];
			GetAbilityName(AbilityID, sName, sizeof(sName));
			
			char sDisplay[128];
			Format(sDisplay, sizeof(sDisplay), "%s [%s]", sDisplayName, sName);
			
			SetNativeString(3, sDisplay, size);
		}
	}
	
	return true;
}

void RefillAbilitiesMenu(int HeroID, Handle hMenu)
{
	int AbilityID = iHeroAbility[HeroID];
	
	char sDisplay[64];
	GetAbilityName(AbilityID, sDisplay, sizeof(sDisplay));
	
	char sID[32];
	IntToString(AbilityID, sID, sizeof(sID));
	
	AddMenuItem(hMenu, sID, sDisplay);
}
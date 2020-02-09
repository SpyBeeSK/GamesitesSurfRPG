//Includes
#include <sourcemod>
#include <smlib>

//Defines
#define PLUGIN_VERSION "1.0.2"

//Other
#pragma semicolon 1
#pragma newdecls required

//Cvars
ConVar g_cvKillFeed;

public Plugin myinfo = {
	name        = "[CS:GO] Fortnite kill feed",
	author      = "Javierko",
	description = "",
	version     = PLUGIN_VERSION,
	url         = "github.com/Javierko"
};

public void OnPluginStart()
{
	//Events
	HookEvent("player_death", Event_PlayerDeath_Pre, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath);
	
	//Cvars
	g_cvKillFeed = CreateConVar("sm_kf_disable", "0", "1 - Kill feed will be disabled, 0 - enabled", _, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "fortnitekillfeed");
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker")); 
	
	char sWeapon[512];
	event.GetString("weapon", sWeapon, sizeof(sWeapon));
	
	for (int i = 1; i <= MaxClients; i++) 
	{
		if(IsValidClient(i))
		{
			if(i == attacker)
			{
				if(IsWeaponShotgun(sWeapon))
				{
					PrintToChat(attacker, " \x06%N \x01shotgunned \x02%N", attacker, victim);
				}
				else if(IsWeaponRifle(sWeapon))
				{
					PrintToChat(attacker, " \x06%N \x01eliminated \x02%N \x01with a rifle", attacker, victim);
				}
				else if(IsWeaponPistol(sWeapon))
				{
					PrintToChat(attacker, " \x06%N \x01eliminated \x02%N \x01with a pistol", attacker, victim);
				}
				else if(IsWeaponSMG(sWeapon))
				{
					PrintToChat(attacker, " \x06%N \x01eliminated \x02%N \x01with an SMG", attacker, victim);
				}
				else if(IsWeaponScope(sWeapon))
				{
					float distance;   
					
					distance = Entity_GetDistance(attacker, victim);
					distance = Math_UnitsToMeters(distance);	
					
					PrintToChat(attacker, " \x06%N \x01sniped \x02%N (%01.0fm)", attacker, victim, distance);
				}
				else if(IsWeaponHeavy(sWeapon))
				{
					PrintToChat(attacker, " \x06%N \x01eliminated \x02%N \x01with a heavy gun", attacker, victim);
				}
				else if(IsWeaponKnife(sWeapon))
				{
					PrintToChat(attacker, " \x06%N \x01eliminated \x02%N \x01with knife", attacker, victim);
				}
			}
			else
			{
				if(IsWeaponShotgun(sWeapon))
				{
					PrintToChat(i, " \x0D%N \x01shotgunned \x02%N", attacker, victim);
				}
				else if(IsWeaponRifle(sWeapon))
				{
					PrintToChat(i, " \x0D%N \x01eliminated \x02%N \x01with a rifle", attacker, victim);
				}
				else if(IsWeaponPistol(sWeapon))
				{
					PrintToChat(i, " \x0D%N \x01eliminated \x02%N \x01with a pistol", attacker, victim);
				}
				else if(IsWeaponSMG(sWeapon))
				{
					PrintToChat(i, " \x0D%N \x01eliminated \x02%N \x01with an SMG", attacker, victim);
				}
				else if(IsWeaponScope(sWeapon))
				{
					float distance;
					
					distance = Entity_GetDistance(attacker, victim);
					distance = Math_UnitsToMeters(distance);   
					
					PrintToChat(i, " \x0D%N \x01sniped \x02%N (%01.0fm)", attacker, victim, distance);
				}
				else if(IsWeaponHeavy(sWeapon))
				{
					PrintToChat(i, " \x0D%N \x01eliminated \x02%N \x01with a heavy gun", attacker, victim);
				}
				else if(IsWeaponKnife(sWeapon))
				{
					PrintToChat(i, " \x0D%N \x01eliminated \x02%N \x01with knife", attacker, victim);
				}
			}
		}
	}
}

public Action Event_PlayerDeath_Pre(Event event, const char[] name, bool dontBroadcast)
{
	if(g_cvKillFeed.BoolValue)
	{
		event.BroadcastDisabled = true;  
	}
	
	return Plugin_Continue;
}

stock bool IsWeaponShotgun(const char[] sWeapon)
{
	if(	StrEqual(sWeapon, "xm1014") || 
		StrEqual(sWeapon, "mag7") || 
		StrEqual(sWeapon, "sawedoff") || 
		StrEqual(sWeapon, "nova"))
	{
		return true;
	}
	return false;
}

stock bool IsWeaponRifle(const char[] sWeapon)
{
	if(	StrEqual(sWeapon, "ak47") || 
		StrEqual(sWeapon, "famas") || 
		StrEqual(sWeapon, "aug") || 
		StrEqual(sWeapon, "galilar") ||
		StrEqual(sWeapon, "m4a1") ||
		StrEqual(sWeapon, "sg556") ||
		StrEqual(sWeapon, "m4a1_silencer"))
	{
		return true;
	}
	return false;
}

stock bool IsWeaponPistol(const char[] sWeapon)
{
	if( StrEqual(sWeapon, "deagle") || 
		StrEqual(sWeapon, "elite") || 
		StrEqual(sWeapon, "fiveseven") || 
		StrEqual(sWeapon, "glock") ||
		StrEqual(sWeapon, "tec9") ||
		StrEqual(sWeapon, "hkp2000") ||
		StrEqual(sWeapon, "p250") ||
		StrEqual(sWeapon, "usp_silencer") ||
		StrEqual(sWeapon, "cz75a") ||
		StrEqual(sWeapon, "revolver"))
	{
		return true;
	}
	return false;
}

stock bool IsWeaponSMG(const char[] sWeapon)
{
	if( StrEqual(sWeapon, "mac10") || 
		StrEqual(sWeapon, "p90") || 
		StrEqual(sWeapon, "ump45") || 
		StrEqual(sWeapon, "bizon") ||
		StrEqual(sWeapon, "mp7") ||
		StrEqual(sWeapon, "mp9"))
	{
		return true;
	}
	return false;
}

stock bool IsWeaponScope(const char[] sWeapon)
{
	if( StrEqual(sWeapon, "awp") || 
		StrEqual(sWeapon, "g3sg1") || 
		StrEqual(sWeapon, "scar20") || 
		StrEqual(sWeapon, "ssg08"))
	{
		return true;
	}
	return false;
}

stock bool IsWeaponHeavy(const char[] sWeapon)
{
	if( StrEqual(sWeapon, "m249") || 
		StrEqual(sWeapon, "negev"))
	{
		return true;
	}
	return false;
}

stock bool IsWeaponKnife(const char[] sWeapon)
{
	if(	StrEqual(sWeapon, "knife") || 
		StrEqual(sWeapon, "bayonet"))
	{
		return true;
	}
	return false;
}

stock bool IsValidClient(int client)
{
	if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client)) 
	{
		return true;
	}
	return false;
}
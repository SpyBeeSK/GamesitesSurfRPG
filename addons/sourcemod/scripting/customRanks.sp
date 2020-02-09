#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Klaus"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <rankme>
#include <chat-processor>
#define PREFIX " \x04[Ranks]\x01"
#define MENUPREFIX "[Ranks]"

#define MAX_RANKS 32

char g_sRanks[MAX_RANKS][256];
char g_sRanksColors[MAX_RANKS][32];

char g_sColorsNames[][] =  { "WHITE", "DARK_RED", "PURPLE", "GREEN", "TURQUISE", "LIME_GREEN", "RED", "GREY", "YELLOW", "ORANGE", "PINK", "LIGHT_BLUE", "BLUE" };
char g_sColorsCodes[][] =  { "\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08", "\x09", "\x10", "\x0E", "\x0A", "\x0C" };

int g_iRanksPoints[MAX_RANKS];
int g_iRank[MAXPLAYERS + 1];


public Plugin myinfo = 
{
	name = "Custom Ranks", 
	author = PLUGIN_AUTHOR, 
	description = "Custom ranks based on RankMe points", 
	version = PLUGIN_VERSION, 
	url = "https://steamcommunity.com/id/KlausLaw/"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_ranks", SM_Ranks);
	HookEvent("player_spawn", Event_PlayerSpawn);
	loadRanks();
}

public Action RankMe_OnPlayerLoaded(client)
{
	getPlayerRank(client);
}

public Action Event_PlayerSpawn(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	getPlayerRank(client);
	return Plugin_Continue;
}

public Action CP_OnChatMessage(int & author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool & processcolors, bool & removecolors)
{
	Format(name, MAX_NAME_LENGTH, " \x07[%s%s\x07]\x03 %s", g_sRanksColors[g_iRank[author]], g_sRanks[g_iRank[author]], name);
	return Plugin_Continue;
}

public Action SM_Ranks(int client, int args)
{
	openRanksMenu(client);
	return Plugin_Handled;
}

void openRanksMenu(int client)
{
	Menu menu = new Menu(Menu_Ranks);
	menu.SetTitle("%s - Ranks list\n \n• Rank: %s", MENUPREFIX, g_sRanks[g_iRank[client]]);

	char sRank[12], sItem[128];
	for (int i = 0; i < sizeof(g_sRanks); i++)
	{
		if (strlen(g_sRanks[i]) <= 0)break;
		IntToString(i, sRank, sizeof(sRank));
		Format(sItem, sizeof(sItem), "%s", g_sRanks[i]);
		menu.AddItem(sRank, sItem);
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_Ranks(Menu menu, MenuAction action, int client, int Position)
{
	if (action == MenuAction_Select)
	{
		char sItem[12];
		menu.GetItem(Position, sItem, sizeof(sItem));
		int iRank = StringToInt(sItem);
		PrintToChat(client, "%s Rank %s%s\x01: You need \x07%d\x01 points in order to achieve this rank.", PREFIX, g_sRanksColors[iRank], g_sRanks[iRank], g_iRanksPoints[iRank]);
		openRanksMenu(client);
	}
	if (action == MenuAction_End)
	{
		delete menu;
	}
}

void getPlayerRank(int client)
{
	int iPoints = RankMe_GetPoints(client);
	int iMaxRank = 0;
	for (int i = 0; i < sizeof(g_sRanks); i++)
	{
		if (strlen(g_sRanks[i]) <= 0)break;
		if (iPoints >= g_iRanksPoints[i] && g_iRanksPoints[i] > g_iRanksPoints[iMaxRank])
			iMaxRank = i;
		
	}
	g_iRank[client] = iMaxRank;
	CS_SetClientClanTag(client, g_sRanks[iMaxRank]);
}

void loadRanks()
{
	char sPath[64], sPoints[32], sColor[32];
	KeyValues kv = new KeyValues("Ranks");
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/ranks.cfg");
	kv.ImportFromFile(sPath);
	
	if (!kv.GotoFirstSubKey())
	{
		delete kv;
		LogError("Config ranks didnt't load well!.");
		return;
	}
	int iKeyCounter = 0;
	do
	{
		kv.GetSectionName(g_sRanks[iKeyCounter], 256);
		g_sRanks[iKeyCounter][0] = CharToUpper(g_sRanks[iKeyCounter][0]);
		kv.GetString("Points", sPoints, sizeof(sPoints));
		g_iRanksPoints[iKeyCounter] = StringToInt(sPoints);
		kv.GetString("Color", sColor, sizeof(sColor));
		// Color to Code
		for (int i = 0; i < sizeof(g_sColorsNames); i++)
		{
			if (!StrEqual(sColor, g_sColorsNames[i], false))continue;
			strcopy(g_sRanksColors[iKeyCounter], 32, g_sColorsCodes[i]);
			break;
		}
		
		iKeyCounter++;
	}
	while (kv.GotoNextKey());
	delete kv;
	
}


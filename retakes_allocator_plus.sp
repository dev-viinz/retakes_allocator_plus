#include <sourcemod>
#include <cstrike>
#include <clientprefs>
#include "include/retakes.inc"
#include "retakes/generic.sp"

#pragma semicolon 1
#pragma newdecls required

#define MENU_TIME_LENGTH 15

char g_CTRifleChoice[MAXPLAYERS+1][WEAPON_STRING_LENGTH];
char g_CTPistolChoice[MAXPLAYERS+1][WEAPON_STRING_LENGTH];
char g_TRifleChoice[MAXPLAYERS+1][WEAPON_STRING_LENGTH];
char g_TPistolChoice[MAXPLAYERS+1][WEAPON_STRING_LENGTH];
bool g_AwpChoice[MAXPLAYERS+1];
Handle g_hCTRifleChoiceCookie;
Handle g_hCTPistolChoiceCookie;
Handle g_hTRifleChoiceCookie;
Handle g_hTPistolChoiceCookie;
Handle g_hAwpChoiceCookie;

char g_TPistolChoices[][][] = {
	// Default pistols:
	{ "weapon_glock", "Glock" },
	// Upgraded pistols:
	{ "weapon_p250", "P250" },
	{ "weapon_tec9", "Tec-9" },
	{ "weapon_deagle", "Deagle" },
	// Random pistol, must be last entry in the array, might implement it at some point
	// { "", "Random" },
};

char g_CTPistolChoices[][][] = {
	// Default pistols:
	{ "weapon_usp_silencer", "USP" },
	{ "weapon_hkp2000", "P2000" },
	// Upgraded pistols:
	{ "weapon_p250", "P250" },
	{ "weapon_fiveseven", "Five-Seven" },
	{ "weapon_deagle", "Deagle" },
	// Random pistol, must be last entry in the array, might implement it at some point
	// { "", "Random" },
};

public Plugin myinfo = {
	name = "CS:GO Retakes: weapon allocator plus",
	author = "splewis and viinz",
	description = "Defines a custom weapon allocation policy and lets players set weapon preferences",
	version = PLUGIN_VERSION,
	url = "https://github.com/dev-viinz/retakes_allocator_plus"
};

public void OnPluginStart() {
	g_hCTRifleChoiceCookie = RegClientCookie("retakes_ctriflechoice", "", CookieAccess_Private);
	g_hCTPistolChoiceCookie = RegClientCookie("retakes_ctpistolchoice", "", CookieAccess_Private);
	g_hTRifleChoiceCookie = RegClientCookie("retakes_triflechoice", "", CookieAccess_Private);
	g_hTPistolChoiceCookie = RegClientCookie("retakes_tpistolchoice", "", CookieAccess_Private);
	g_hAwpChoiceCookie = RegClientCookie("retakes_awpchoice", "", CookieAccess_Private);
}

public void OnClientConnected(int client) {
	g_CTRifleChoice[client] = "m4a1";
	g_CTPistolChoice[client] = "weapon_usp_silencer";
	g_TRifleChoice[client] = "ak47";
	g_TPistolChoice[client] = "weapon_glock";
	g_AwpChoice[client] = false;
}

public void Retakes_OnGunsCommand(int client) {
	GiveWeaponsMenu(client);
}

public void Retakes_OnWeaponsAllocated(ArrayList tPlayers, ArrayList ctPlayers, Bombsite bombsite) {
	WeaponAllocator(tPlayers, ctPlayers, bombsite);
}

/**
 * Updates client weapon settings according to their cookies.
 */
public void OnClientCookiesCached(int client) {
	if (IsFakeClient(client))
		return;
	char ctrifle[WEAPON_STRING_LENGTH];
	char ctpistol[WEAPON_STRING_LENGTH];
	char trifle[WEAPON_STRING_LENGTH];
	char tpistol[WEAPON_STRING_LENGTH];
	GetClientCookie(client, g_hCTRifleChoiceCookie, ctrifle, sizeof(ctrifle));
	GetClientCookie(client, g_hCTPistolChoiceCookie, ctpistol, sizeof(ctpistol));
	GetClientCookie(client, g_hTRifleChoiceCookie, trifle, sizeof(trifle));
	GetClientCookie(client, g_hTPistolChoiceCookie, tpistol, sizeof(tpistol));
	g_CTRifleChoice[client] = ctrifle;
	g_CTPistolChoice[client] = ctpistol;
	g_TRifleChoice[client] = trifle;
	g_TPistolChoice[client] = tpistol;
	g_AwpChoice[client] = GetCookieBool(client, g_hAwpChoiceCookie);
}

static void SetNades(char nades[NADE_STRING_LENGTH]) {
	int rand = GetRandomInt(0, 3);
	switch(rand) {
		case 0: nades = "";
		case 1: nades = "s";
		case 2: nades = "f";
		case 3: nades = "h";
	}
}

static bool TryForAwp() {
	int rand = GetRandomInt(0, 4);
	if (rand == 4) {
		return true;
	}
	return false;
}

static bool IsPistolRound() {
	int ctscore = GetTeamScore(3);
	int tscore = GetTeamScore(2);
	int score = ctscore + tscore;
	if ((score % 5) == 0) {
		return true;
	}
	return false;
}

public void WeaponAllocator(ArrayList tPlayers, ArrayList ctPlayers, Bombsite bombsite) {
	int tCount = tPlayers.Length;
	int ctCount = ctPlayers.Length;

	char primary[WEAPON_STRING_LENGTH];
	char secondary[WEAPON_STRING_LENGTH];
	char nades[NADE_STRING_LENGTH];
	int health = 100;
	int kevlar = 100;
	bool helmet = true;
	bool kit = true;

	bool giveTAwp = true;
	bool giveCTAwp = true;

	bool pistolRound = false;
	if (IsPistolRound()) {
		pistolRound = true;
	}

	for (int i = 0; i < tCount; i++) {
		int client = tPlayers.Get(i);

		if (pistolRound) {
			helmet = false;
		} else {
			if (giveTAwp && g_AwpChoice[client] && TryForAwp()) {
				primary = "weapon_awp";
				giveTAwp = false;
			} else if(StrEqual(g_TRifleChoice[client], "sg556", true)) {
				primary = "weapon_sg556";
			} else {
				primary = "weapon_ak47";
			}
			helmet = true;
		}


		secondary = g_TPistolChoice[client];
		health = 100;
		kevlar = 100;
		kit = false;
		SetNades(nades);

		Retakes_SetPlayerInfo(client, primary, secondary, nades, health, kevlar, helmet, kit);
	}

	for (int i = 0; i < ctCount; i++) {
		int client = ctPlayers.Get(i);

		if (pistolRound) {
			helmet = false;
		} else {
			if (giveCTAwp && g_AwpChoice[client] && TryForAwp()) {
				primary = "weapon_awp";
				giveCTAwp = false;
			} else if (StrEqual(g_CTRifleChoice[client], "m4a1_silencer", true)) {
				primary = "weapon_m4a1_silencer";
			} else if (StrEqual(g_CTRifleChoice[client], "m4a1", true)) {
				primary = "weapon_m4a1";
			} else {
				primary = "weapon_aug";
			}
			helmet = true;
		}

		secondary = g_CTPistolChoice[client];
		kit = true;
		health = 100;
		kevlar = 100;
		SetNades(nades);

		Retakes_SetPlayerInfo(client, primary, secondary, nades, health, kevlar, helmet, kit);
	}
	
	if (IsPistolRound()) {
		Retakes_MessageToAll("%s", "Pistol round!");
	}
}

public void GiveWeaponsMenu(int client) {
	Menu menu = new Menu(MenuHandler_CTRifle);
	menu.SetTitle("Select a CT rifle:");
	menu.AddItem("m4a1", "M4A4");
	menu.AddItem("m4a1_silencer", "M4A1-S");
	menu.AddItem("aug", "AUG");
	menu.Display(client, MENU_TIME_LENGTH);
}

public int MenuHandler_CTRifle(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		int client = param1;
		char choice[WEAPON_STRING_LENGTH];
		menu.GetItem(param2, choice, sizeof(choice));
		g_CTRifleChoice[client] = choice;
		SetClientCookie(client, g_hCTRifleChoiceCookie, choice);
		CTPistolMenu(client);
	} else if (action == MenuAction_End) {
		delete menu;
	}
}

public void CTPistolMenu(int client) {
	Menu menu = new Menu(MenuHandler_CTPistol);
	menu.SetTitle("Select a CT pistol:");
	for (int i = 0; i < sizeof(g_CTPistolChoices); i++) {
		menu.AddItem(g_CTPistolChoices[i][0], g_CTPistolChoices[i][1]);
	}
	menu.Display(client, MENU_TIME_LENGTH);
}

public int MenuHandler_CTPistol(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		int client = param1;
		char choice[WEAPON_STRING_LENGTH];
		menu.GetItem(param2, choice, sizeof(choice));
		g_CTPistolChoice[client] = choice;
		SetClientCookie(client, g_hCTPistolChoiceCookie, choice);
		TRifleMenu(client);
	} else if (action == MenuAction_End) {
		delete menu;
	}
}

public void TRifleMenu(int client) {
	Menu menu = new Menu(MenuHandler_TRifle);
	menu.SetTitle("Select a T rifle:");
	menu.AddItem("ak47", "AK-47");
	menu.AddItem("sg556", "SG-556");
	menu.Display(client, MENU_TIME_LENGTH);
}

public int MenuHandler_TRifle(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		int client = param1;
		char choice[WEAPON_STRING_LENGTH];
		menu.GetItem(param2, choice, sizeof(choice));
		g_TRifleChoice[client] = choice;
		SetClientCookie(client, g_hTRifleChoiceCookie, choice);
		TPistolMenu(client);
	} else if (action == MenuAction_End) {
		delete menu;
	}
}

public void TPistolMenu(int client) {
	Menu menu = new Menu(MenuHandler_TPistol);
	menu.SetTitle("Select a T pistol:");
	for (int i = 0; i < sizeof(g_TPistolChoices); i++) {
		menu.AddItem(g_TPistolChoices[i][0], g_TPistolChoices[i][1]);
	}
	menu.Display(client, MENU_TIME_LENGTH);
}

public int MenuHandler_TPistol(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		int client = param1;
		char choice[WEAPON_STRING_LENGTH];
		menu.GetItem(param2, choice, sizeof(choice));
		g_TPistolChoice[client] = choice;
		SetClientCookie(client, g_hTPistolChoiceCookie, choice);
		GiveAwpMenu(client);
	} else if (action == MenuAction_End) {
		delete menu;
	}
}

public void GiveAwpMenu(int client) {
	Menu menu = new Menu(MenuHandler_AWP);
	menu.SetTitle("Allow yourself to receive AWPs?");
	AddMenuBool(menu, true, "Yes");
	AddMenuBool(menu, false, "No");
	menu.Display(client, MENU_TIME_LENGTH);
}

public int MenuHandler_AWP(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		int client = param1;
		bool allowAwps = GetMenuBool(menu, param2);
		g_AwpChoice[client] = allowAwps;
		SetCookieBool(client, g_hAwpChoiceCookie, allowAwps);
	} else if (action == MenuAction_End) {
		delete menu;
	}
}

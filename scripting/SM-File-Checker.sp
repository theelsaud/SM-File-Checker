#include <sourcemod>
#pragma newdecls required
#pragma semicolon 1

#define CONFIG_PATH "configs/file_checker.ini"

public Plugin myinfo =
{
	name = "SM-File-Checker",
	author = "FIVE & Domikuss",
	description = "When updating a file, the command is executed",
	version = "1.0.0",
	url = "https://github.com/theelsaud/SM-File-Checker"
};

enum struct FileInfo
{
	char sPath[PLATFORM_MAX_PATH];
	char sCommand[256];

	int iLastTimeUpdate;
}
ArrayList g_hFiles;

Handle g_hTimer;

public void OnPluginStart()
{
	LoadConfig();
	RegServerCmd("sm_fc_update", cmd_UpdateConfig);
}

Action cmd_UpdateConfig(int iArgs)
{
	LoadConfig();
	PrintToServer("[SM File Checker] Config reloaded.");

	return Plugin_Handled;
}

void LoadConfig()
{
	if(g_hFiles) delete g_hFiles;
	g_hFiles = new ArrayList(sizeof(FileInfo));

	KeyValues hConfig;
	char sPath[PLATFORM_MAX_PATH], szBuffer[256];

	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, CONFIG_PATH);
	hConfig = new KeyValues("FileChecker");

	if(!hConfig.ImportFromFile(sPath))
	{
		FormatEx(szBuffer, sizeof(szBuffer), "[CONFIG] NOT FOUND (%s)", sPath);
		SetFailState(szBuffer);
	}
	hConfig.Rewind();

	float fTimeUpdate = hConfig.GetFloat("time", 1.0);

	if(hConfig.JumpToKey("files"))
	{
		if (hConfig.GotoFirstSubKey(false))
		{
			do
			{
				FileInfo hCurrentFile;
				hConfig.GetSectionName(hCurrentFile.sPath, sizeof(hCurrentFile.sPath));
				hConfig.GetString(NULL_STRING, hCurrentFile.sCommand, sizeof(hCurrentFile.sCommand));

				g_hFiles.PushArray(hCurrentFile, sizeof(hCurrentFile));
			}
			while (hConfig.GotoNextKey(false));
		}
	}

	if(g_hTimer)
	{
		KillTimer(g_hTimer);
	}
	g_hTimer = CreateTimer(fTimeUpdate, FileChecker, _, TIMER_REPEAT);

	delete hConfig;
}

Action FileChecker(Handle hTimer)
{
	for(int i = 0; i < g_hFiles.Length; i++)
	{
		FileInfo hCurrentFile;
		g_hFiles.GetArray(i, hCurrentFile, sizeof(hCurrentFile));

		if(FileExists(hCurrentFile.sPath))
		{
			int iTime = GetFileTime(hCurrentFile.sPath, FileTime_LastChange);
			if(iTime != hCurrentFile.iLastTimeUpdate)
			{
				g_hFiles.Set(i, iTime, FileInfo::iLastTimeUpdate);

				if(hCurrentFile.iLastTimeUpdate != 0) 
				{
					PrintToServer("[SM File Checker] File [ %s ] updated. Running command...", hCurrentFile.sPath);
					ServerCommand(hCurrentFile.sCommand);
				}
			}
		}
	}

	return Plugin_Continue;
}
/*
Copyright (c) 2016 Drake "MrOats" Denston

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

/*
Current Status: Stable.
Thank you to all those who have assisted me with this plugin!
*/


//Globals

array<bool> bSpectatePlease(8, false);
const float MAX_FLOAT = Math.FLOAT_MAX;
CClientCommand spectate("spectate", "Toggles Player's spectate state", @toggleSpectate );
//CClientCommand respawn("respawn", "Debug Command", @RespawnMe );

//Config

bool adminOnly = false;

//Plugin Initialization Functions

void PluginInit()
{

  g_Module.ScriptInfo.SetAuthor("MrOats");
  g_Module.ScriptInfo.SetContactInfo("http://forums.svencoop.com/showthread.php/44306-Plugin-SpectateMode");
  g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect,@RemoveSpecStatus);
  g_Hooks.RegisterHook(Hooks::Player::PlayerSpawn,@CheckSpectate);
  g_Hooks.RegisterHook(Hooks::Player::ClientSay, @Decider);
  //g_Hooks.RegisterHook(Hooks::Player::PlayerCanRespawn,@PreventRespawn); //<-- See function for notes

  /*Just in case as_reloadplugins is called
  bSpectatePlease.resize(g_Engine.maxClients);
  for (uint i = 0; i < bSpectatePlease.length(); i++)
  {

    bSpectatePlease[i] = false;

  }

  if(g_pSetRespawn !is null)
    g_Scheduler.RemoveTimer(g_pSetRespawn);

  @g_pSetRespawn = g_Scheduler.SetInterval("SetRespawnTime", .5f, g_Scheduler.REPEAT_INFINITE_TIMES);
  */
}

void MapActivate()
{

  bSpectatePlease.resize(g_Engine.maxClients);
  for (uint i = 0; i < bSpectatePlease.length(); i++)
  {
    bSpectatePlease[i] = false;
  }


}

//Hooks

HookReturnCode Decider(SayParameters@ pParams)
{

  CBasePlayer@ pPlayer = pParams.GetPlayer();
  const CCommand@ pArguments = pParams.GetArguments();

  if (pArguments[0] == "!spectate")
  {

    toggleSpectate(@pArguments, @pPlayer);
    return HOOK_HANDLED;

  }
  else if (pArguments[0] == "/spectate")
  {

    pParams.set_ShouldHide(true);
    toggleSpectate(@pArguments, @pPlayer);
    return HOOK_HANDLED;

  }
  else return HOOK_CONTINUE;

}

HookReturnCode RemoveSpecStatus(CBasePlayer@ pPlayer)
{

  ExitSpectate(pPlayer);
  return HOOK_HANDLED;

}

/*

HookReturnCode PreventRespawn(CBasePlayer@ pPlayer, bool& out bCanRespawn)
{

//Having issues with below code as it still attempts to respawn player,
//See https://github.com/baso88/SC_AngelScript/issues/49
  MessageWarnPlayer(pPlayer, "PreventRespawn has a heartbeat!");

  if (bSpectatePlease[pPlayer.entindex() - 1])
  {

    bCanRespawn = false;
    MessageWarnPlayer(pPlayer, "Your respawn is turned off?");
    pPlayer.GetObserver().StartObserver( pPlayer.pev.origin, pPlayer.pev.angles, false );
    g_Scheduler.SetTimeout("SetRespawnTime", .75f, @pPlayer);
    return HOOK_HANDLED;

  }
  else
  {

    bCanRespawn = true;
    return HOOK_HANDLED;

  }

}

*/

HookReturnCode CheckSpectate(CBasePlayer@ pPlayer)
{

  if (bSpectatePlease[pPlayer.entindex() - 1])
  {

    pPlayer.GetObserver().StartObserver( pPlayer.pev.origin, pPlayer.pev.angles, false );
    g_Scheduler.SetTimeout("SetRespawnTime", .75f, @pPlayer);
    return HOOK_HANDLED;

  }
  else
    return HOOK_HANDLED;

}

//Main Functions

void toggleSpectate(const CCommand@ pArguments, CBasePlayer@ pPlayer)
{

  if ( (g_PlayerFuncs.AdminLevel(pPlayer) >= ADMIN_YES) && (pArguments.ArgC() > 1) )
  {

    //Let admin search for player and put them in or out of Spectate Mode.
    CBasePlayer@ pTarget = GetTargetPlayer(pArguments.Arg(1));

    if (pTarget is null)
      MessageWarnPlayer(pPlayer, "The player you entered was not found.");
    else
    {

      if (bSpectatePlease[pTarget.entindex() - 1])
      {

        MessageWarnPlayer(pPlayer, "Moving " + pTarget.pev.netname + " out of Spectate Mode.");
        ExitSpectate(pTarget);

      }
      else
      {

        MessageWarnPlayer(pPlayer, "Moving " + pTarget.pev.netname + " into Spectate Mode.");
        EnterSpectate(pTarget);

      }

    }

  }
  else
  {

    if (bSpectatePlease[pPlayer.entindex() - 1])
      ExitSpectate(pPlayer);
    else
      EnterSpectate(pPlayer);

  }

}

void toggleSpectate(const CCommand@ pArguments)
{

  CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

  if ( (g_PlayerFuncs.AdminLevel(pPlayer) >= ADMIN_YES) && (pArguments.ArgC() > 1) )
  {

    //Let admin search for player and put them in or out of Spectate Mode.
    CBasePlayer@ pTarget = GetTargetPlayer(pArguments.Arg(1));

    if (pTarget is null)
      MessageWarnPlayer(pPlayer, "The player you entered was not found.");
    else
    {

      if (bSpectatePlease[pTarget.entindex() - 1])
      {

        MessageWarnPlayer(pPlayer, "Moving " + pTarget.pev.netname + " out of Spectate Mode.");
        ExitSpectate(pTarget);

      }
      else
      {

        MessageWarnPlayer(pPlayer, "Moving " + pTarget.pev.netname + " into Spectate Mode.");
        EnterSpectate(pTarget);

      }

    }

  }
  else
  {

    if (bSpectatePlease[pPlayer.entindex() - 1])
      ExitSpectate(pPlayer);
    else
      EnterSpectate(pPlayer);

  }

}

CBasePlayer@ GetPlayerBySteamId(const string& in szTargetSteamId)
{

	CBasePlayer@ pTarget;

	for (int iIndex = 1; iIndex <= g_Engine.maxClients; ++iIndex)
	{

		@pTarget = g_PlayerFuncs.FindPlayerByIndex(iIndex);

		if( pTarget !is null )
		{

			const string szSteamId = g_EngineFuncs.GetPlayerAuthId(pTarget.edict());

			if(szSteamId == szTargetSteamId)
				return pTarget;

		}

	}

	return null;

}

CBasePlayer@ GetTargetPlayer(const string& in szNameOrSteamId)
{

	CBasePlayer@ pTarget = g_PlayerFuncs.FindPlayerByName(szNameOrSteamId, false);

	if(pTarget !is null)
		return pTarget;

	return GetPlayerBySteamId(szNameOrSteamId);
}

void SetRespawnTime(CBasePlayer@ pPlayer)
{

  pPlayer.m_flRespawnDelayTime = MAX_FLOAT;
  return;

}

void EnterSpectate(CBasePlayer@ pPlayer)
{

  if (adminOnly && (g_PlayerFuncs.AdminLevel(pPlayer) >= ADMIN_YES) )
    bSpectatePlease[pPlayer.entindex() - 1] = true;
  else if (!adminOnly)
    bSpectatePlease[pPlayer.entindex() - 1] = true;

  if( (!pPlayer.GetObserver().IsObserver()) && (bSpectatePlease[pPlayer.entindex() -1]) )
  {

    MessageWarnPlayer(pPlayer, "Entering Spectate Mode");
    pPlayer.GetObserver().StartObserver( pPlayer.pev.origin, pPlayer.pev.angles, false );
    g_Scheduler.SetTimeout("SetRespawnTime", .75f, @pPlayer);

  }

}

void ExitSpectate(CBasePlayer@ pPlayer)
{

  MessageWarnPlayer(pPlayer, "Exiting Spectate Mode");
  bSpectatePlease[pPlayer.entindex() - 1] = false;

  //Reset the player's respawn time by respawning and killing.
  g_PlayerFuncs.RespawnPlayer(pPlayer, true, true);
  g_AdminControl.KillPlayer(pPlayer, 0); /* Is 0 because we don't want to add more time to mp_respawndelay */
  pPlayer.m_iDeaths -= 1;

}

void MessageWarnPlayer(CBasePlayer@ pPlayer, string msg)
{

  g_PlayerFuncs.SayText( pPlayer, "[SM] " + msg + "\n");

}

void MessageWarnAllPlayers(CBasePlayer@ pPlayer, string msg)
{

  g_PlayerFuncs.SayTextAll( pPlayer, "[SM] " + msg + "\n");

}


void RespawnMe(const CCommand@ pArguments)
{

  CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
  g_PlayerFuncs.RespawnPlayer(pPlayer, true, true);

}

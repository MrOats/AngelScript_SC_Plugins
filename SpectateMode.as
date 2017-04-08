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

CScheduledFunction@ g_pSetRespawn = null;
array<bool> bSpectatePlease(8, false);
const float MAX_FLOAT = Math.FLOAT_MAX;
CClientCommand spectate("spectate", "Toggles Player's spectate state", @toggleSpectate );

//Config

bool adminOnly = false;

//Main Functions

void PluginInit()
{

  g_Module.ScriptInfo.SetAuthor("MrOats");
  g_Module.ScriptInfo.SetContactInfo("http://forums.svencoop.com/showthread.php/44306-Plugin-SpectateMode");
  g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect,@RemoveSpecStatus);
  g_Hooks.RegisterHook(Hooks::Game::MapChange,@EndTimerFuncs);
  g_Hooks.RegisterHook(Hooks::Player::PlayerSpawn,@CheckSpectate);
  /* g_Hooks.RegisterHook(Hooks::Player::PlayerCanRespawn,@PreventRespawn); <-- See function for notes */

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

  if(g_pSetRespawn !is null)
    g_Scheduler.RemoveTimer(g_pSetRespawn);

  @g_pSetRespawn = g_Scheduler.SetInterval("SetRespawnTime", .5f, g_Scheduler.REPEAT_INFINITE_TIMES);

}

void toggleSpectate(const CCommand@ pArguments)
{

  CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

  if (bSpectatePlease[pPlayer.entindex() - 1])
    ExitSpectate(pPlayer);
  else EnterSpectate(pPlayer);

}

void SetRespawnTime()
{

/*
The reason why we are still using a Scheduler that
runs constantly at a <1 second interval is because
the game isn't setting the player's respawn timer when
I try setting it once. Tried using a PlayerSpawn hook and
a PlayerKilled hook to set it at those times, even when I put
the player to Observer Mode.

This "hack" will remain until a proper "run-once" solution is set on a
per-player basis.
*/


  for (int i = 1; i <= g_Engine.maxClients; i++)
  {

    CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);

    if ((pPlayer !is null) && (bSpectatePlease[pPlayer.entindex() - 1]))
      pPlayer.m_flRespawnDelayTime = MAX_FLOAT;

  }

}

void EnterSpectate(CBasePlayer@ pPlayer)
{

  if (adminOnly && (g_PlayerFuncs.AdminLevel(pPlayer) >= ADMIN_YES) )
    bSpectatePlease[pPlayer.entindex() - 1] = true;
  else if (!adminOnly)
    bSpectatePlease[pPlayer.entindex() - 1] = true;

  if(!pPlayer.GetObserver().IsObserver())
  pPlayer.GetObserver().StartObserver( pPlayer.pev.origin, pPlayer.pev.angles, false );

}

void ExitSpectate(CBasePlayer@ pPlayer)
{

  //g_Game.AlertMessage(at_console, "Exiting SpectateMode\n");
  bSpectatePlease[pPlayer.entindex() - 1] = false;

  //Reset the player's respawn time by respawning and killing.
  g_PlayerFuncs.RespawnPlayer(pPlayer, true, true);
  g_AdminControl.KillPlayer(pPlayer, 3);

}

HookReturnCode RemoveSpecStatus(CBasePlayer@ pPlayer)
{

  ExitSpectate(pPlayer);
  return HOOK_HANDLED;

}

/*


HookReturnCode PreventRespawn(CBasePlayer@ pPlayer, bool& out bCanRespawn)
{
Having issues with below code as it still attempts to respawn player,
See https://github.com/baso88/SC_AngelScript/issues/49

  if (bSpectatePlease[pPlayer.entindex() - 1])
  {

    bCanRespawn = false;
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
    return HOOK_HANDLED;

  }
  else
    return HOOK_HANDLED;

}

HookReturnCode EndTimerFuncs()
{

  g_Scheduler.ClearTimerList();
  @g_pSetRespawn = null;
  
  return HOOK_HANDLED;

}

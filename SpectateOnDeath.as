/*
Copyright (c) 2017 Drake "MrOats" Denston

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

/*
Current Status: Unstable/Under Development, report bugs on forums.
Documentation: https://github.com/MrOats/AngelScript_SC_Plugins/wiki/RockTheVote.as
*/

void PluginInit()
{

  g_Module.ScriptInfo.SetAuthor("MrOats");
  g_Module.ScriptInfo.SetContactInfo("N/A");
  g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @DelaySpawn);
  g_Hooks.RegisterHook(Hooks::Player::PlayerKilled, @PutToObserver);
  //g_Hooks.RegisterHook(Hooks::Player::PlayerCanRespawn,@MakeRespawn);

}

HookReturnCode DelaySpawn(CBasePlayer@ pPlayer)
{

  //Kill joined player to make them wait until respawn time is over
  //to prevent them from rejoining to override respawn time

  //g_Scheduler.SetTimeout("KillSpawn", 1, @pPlayer);
  pPlayer.GetObserver().StartObserver( pPlayer.pev.origin, pPlayer.pev.angles, false );

  return HOOK_HANDLED;

}

HookReturnCode PutToObserver(CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib)
{

  g_Scheduler.SetTimeout("ObsFunc", 1, @pPlayer)
  return HOOK_HANDLED;

}

/*
HookReturnCode MakeRespawn(CBasePlayer@ pPlayer, bool& out bCanRespawn)
{

  bCanRespawn = true;
  return HOOK_HANDLED;

}
*/

void KillSpawn(CBasePlayer@ pPlayer)
{

  pPlayer.GetObserver().StartObserver( pPlayer.pev.origin, pPlayer.pev.angles, false );

}

void ObsFunc(CBasePlayer@ pPlayer)
{

  Observer@ pPlrObs = pPlayer.GetObserver();
  pPlrObs.StartObserver( pPlayer.pev.origin, pPlayer.pev.angles, true );
  pPlrObs.SetObserverModeControlEnabled(true);
  pPlrObs.SetMode(OBS_ROAMING);
  pPlayer.ShowForcedRespawnMessage(int(g_EngineFuncs.CVarGetFloat("mp_respawndelay"));

}

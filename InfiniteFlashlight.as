/*
Copyright (c) 2017 Drake "MrOats" Denston

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

/*
Current Status: Stable.
Documentation: https://github.com/MrOats/AngelScript_SC_Plugins/wiki/InfiniteFlashlight.as
*/

// Globals
CScheduledFunction@ g_TimeUntilMax = null;

CCVar@ g_InfiniteFlashLight;

void PluginInit()
{

  g_Module.ScriptInfo.SetAuthor("MrOats");
  g_Module.ScriptInfo.SetContactInfo("https://forums.svencoop.com/showthread.php/44687-Plugin-Infinite-Flashlight");
  g_Hooks.RegisterHook(Hooks::Game::MapChange,@ResetCVars);

  @g_InfiniteFlashLight = CCVar("infiniteFlashlightEnable", true, "Whether or not this plugin should run", ConCommandFlag::AdminOnly);

}

void MapActivate()
{

  g_Scheduler.ClearTimerList();
  @g_TimeUntilMax = null;

  if (g_InfiniteFlashLight.GetBool())
    @g_TimeUntilMax = g_Scheduler.SetInterval("SetFlashlightsToMax",5.0f,g_Scheduler.REPEAT_INFINITE_TIMES);
  else
    g_Game.AlertMessage(at_logged, "Infinite Flash Light disabled.\n");

}

void SetFlashlightsToMax()
{

  for (int i = 1; i <= g_Engine.maxClients; i++)
  {

    CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
    if ( (pPlayer !is null) && (pPlayer.IsAlive()) )
      pPlayer.m_iFlashBattery = 100;

  }

}

HookReturnCode ResetCVars()
{

  g_Scheduler.ClearTimerList();
  @g_TimeUntilMax = null;

  return HOOK_HANDLED;

}

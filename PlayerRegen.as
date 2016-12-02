/*
Copyright (c) 2016 Drake "MrOats" Denston

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

/*
Current Status: Stable. New Features to be added.
Documentation: https://github.com/MrOats/AngelScript_SC_Plugins/wiki/PlayerRegen.as
*/
CScheduledFunction@ g_APRegenTimer=null;
CScheduledFunction@ g_HPRegenTimer=null;

const int g_MAXPLAYERS=g_Engine.maxClients;

CCVar@ g_HPRegen;
CCVar@ g_HP_Regen_Amnt;
CCVar@ g_HP_Regen_Delay;
CCVar@ g_HP_Regen_Max;
CCVar@ g_APRegen;
CCVar@ g_AP_Regen_Amnt;
CCVar@ g_AP_Regen_Delay;
CCVar@ g_AP_Regen_Max;
//Config

//End Config

void PluginInit()
{

  g_Module.ScriptInfo.SetAuthor("MrOats");
  g_Module.ScriptInfo.SetContactInfo("http://forums.svencoop.com/showthread.php/44242-Plugin-Player-Regen-(HP-and-AP-Regen)");

  g_Hooks.RegisterHook(Hooks::Game::MapChange,@EndTimerFuncs);
  g_Hooks.RegisterHook(Hooks::Player::PlayerSpawn,@SetMax);

  @g_HPRegen=CCVar("hpregen", true, "Enable or Disable HP Regen",  ConCommandFlag::AdminOnly);
  @g_HP_Regen_Amnt=CCVar("hpamnt", 1, "How much HP to regen per delay",  ConCommandFlag::AdminOnly);
  @g_HP_Regen_Delay=CCVar("hpdelay", 3.0f, "Delay before giving HP again",  ConCommandFlag::AdminOnly);
  @g_HP_Regen_Max=CCVar("hpmax", 100, "Max amount of health player should have",  ConCommandFlag::AdminOnly);
  @g_APRegen=CCVar("apregen", true, "Enable or Disable AP Regen",  ConCommandFlag::AdminOnly);
  @g_AP_Regen_Amnt=CCVar("apamnt", 1, "How much AP to regen per delay",  ConCommandFlag::AdminOnly);
  @g_AP_Regen_Delay=CCVar("apdelay", 3.0f, "Delay before giving AP again",  ConCommandFlag::AdminOnly);
  @g_AP_Regen_Max=CCVar("apmax", 100, "Max amount of armor player should have",  ConCommandFlag::AdminOnly);
}

void MapInit()
{

  if(g_HPRegenTimer.GetBool() !is null)
    g_Scheduler.RemoveTimer(g_HPRegenTimer);
  if(g_APRegenTimer.GetBool() !is null)
		g_Scheduler.RemoveTimer(g_APRegenTimer);

  if (HPRegen)
    @pHPRegenTimer = g_Scheduler.SetInterval("GiveHP",g_HP_Regen_Delay.GetFloat(),g_Scheduler.REPEAT_INFINITE_TIMES);
  if (APRegen)
    @pAPRegenTimer = g_Scheduler.SetInterval("GiveAP",g_AP_Regen_Delay.GetFloat(),g_Scheduler.REPEAT_INFINITE_TIMES);

}

//Main Functions
HookReturnCode SetMax(CBasePlayer@ pPlayer)
{

  pPlayer.pev.max_health=g_HP_Regen_Max.GetInt();
  pPlayer.pev.armortype=g_AP_Regen_Max.GetInt();
  return HOOK_HANDLED;
}

void GiveAP()
{

  for (int i = 1; i <= g_MAXPLAYERS; i++)
  {
    CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
    if ((pPlayer !is null) && (pPlayer.IsConnected()) && (pPlayer.IsAlive()))
      pPlayer.pev.armorvalue+=g_AP_Regen_Amnt.GetInt();
  }

}

void GiveHP()
{
  for (int i = 1; i <= g_MAXPLAYERS; i++)
  {
    CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
    if ((pPlayer !is null) && (pPlayer.IsConnected()) && (pPlayer.IsAlive()))
      pPlayer.pev.health+=HP_Regen_Amnt.GetInt();
  }

}

HookReturnCode EndTimerFuncs()
{

  g_Scheduler.ClearTimerList();
  return HOOK_HANDLED;

}

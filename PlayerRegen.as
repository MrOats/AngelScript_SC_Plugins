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
CScheduledFunction@ g_APRegenTimer = null;
CScheduledFunction@ g_HPRegenTimer = null;

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

  g_Hooks.RegisterHook(Hooks::Game::MapChange,@ResetCVars);
  g_Hooks.RegisterHook(Hooks::Player::PlayerSpawn,@SetMax);

  //DO NOT CHANGE DEFAULT VALUES.
  @g_HPRegen = CCVar("hpregen",true, "Enable or Disable HP Regen", ConCommandFlag::AdminOnly,@refreshTimers);
  @g_HP_Regen_Amnt = CCVar("hpamnt",1, "How much HP to regen per delay", ConCommandFlag::AdminOnly);
  @g_HP_Regen_Delay = CCVar("hpdelay",3.0, "Delay before giving HP again", ConCommandFlag::AdminOnly,@refreshTimers);
  @g_HP_Regen_Max = CCVar("hpmax",100, "Max amount of health player should have", ConCommandFlag::AdminOnly);
  @g_APRegen = CCVar("apregen",true, "Enable or Disable AP Regen", ConCommandFlag::AdminOnly,@refreshTimers);
  @g_AP_Regen_Amnt = CCVar("apamnt",1, "How much AP to regen per delay", ConCommandFlag::AdminOnly);
  @g_AP_Regen_Delay = CCVar("apdelay",3.0, "Delay before giving AP again", ConCommandFlag::AdminOnly,@refreshTimers);
  @g_AP_Regen_Max = CCVar("apmax",100, "Max amount of armor player should have", ConCommandFlag::AdminOnly);

/* Just in case as_reloadplugin(s) is called

  if(g_HPRegenTimer !is null)
  {

    g_Scheduler.RemoveTimer(g_HPRegenTimer);
    @g_HPRegenTimer = null;

  }

  if(g_APRegenTimer !is null)
  {

    g_Scheduler.RemoveTimer(g_APRegenTimer);
    @g_APRegenTimer = null;

  }

  if (g_HPRegen.GetBool())
    @g_HPRegenTimer = g_Scheduler.SetInterval("GiveHP",g_HP_Regen_Delay.GetFloat(),g_Scheduler.REPEAT_INFINITE_TIMES);
  if (g_APRegen.GetBool())
    @g_APRegenTimer = g_Scheduler.SetInterval("GiveAP",g_AP_Regen_Delay.GetFloat(),g_Scheduler.REPEAT_INFINITE_TIMES);
*/
}


void MapActivate()
{
  g_Scheduler.ClearTimerList();
  @g_HPRegenTimer = null;
  @g_APRegenTimer = null;


  if ( g_HPRegen.GetBool() )
  {

	   @g_HPRegenTimer = g_Scheduler.SetInterval("GiveHP",g_HP_Regen_Delay.GetFloat(),g_Scheduler.REPEAT_INFINITE_TIMES);

  }

  if ( g_APRegen.GetBool() )
  {

    @g_APRegenTimer = g_Scheduler.SetInterval("GiveAP",g_AP_Regen_Delay.GetFloat(),g_Scheduler.REPEAT_INFINITE_TIMES);

  }



}

//Adjust Timers

void refreshTimers(CCVar@ cvar, const string& in szOldValue, float flOldValue)
{

  //Refresh HP Timer
  if ( !(g_HPRegen.GetBool()) )
  {

    g_Scheduler.RemoveTimer(g_HPRegenTimer);
    @g_HPRegenTimer = null;

  }
  else
  {
    g_Scheduler.RemoveTimer(g_HPRegenTimer);
    @g_HPRegenTimer = null;
    @g_HPRegenTimer = g_Scheduler.SetInterval("GiveHP",g_HP_Regen_Delay.GetFloat(),g_Scheduler.REPEAT_INFINITE_TIMES);
  }

  //Refresh AP Timer
  if ( !(g_APRegen.GetBool()) )
  {

    g_Scheduler.RemoveTimer(g_APRegenTimer);
    @g_APRegenTimer = null;

  }
  else
  {

    g_Scheduler.RemoveTimer(g_APRegenTimer);
    @g_APRegenTimer = null;
    @g_APRegenTimer = g_Scheduler.SetInterval("GiveAP",g_AP_Regen_Delay.GetFloat(),g_Scheduler.REPEAT_INFINITE_TIMES);

  }

}

void delayAP(CCVar@ cvar, const string& in szOldValue, float flOldValue)
{

  g_Scheduler.RemoveTimer(g_APRegenTimer);
  @g_APRegenTimer = null;
  @g_APRegenTimer = g_Scheduler.SetInterval("GiveAP",g_AP_Regen_Delay.GetFloat(),g_Scheduler.REPEAT_INFINITE_TIMES);
}
/*
void toggleHP(CCVar@ cvar, const string& in szOldValue, float flOldValue)
{

  if ( !(g_HPRegen.GetBool()) )
  {

    g_Scheduler.RemoveTimer(g_HPRegenTimer);
    @g_HPRegenTimer = null;

  }
  else
  {
    g_Scheduler.RemoveTimer(g_HPRegenTimer);
    @g_HPRegenTimer = null;
    @g_HPRegenTimer = g_Scheduler.SetInterval("GiveAP",g_AP_Regen_Delay.GetFloat(),g_Scheduler.REPEAT_INFINITE_TIMES);
  }
}

void toggleAP(CCVar@ cvar, const string& in szOldValue, float flOldValue)
{


  if ( !(g_APRegen.GetBool()) )
  {

    g_Scheduler.RemoveTimer(g_APRegenTimer);
    @g_APRegenTimer = null;

  }
  else
  {
    g_Scheduler.RemoveTimer(g_APRegenTimer);
    @g_APRegenTimer = null;
    @g_APRegenTimer = g_Scheduler.SetInterval("GiveAP",g_AP_Regen_Delay.GetFloat(),g_Scheduler.REPEAT_INFINITE_TIMES);
  }
}

void delayHP(CCVar@ cvar, const string& in szOldValue, float flOldValue)
{

  g_Scheduler.RemoveTimer(g_HPRegenTimer);
  @g_HPRegenTimer = null;
  @g_HPRegenTimer = g_Scheduler.SetInterval("GiveHP",g_HP_Regen_Delay.GetFloat(),g_Scheduler.REPEAT_INFINITE_TIMES);

}

void delayAP(CCVar@ cvar, const string& in szOldValue, float flOldValue)
{

  g_Scheduler.RemoveTimer(g_APRegenTimer);
  @g_APRegenTimer = null;
  @g_APRegenTimer = g_Scheduler.SetInterval("GiveAP",g_AP_Regen_Delay.GetFloat(),g_Scheduler.REPEAT_INFINITE_TIMES);
}
*/
//Main Functions
HookReturnCode SetMax(CBasePlayer@ pPlayer)
{

  pPlayer.pev.max_health = g_HP_Regen_Max.GetInt();
  pPlayer.pev.armortype = g_AP_Regen_Max.GetInt();
  return HOOK_HANDLED;

}

void GiveAP()
{

  for (int i = 1; i <= g_Engine.maxClients; i++)
  {

    CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
    if ( (pPlayer !is null) && (pPlayer.IsAlive()) )
      if ( !(pPlayer.pev.armorvalue >= g_AP_Regen_Max.GetInt()) )
        pPlayer.pev.armorvalue += g_AP_Regen_Amnt.GetInt();

  }

}

void GiveHP()
{

  for (int i = 1; i <= g_Engine.maxClients; i++)
  {

    CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
    if ( (pPlayer !is null) && (pPlayer.IsAlive()) )
      if ( !(pPlayer.pev.health >= g_HP_Regen_Max.GetInt()) )
        pPlayer.pev.health += g_HP_Regen_Amnt.GetInt();

  }

}

HookReturnCode ResetCVars()
{

  g_Scheduler.ClearTimerList();
  @g_HPRegenTimer = null;
  @g_APRegenTimer = null;

  g_HPRegen.SetBool(true);
  g_HP_Regen_Amnt.SetInt(1);
  g_HP_Regen_Delay.SetFloat(3.0);
  g_HP_Regen_Max.SetInt(100);
  g_APRegen.SetBool(true);
  g_AP_Regen_Amnt.SetInt(1);
  g_AP_Regen_Delay.SetFloat(3.0);
  g_AP_Regen_Max.SetInt(100);

  return HOOK_HANDLED;

}

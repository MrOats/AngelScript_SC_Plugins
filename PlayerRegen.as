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
CScheduledFunction@ pAPRegenTimer = null;
CScheduledFunction@ pHPRegenTimer = null;
//Config
bool HPRegen=true;
bool APRegen=true;

int HP_Regen_Amnt=1;
int HP_Regen_Delay=3;
int AP_Regen_Amnt=1;
int AP_Regen_Delay=3;
//End Config
void PluginInit(){
  //For use in Sven Coop, place inside 'scripts/plugins'.
  g_Module.ScriptInfo.SetAuthor("MrOats");
  g_Module.ScriptInfo.SetContactInfo("www.modriot.com");


if (HPRegen){
  @pHPRegenTimer = g_Scheduler.SetInterval("GiveHP",HP_Regen_Delay,g_Scheduler.REPEAT_INFINITE_TIMES);
}
if (APRegen){
  @pAPRegenTimer = g_Scheduler.SetInterval("GiveAP",AP_Regen_Delay,g_Scheduler.REPEAT_INFINITE_TIMES);
}
}
//Main Functions
void GiveAP(){
  for (int i = 1; i <= g_Engine.maxClients; i++) {
    CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
    if ((pPlayer !is null) && (pPlayer.IsConnected()) && (pPlayer.IsAlive())){
      pPlayer.pev.armorvalue+=AP_Regen_Amnt;
    }
  }
}
void GiveHP(){
  for (int i = 1; i <= g_Engine.maxClients; i++) {
    CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
    if ((pPlayer !is null) && (pPlayer.IsConnected()) && (pPlayer.IsAlive())){
      pPlayer.pev.health+=HP_Regen_Amnt;
    }
  }
}

CScheduledFunction@ g_pKeepSpec=null;
void PluginInit(){
  g_Module.ScriptInfo.SetAuthor("MrOats");
  g_Module.ScriptInfo.SetContactInfo("www.modriot.com");

  @g_pKeepSpec = g_Scheduler.SetInterval("SetRespawnTime",g_Engine.frametime,g_Scheduler.REPEAT_INFINITE_TIMES);
}
void SetRespawnTime(){
  for (int i = 1; i <= g_Engine.maxClients; i++) {
    CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
    if(pPlayer !is null){
      pPlayer.m_flRespawnDelayTime=999;
}
}

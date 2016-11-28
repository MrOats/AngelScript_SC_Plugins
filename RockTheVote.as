/*
Copyright (c) 2016 Drake "MrOats" Denston

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

/*
Current Status: In Development, will not work at the moment.
Documentation: https://github.com/MrOats/AngelScript_SC_Plugins/wiki/ChatTriggers.as
*/
//ClientCommands
CClientCommand rtv( "rtv", "Rock the Vote!", @rtvPUSH );
CClientCommand nominate( "nominate", "Nominate a Map!", @nomPUSH );

//Vars
CTextMenu@ rtvmenu=null;
CTextMenu@ nommenu=null;
array<string> pRocked;
array<string> pNominated;
array<string> pVoted;
array<string> mapList=g_MapCycle.GetMapCycle();
array<string> mapNominated;
array<string> rtvList;
array<int> votes(9,0);
dictionary pNominatedDict;
dictionary rtvVotes;
const int g_MAXPLAYERS=g_Engine.maxClients;
int rtvRequired;
int highest = 0;
int highestIndex = -1;
int secondHighest = 0;
int secondHighestIndex = -1;

//Timers/Schedulers
CScheduledFunction@ g_TimeToVote=null;

//Begin
void PluginInit(){
  g_Module.ScriptInfo.SetAuthor("MrOats");
  g_Module.ScriptInfo.SetContactInfo("N/A");
  g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect,@DisconnectCleanUp);
  g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer,@AddRequired);

  }
void MapInit(){
//Clean up Vars and Menus
  pRocked.resize(0);
  pNominated.resize(0);
  pVoted.resize(0);
  mapList.resize(0);
  mapNominated.resize(0);
  rtvList.resize(0);
  votes.resize(0);
  highest = 0;
  highestIndex = -1;
  secondHighest = 0;
  secondHighestIndex = -1;
  pNominatedDict.deleteAll();
  rtvVotes.deleteAll();
  if(@rtvmenu !is null)
    {
        rtvmenu.Unregister();
        @rtvmenu = null;
    }
  if(@nommenu !is null)
    {
        nommenu.Unregister();
        @nommenu = null;
    }
}

void rtvPUSH(const CCommand@ pArguments){
  CBasePlayer@ pPlayer=g_ConCommandSystem.GetCurrentPlayer();
  RockTheVote(pPlayer);
}
void nomPUSH(const CCommand@ pArguments){
  CBasePlayer@ pPlayer=g_ConCommandSystem.GetCurrentPlayer();
  if (pArguments.ArgC()==2) {
      NominateMap(pPlayer,pArguments.Arg(1));
  }
  else if (pArguments.ArgC()==1){
      NominateMenu(pPlayer);
  }
}

HookReturnCode DisconnectCleanUp(CBasePlayer@ pPlayer){
  string playerID=g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
  //Next line might be removed in case player leaves and RTV voting begins
  mapNominated.removeAt( mapNominated.find(string(pNominatedDict[playerID])) );
  rtvRequired=int(ceil(g_PlayerFuncs.GetNumPlayers()*.66));
  return HOOK_HANDLED;
}

HookReturnCode AddRequired(CBasePlayer@ pPlayer){
  rtvRequired=int(ceil(g_PlayerFuncs.GetNumPlayers()*.66));
  return HOOK_HANDLED;
}

void NominateMap(CBasePlayer@ pPlayer,string szMapName){
  string playerID=g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
  if (mapNominated.length>9)
    g_PlayerFuncs.SayText(pPlayer,"Players have reached maxed number of nominations.");
  else if((mapNominated.find(szMapName)<0)&&(pNominatedDict.exists(playerID))&&(mapList.find(szMapName)<0)){
      mapNominated.removeAt( mapNominated.find(string(pNominatedDict[playerID])) );
      g_PlayerFuncs.SayText(pPlayer,"Changing your nomination to \""+szMapName+"\".");
      mapNominated.insertLast(szMapName);
      pNominatedDict.set(playerID,szMapName);
    }
  else if((mapNominated.find(szMapName)<0)&&!(pNominatedDict.exists(playerID))&&(mapList.find(szMapName)<0)){
      g_PlayerFuncs.SayText(pPlayer,"You have nominated \""+szMapName+"\".");
      mapNominated.insertLast(szMapName);
      pNominatedDict.set(playerID,szMapName);
    }
  else g_PlayerFuncs.SayText(pPlayer,"Somebody has already nominated \""+szMapName+"\".");
}

void nominate_MenuCallback(CTextMenu@ nommenu, CBasePlayer@ pPlayer, int page, const CTextMenuItem@ item) {
  if (item !is null && pPlayer !is null)
    NominateMap(pPlayer,item.m_szName);

  if (@nommenu !is null && rtvmenu.IsRegistered())
    nommenu.Unregister();
    @nommenu = null;
}

void NominateMenu(CBasePlayer@ pPlayer){
      @nommenu = CTextMenu(@nominate_MenuCallback);
      nommenu.SetTitle("Nominate...");

      for (uint i = 0; i < mapList.length(); ++i) {
        nommenu.AddItem(mapList[i], any(mapList[i]));
      }

      nommenu.Register();
      nommenu.Open(0, 0, pPlayer);
    }

void RockTheVote(CBasePlayer@ pPlayer) {
  string playerID=g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
  if(pRocked.find(playerID)>=0){
    g_PlayerFuncs.SayText(pPlayer,"You have already Rocked the Vote!\n");
    g_PlayerFuncs.SayTextAll(pPlayer,""+pRocked.length()+" of "+rtvRequired+" players until vote initiates!\n");
  }
  else{
    pRocked.insertLast(playerID);
    g_PlayerFuncs.SayText(pPlayer,"You have Rocked the Vote!");
    g_PlayerFuncs.SayTextAll(pPlayer,""+pRocked.length()+" of "+rtvRequired+" players until vote initiates!\n");
  }
  if (int(pRocked.length())>=rtvRequired){ //Add bool to see if voting as begun already
    BeginVote();
    @g_TimeToVote = g_Scheduler.SetTimeout("ChooseMap",25);
  }
}

void rtv_MenuCallback(CTextMenu@ rtvmenu, CBasePlayer@ pPlayer, int page, const CTextMenuItem@ item) {
  if (item !is null && pPlayer !is null)
    vote(item.m_szName,pPlayer);

  if (@rtvmenu !is null && rtvmenu.IsRegistered())
    rtvmenu.Unregister();
    @rtvmenu = null;
}

void VoteMenu(){
  g_PlayerFuncs.CenterPrintAll("You have 25 seconds to vote!");
  @rtvmenu = CTextMenu(@rtv_MenuCallback);
  rtvmenu.SetTitle("RTV Vote");
  //below needs to be fixed, rtvList contains integers??
  for (uint i = 0; i < rtvList.length(); ++i) {
    rtvmenu.AddItem(rtvList[i], any(rtvList[i]));
  }

  rtvmenu.Register();

  for (int i = 1; i <= g_MAXPLAYERS; i++) {
    CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
    if(pPlayer !is null){
      rtvmenu.Open(0, 0, pPlayer);
    }
}
}
void vote(string votedMap,CBasePlayer@ pPlayer){
  string playerID=g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
  //I should make a dictionary then parse it for most voted map.
	for(int i = 0; i < int(votes.length()); i++)
	{
		if(votes[i] != 0 && votes[i] >= highest)
		{
			secondHighest = highest;
			secondHighestIndex = highestIndex;
			highest = votes[i];
			highestIndex = i;
		}
	}
  if (pVoted.find(playerID)<0){
  votes[rtvList.find(votedMap)]=+1;
  pVoted.insertLast(playerID);
  }
  else
    g_PlayerFuncs.SayText(pPlayer,"You voted already!");
}

string RandomMap(){
  return Math.RandomLong(0,mapList.length());
}

void BeginVote(){
  string rMap;
  for (uint i = 0; i < mapNominated.length(); i++) {
    rtvList.insertLast(mapNominated[i]);
  }
  while (rtvList.length()<9){
    rMap=RandomMap();
    if (rMap!=(rtvList.find(rMap))) {
      rtvList.insertLast(rMap);
    }
  }
  //Give Menus to Vote!
  VoteMenu();
}

void ChooseMap(){
if(highest==secondHighest){
  g_PlayerFuncs.CenterPrintAll("There was a tie... choosing a random map between the tie");
  int randInd=Math.RandomLong(0,1);
  if (randInd==highest) {
    g_EngineFuncs.ServerCommand("changelevel " + rtvList[highestIndex] + "\n");
  }
  else g_EngineFuncs.ServerCommand("changelevel " + rtvList[secondHighestIndex] + "\n");
}
else {
g_PlayerFuncs.CenterPrintAll("Changing map to \""+rtvList[highestIndex]+"\"\n");
g_EngineFuncs.ServerCommand("changelevel " + rtvList[highestIndex] + "\n");
}
}

string PostVote(Dictionary votedmaps){
  array<string> templist=votedmaps.getKeys();
  for (uint i = 0; i < templist.length(); i++) {
    for (int x = 0; x < g_MAXPLAYERS; x--) {
      if (votedmaps.get(templist[i], x)) {

      }
    }
    }
  }
}

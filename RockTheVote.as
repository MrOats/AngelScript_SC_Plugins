/*
Copyright (c) 2017 Drake "MrOats" Denston

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

/*
Current Status: In Development, will not work at the moment.
Documentation: https://github.com/MrOats/AngelScript_SC_Plugins/wiki/ChatTriggers.as
*/

final class RTV_Data
{

  private string m_szVotedMap = "";
  private string m_szNominatedMap = "";
  private bool m_bHasRTV = false;
  private CBasePlayer@ m_pPlayer;
  private string m_szPlayerName;
  private string m_szSteamID = "";

  //RTV Data Properties

  string szVotedMap
  {
    get const { return m_szVotedMap; }
    set { m_szVotedMap = value; }
  }
  string szNominatedMap
  {
    get const { return m_szNominatedMap; }
    set { m_szNominatedMap = value; }
  }
  bool bHasRTV
  {
    get const { return m_bHasRTV; }
    set { m_bHasRTV = value; }
  }
  CBasePlayer@ pPlayer
  {
    get const { return m_pPlayer; }
    set { @m_pPlayer = value; }
  }
  string szSteamID
  {
    get const { return m_szSteamID; }
    set { m_szSteamID = value; }
  }
  string szPlayerName
  {
    get const { return m_szPlayerName; }
    set { m_szPlayerName = value; }
  }


  //RTV Data Functions


  //Constructor

  RTV_Data(CBasePlayer@ pPlr)
  {

    @pPlayer = pPlr;
    szSteamID = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
    szPlayerName = pPlayer.pev.netname;

  }

}

//ClientCommands

CClientCommand rtv("rtv", "Rock the Vote!", @RtvPush);
CClientCommand nominate("nominate", "Nominate a Map!", @NomPush);

//Global Vars

CTextMenu@ rtvmenu = null;
CTextMenu@ nommenu = null;
array<RTV_Data@> rtv_plr_data;
dictionary rtvVotes;
bool isVoting = false;
bool canRTV = false;
int rtvRequired;
int rtvVoted = 0;
int secondsUntilVote = 5;

//Global Timers/Schedulers

CScheduledFunction@ g_TimeToVote = null;
CScheduledFunction@ g_TimeUntilVote = null;

//Begin

void PluginInit()
{

  g_Module.ScriptInfo.SetAuthor("MrOats");
  g_Module.ScriptInfo.SetContactInfo("N/A");
  g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect, @DisconnectCleanUp);
  g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @AddPlayer);

}
void MapActivate()
{
  //Clean up Vars and Menus
  rtvVotes.deleteAll();
  canRTV = false;
  isVoting = false;
  rtv_plr_data.resize(0);
  rtv_plr_data.resize(g_Engine.maxClients);

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

  g_Scheduler.RemoveTimer(g_TimeUntilVote);
  @g_TimeUntilVote = null;
  @g_TimeUntilVote = g_Scheduler.SetInterval("DecrementSeconds", 1, secondsUntilVote + 1);
}

void DecrementSeconds()
{
  if (secondsUntilVote == 0)
  {

    canRTV = true;
    g_Scheduler.RemoveTimer(g_TimeUntilVote);
    @g_TimeUntilVote = null;

  }
  else
  {

    secondsUntilVote -= 1;

  }


}

void RtvPush(const CCommand@ pArguments)
{

  CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
  RockTheVote(pPlayer);

}

void NomPush(const CCommand@ pArguments)
{

  CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

  if (pArguments.ArgC() == 2)
  {
    NominateMap(pPlayer,pArguments.Arg(1));
  }
  else if (pArguments.ArgC() == 1) {
    NominateMenu(pPlayer);
  }

}

HookReturnCode DisconnectCleanUp(CBasePlayer@ pPlayer)
{

  RTV_Data@ rtvdataobj = @rtv_plr_data[pPlayer.entindex() - 1];
  //Next line might be removed in case player leaves and RTV voting begins
  rtvdataobj.szNominatedMap.Clear();
  rtvRequired = int(ceil( g_PlayerFuncs.GetNumPlayers() * .66 ));
  @rtvdataobj = null;

  return HOOK_HANDLED;

}

HookReturnCode AddPlayer(CBasePlayer@ pPlayer)
{

  RTV_Data@ rtvdataobj = RTV_Data(pPlayer);
  @rtv_plr_data[pPlayer.entindex() - 1] = @rtvdataobj;
  rtvRequired = int( ceil( g_PlayerFuncs.GetNumPlayers() * .66 ) );

  return HOOK_HANDLED;

}

void NominateMap( CBasePlayer@ pPlayer, string szMapName )
{

  RTV_Data@ rtvdataobj = @rtv_plr_data[pPlayer.entindex() - 1];
  array<string> mapsNominated = GetNominatedMaps();
  array<string> mapList = GetMapList();


  if ( mapList.find( szMapName ) < 0 )
  {

    g_PlayerFuncs.SayText( pPlayer, "Map does not exist.\n" );
    return;

  }

  if ( mapsNominated.find( szMapName ) >= 0 )
  {

    g_PlayerFuncs.SayText( pPlayer, "Someone nominated \"" + szMapName + "\" already.\n");
    return;

  }

  if ( mapsNominated.length() > 9 )
  {

    g_PlayerFuncs.SayText( pPlayer, "Players have reached maxed number of nominations!\n" );
    return;

  }

  if ( rtvdataobj.szNominatedMap.IsEmpty() )
  {

    g_PlayerFuncs.SayTextAll( pPlayer, rtvdataobj.szPlayerName + " has nominated \"" + szMapName + "\".\n" );
    rtvdataobj.szNominatedMap = szMapName;
    return;

  }
  else
  {

    g_PlayerFuncs.SayTextAll( pPlayer, rtvdataobj.szPlayerName + " has nominated has changed their nomination to \"" + szMapName + "\".\n" );
    rtvdataobj.szNominatedMap = szMapName;
    return;

  }

}

void nominate_MenuCallback( CTextMenu@ nommenu, CBasePlayer@ pPlayer, int page, const CTextMenuItem@ item)
{

  if ( item !is null && pPlayer !is null )
    NominateMap( pPlayer,item.m_szName );

  if ( @nommenu !is null && nommenu.IsRegistered() )
  {

    nommenu.Unregister();
    @nommenu = null;

  }

}

void NominateMenu( CBasePlayer@ pPlayer )
{
      @nommenu = CTextMenu(@nominate_MenuCallback);
      nommenu.SetTitle("Nominate...");

      array<string> mapList = GetMapList();

      for (uint i = 0; i < mapList.length(); ++i) {
        nommenu.AddItem( mapList[i], any(mapList[i]));
      }

      nommenu.Register();
      nommenu.Open( 0, 0, pPlayer );
}

void RockTheVote(CBasePlayer@ pPlayer)
{

  RTV_Data@ rtvdataobj = @rtv_plr_data[pPlayer.entindex() - 1];

  if (canRTV)
  {
    if (rtvdataobj.bHasRTV)
    {

      g_PlayerFuncs.SayText(pPlayer,"You have already Rocked the Vote!\n");
      g_PlayerFuncs.SayTextAll(pPlayer,"" + rtvVoted + " of " + rtvRequired + " players until vote initiates!\n");

    }
    else
    {

      rtvdataobj.bHasRTV = true;
      rtvVoted += 1;
      g_PlayerFuncs.SayText(pPlayer,"You have Rocked the Vote!");
      g_PlayerFuncs.SayTextAll(pPlayer,"" + rtvVoted + " of " + rtvRequired + " players until vote initiates!\n");

    }

    if (rtvVoted >= rtvRequired){
      if (!isVoting)
      {

        isVoting = true;
        BeginVote();

      }

      @g_TimeToVote = g_Scheduler.SetTimeout("PostVote", 25);

    }

  }
  else
    g_PlayerFuncs.SayTextAll(pPlayer, "RTV will enable in " + secondsUntilVote +" seconds.\n" );

}

void rtv_MenuCallback(CTextMenu@ rtvmenu, CBasePlayer@ pPlayer, int page, const CTextMenuItem@ item)
{

  if (item !is null && pPlayer !is null)
    vote(item.m_szName,pPlayer);

  if (@rtvmenu !is null && rtvmenu.IsRegistered())
  {

    rtvmenu.Unregister();
    @rtvmenu = null;

  }

}

void VoteMenu(array<string> rtvList)
{

  g_PlayerFuncs.CenterPrintAll("You have 25 seconds to vote!");
  rtvVotes.deleteAll();

  @rtvmenu = CTextMenu(@rtv_MenuCallback);
  rtvmenu.SetTitle("RTV Vote");
  for (uint i = 0; i < rtvList.length(); ++i)
  {

    rtvmenu.AddItem(rtvList[i], any(rtvList[i]));

  }

  //Fill in Dictionary of Voted Maps
  //For some reason rtvList.length() != rtvVotes.getSize() in other places??
  for (size_t i = 0; i < rtvList.length(); i++)
  {

    rtvVotes.set(rtvList[i], 0);

  }

  rtvmenu.Register();

  for (int i = 1; i <= g_Engine.maxClients; i++)
  {

    CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);

    if(pPlayer !is null)
    {

      rtvmenu.Open(0, 0, pPlayer);

    }

  }

}

void vote(string votedMap,CBasePlayer@ pPlayer)
{

  RTV_Data@ rtvdataobj = @rtv_plr_data[pPlayer.entindex() - 1];

  if (rtvdataobj.szVotedMap.IsEmpty())
  {

    rtvVotes.set(votedMap, int(rtvVotes[votedMap]) + 1);
    rtvdataobj.szVotedMap = votedMap;

  }
  else
    g_PlayerFuncs.SayText(pPlayer,"You voted already!"); /* Should give player ability to change votes someday */

}

string RandomMap()
{

  array<string> mapList = GetMapList();

  return mapList[ Math.RandomLong( 0, mapList.length() - 1) ];

}

string RandomMap(array<string> mapList)
{

  return mapList[ Math.RandomLong( 0, mapList.length() - 1)];

}

string RandomMap(array<string> mapList, uint length)
{

  return mapList[Math.RandomLong(0, length)];

}

void BeginVote()
{

  array<string> rtvList;
  array<string> mapsNominated = GetNominatedMaps();

  for (uint i = 0; i < mapsNominated.length(); i++)
  {

    rtvList.insertLast(mapsNominated[i]);

  }
  while (rtvList.length() < 9) /*Make CVar for max number of maps*/
  {

    string rMap = RandomMap();

    if ( (rtvList.find(rMap)) < 0)
    {

      rtvList.insertLast(rMap);

    }

  }

  //Give Menus to Vote!
  VoteMenu(rtvList);

}

void ChooseMap(string chosenMap)
{

  g_EngineFuncs.ServerCommand("changelevel " + chosenMap + "\n");

}

void PostVote()
{

  //Find highest amount of votes
  array<string> rtvList = GetVotedMaps();

  int highestVotes = 0;

  for (size_t i = 0; i < rtvList.length(); i++)
  {

    if ( int(rtvVotes[rtvList[i]]) >= highestVotes)
    {

      highestVotes = int(rtvVotes[rtvList[i]]);

    }
  }

  //Find how many maps were voted at the highest
  array<string> candidates;
  for (size_t i = 0; i < rtvList.length(); i++)
  {

    if ( int(rtvVotes[rtvList[i]]) == highestVotes)
    {

      candidates.insertLast( rtvList[i] );

    }
  }

  //Revote if more than one map is at highest vote count
  if (candidates.length() > 1)
  {

    ClearVotedMaps();
    @g_TimeToVote = g_Scheduler.SetTimeout("PostVote", 25);
    VoteMenu(candidates);

  }
  else
  {

    g_PlayerFuncs.CenterPrintAll("Changing map to \"" + candidates[0] +"\"\n");
    g_Scheduler.SetTimeout("ChooseMap", 5, candidates[0]);

  }

}

array<string> GetNominatedMaps()
{
  array<string> nommaps;

  for (size_t i = 0; i < rtv_plr_data.length(); i++)
  {

    RTV_Data@ pPlayer = @rtv_plr_data[i];

    if (pPlayer !is null)
      if ( !(pPlayer.szNominatedMap.IsEmpty()) )
        nommaps.insertLast(pPlayer.szNominatedMap);

  }

  return nommaps;
}

array<string> GetMapList()
{

  return g_MapCycle.GetMapCycle();

}

array<string> GetVotedMaps()
{

  array<string> votedmaps;

  for (size_t i = 0; i < rtv_plr_data.length(); i++)
  {

    RTV_Data@ pPlayer = @rtv_plr_data[i];

    if (pPlayer !is null)
      if ( !(pPlayer.szVotedMap.IsEmpty()) )
        votedmaps.insertLast(pPlayer.szVotedMap);

  }

  return votedmaps;

}

void ClearVotedMaps()
{

  for (size_t i = 0; i < rtv_plr_data.length(); i++)
  {

    RTV_Data@ pPlayer = @rtv_plr_data[i];

    if (pPlayer !is null)
    {

      pPlayer.szVotedMap.Clear();
      //pPlayer.bHasRTV = false;

    }

  }

}

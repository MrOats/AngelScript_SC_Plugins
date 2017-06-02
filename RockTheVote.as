/*
Copyright (c) 2017 Drake "MrOats" Denston

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

/*
Current Status: Stable, report bugs on forums.
Documentation: https://github.com/MrOats/AngelScript_SC_Plugins/wiki/RockTheVote.as
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
CClientCommand forcevote("forcevote", "Lets admin force a vote", @ForceVote, ConCommandFlag::AdminOnly);
CClientCommand addnominatemap("addnominatemap", "Lets admin add as many nominatable maps as possible", @AddNominateMap, ConCommandFlag::AdminOnly);
CClientCommand removenominatemap("removenominatemap", "Lets admin add as many nominatable maps as possible", @RemoveNominateMap, ConCommandFlag::AdminOnly);

//Global Vars

CTextMenu@ rtvmenu = null;
CTextMenu@ nommenu = null;

array<RTV_Data@> rtv_plr_data;
array<string> forcenommaps;
array<string> prevmaps;


bool isVoting = false;
bool canRTV = false;


CCVar@ g_SecondsUntilVote;
CCVar@ g_MapList;
CCVar@ g_WhenToChange;
CCVar@ g_MaxMapsToVote;
CCVar@ g_VotingPeriodTime;
CCVar@ g_PercentageRequired;
CCVar@ g_ChooseEnding;
CCVar@ g_ExcludePrevMaps;

//Global Timers/Schedulers

CScheduledFunction@ g_TimeToVote = null;
CScheduledFunction@ g_TimeUntilVote = null;

//Hooks

void PluginInit()
{

  g_Module.ScriptInfo.SetAuthor("MrOats");
  g_Module.ScriptInfo.SetContactInfo("http://forums.svencoop.com/showthread.php/44609-Plugin-RockTheVote");
  g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect, @DisconnectCleanUp);
  g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @AddPlayer);
  g_Hooks.RegisterHook(Hooks::Game::MapChange, @ResetVars);
  g_Hooks.RegisterHook(Hooks::Player::ClientSay, @Decider);

  @g_SecondsUntilVote = CCVar("secondsUntilVote", 120, "Delay before players can RTV after map has started", ConCommandFlag::AdminOnly);
  @g_MapList = CCVar("szMapListPath", "mapcycle.txt", "Path to list of maps to use. Defaulted to map cycle file", ConCommandFlag::AdminOnly);
  @g_WhenToChange = CCVar("iChangeWhen", 0, "When to change maps post-vote: <0 for end of map, 0 for immediate change, >0 for seconds until change", ConCommandFlag::AdminOnly);
  @g_MaxMapsToVote = CCVar("iMaxMaps", 9, "How many maps can players nominate and vote for later", ConCommandFlag::AdminOnly);
  @g_VotingPeriodTime = CCVar("secondsToVote", 25, "How long can players vote for a map before a map is chosen", ConCommandFlag::AdminOnly);
  @g_PercentageRequired = CCVar("iPercentReq", 66, "0-100, percent of players required to RTV before voting happens", ConCommandFlag::AdminOnly);
  @g_ChooseEnding = CCVar("iChooseEnding", 1, "Set to 1 to revote when a tie happens, 2 to choose randomly amongst the ties, 3 to await RTV again", ConCommandFlag::AdminOnly);
  @g_ExcludePrevMaps = CCVar("iExcludePrevMaps", 0, "How many maps to exclude from nomination or voting", ConCommandFlag::AdminOnly);

}

void MapActivate()
{

  //Clean up Vars and Menus
  canRTV = false;
  isVoting = false;
  g_Scheduler.ClearTimerList();
  @g_TimeToVote = null;
  @g_TimeUntilVote = null;

  //int prevmaps_len = int(prevmaps.length());
  if (g_ExcludePrevMaps.GetInt() < 0)
    g_ExcludePrevMaps.SetInt(0);


  if ( int(prevmaps.length()) > g_ExcludePrevMaps.GetInt())
    prevmaps.removeAt(0);

  prevmaps.insertLast(g_Engine.mapname);

  rtv_plr_data.resize(g_Engine.maxClients);
  for (uint i = 0; i < rtv_plr_data.length(); i++)
    @rtv_plr_data[i] = null;

  for (uint i = 0; i < forcenommaps.length(); i++)
    forcenommaps[i] = "";

    forcenommaps.resize(0);

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

  @g_TimeUntilVote = g_Scheduler.SetInterval("DecrementSeconds", 1, g_SecondsUntilVote.GetInt() + 1);

}

HookReturnCode Decider(SayParameters@ pParams)
{

  CBasePlayer@ pPlayer = pParams.GetPlayer();
  const CCommand@ pArguments = pParams.GetArguments();

  if (pArguments[0] == "nominate")
  {

    NomPush(@pArguments, @pPlayer);
    return HOOK_HANDLED;

  }
  else if (pArguments[0] == "rtv")
  {

    RtvPush(@pArguments, @pPlayer);
    return HOOK_HANDLED;

  }
  /* Will do this if need be...
  else if (pArguments[0] == "!forcevote")
  {

    ForceVote(@pArguments, @pPlayer);
    return HOOK_HANDLED;

  }
  */
  else return HOOK_CONTINUE;

}

HookReturnCode ResetVars()
{

  g_Scheduler.ClearTimerList();
  @g_TimeToVote = null;
  @g_TimeUntilVote = null;

  return HOOK_HANDLED;

}


HookReturnCode DisconnectCleanUp(CBasePlayer@ pPlayer)
{

  RTV_Data@ rtvdataobj = @rtv_plr_data[pPlayer.entindex() - 1];
  @rtvdataobj = null;

  return HOOK_HANDLED;

}

HookReturnCode AddPlayer(CBasePlayer@ pPlayer)
{

  RTV_Data@ rtvdataobj = RTV_Data(pPlayer);
  @rtv_plr_data[pPlayer.entindex() - 1] = @rtvdataobj;

  return HOOK_HANDLED;

}

//Main Functions
void DecrementSeconds()
{

  if (g_SecondsUntilVote.GetInt() == 0)
  {

    canRTV = true;
    g_Scheduler.RemoveTimer(g_TimeUntilVote);
    @g_TimeUntilVote = null;

  }
  else
  {

    g_SecondsUntilVote.SetInt(g_SecondsUntilVote.GetInt() - 1);

  }

}

void RtvPush(const CCommand@ pArguments, CBasePlayer@ pPlayer)
{

  if (isVoting)
  {

    rtvmenu.Open(0, 0, pPlayer);

  }
  else
  {
    if (canRTV)
    {

      RockTheVote(pPlayer);

    }
    else
    {

      MessageWarnAllPlayers(pPlayer, "RTV will enable in " + g_SecondsUntilVote.GetInt() + " seconds." );

    }

  }

}

void RtvPush(const CCommand@ pArguments)
{

  CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

  if (isVoting)
  {

    rtvmenu.Open(0, 0, pPlayer);

  }
  else
  {
    if (canRTV)
    {

      RockTheVote(pPlayer);

    }
    else
    {

      MessageWarnAllPlayers(pPlayer, "RTV will enable in " + g_SecondsUntilVote.GetInt() + " seconds." );

    }

  }

}

void NomPush(const CCommand@ pArguments, CBasePlayer@ pPlayer)
{

  if (pArguments.ArgC() == 2)
  {

    NominateMap(pPlayer, pArguments.Arg(1));

  }
  else if (pArguments.ArgC() == 1)
  {

    NominateMenu(pPlayer);

  }

}


void NomPush(const CCommand@ pArguments)
{

  CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

  if (pArguments.ArgC() == 2)
  {

    NominateMap(pPlayer,pArguments.Arg(1));

  }
  else if (pArguments.ArgC() == 1)
  {

    NominateMenu(pPlayer);

  }

}

void ForceVote(const CCommand@ pArguments, CBasePlayer@ pPlayer)
{

  if (pArguments.ArgC() >= 2)
  {

    array<string> rtvList;

    for (int i = 1; i < pArguments.ArgC(); i++)
    {

      if (g_EngineFuncs.IsMapValid(pArguments.Arg(i)))
        rtvList.insertLast(pArguments.Arg(i));
      else
        MessageWarnPlayer(pPlayer, pArguments.Arg(i) + " is not a valid map. Skipping...");

    }

    VoteMenu(rtvList);
    @g_TimeToVote = g_Scheduler.SetTimeout("PostVote", g_VotingPeriodTime.GetInt());

  }
  else if (pArguments.ArgC() == 1)
  {

    BeginVote();
    @g_TimeToVote = g_Scheduler.SetTimeout("PostVote", g_VotingPeriodTime.GetInt());

  }

}

void ForceVote(const CCommand@ pArguments)
{

  CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

  if (pArguments.ArgC() >= 2)
  {

    array<string> rtvList;

    for (int i = 1; i < pArguments.ArgC(); i++)
    {

      if (g_EngineFuncs.IsMapValid(pArguments.Arg(i)))
        rtvList.insertLast(pArguments.Arg(i));
      else
        MessageWarnPlayer(pPlayer, pArguments.Arg(i) + " is not a valid map. Skipping...");

    }

    VoteMenu(rtvList);
    @g_TimeToVote = g_Scheduler.SetTimeout("PostVote", g_VotingPeriodTime.GetInt());

  }
  else if (pArguments.ArgC() == 1)
  {

    BeginVote();
    @g_TimeToVote = g_Scheduler.SetTimeout("PostVote", g_VotingPeriodTime.GetInt());

  }

}

void AddNominateMap(const CCommand@ pArguments)
{

  CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
  array<string> plrnom = GetNominatedMaps();


  if (pArguments.ArgC() == 1)
  {

    MessageWarnPlayer(pPlayer, "You did not specify a map to nominate. Try again.");
    return;

  }

  if (g_EngineFuncs.IsMapValid(pArguments.Arg(1)))
  {

    if ( (plrnom.find(pArguments.Arg(1)) < 0) && (forcenommaps.find(pArguments.Arg(1)) < 0) )
    {

      forcenommaps.insertLast(pArguments.Arg(1));
      MessageWarnPlayer(pPlayer, "Map was added to force nominated maps list");

    }
    else
      MessageWarnPlayer(pPlayer, "Map was already nominated by someone else. Skipping...");

  }
  else
    MessageWarnPlayer(pPlayer, "Map does not exist. Skipping...");


}

void RemoveNominateMap(const CCommand@ pArguments)
{

  CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
  array<string> plrnom = GetNominatedMaps();


  if (pArguments.ArgC() == 1)
  {

    MessageWarnPlayer(pPlayer, "You did not specify a map to remove from nominations. Try again.");
    return;

  }


    if (plrnom.find(pArguments.Arg(1)) >= 0)
    {

      //Let's figure out who nominated that map and remove it...
      for (uint i = 0; i < rtv_plr_data.length(); i++)
      {

          if (@rtv_plr_data[i] !is null)
          {

            if (rtv_plr_data[i].szNominatedMap == pArguments.Arg(1))
              {

                MessageWarnAllPlayers(pPlayer, string(rtv_plr_data[i].szPlayerName + " has removed " + rtv_plr_data[i].szPlayerName + " nomination of " + rtv_plr_data[i].szNominatedMap));
                rtv_plr_data[i].szNominatedMap = "";

              }

          }
      }

    }
    else if (forcenommaps.find(pArguments.Arg(1)) >= 0)
    {

      forcenommaps.removeAt(forcenommaps.find(pArguments.Arg(1)));
      MessageWarnPlayer(pPlayer, pArguments.Arg(1) +  " was removed from admin's nominations");

    }
    else MessageWarnPlayer(pPlayer, pArguments.Arg(1) + " was not nominated. Skipping...");

}

CBasePlayer@ PickRandomPlayer()
{

  CBasePlayer@ pPlayer;
  for (int i = 1; i <= g_Engine.maxClients; i++)
  {

    @pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
    if ( (pPlayer !is null) && (pPlayer.IsConnected()) )
      break;

  }

  return @pPlayer;

}

void MessageWarnPlayer(CBasePlayer@ pPlayer, string msg)
{

  g_PlayerFuncs.SayText( pPlayer, "[RTV] " + msg + "\n");

}

void MessageWarnAllPlayers(CBasePlayer@ pPlayer, string msg)
{

  g_PlayerFuncs.SayTextAll( pPlayer, "[RTV] " + msg + "\n");

}


void NominateMap( CBasePlayer@ pPlayer, string szMapName )
{

  RTV_Data@ rtvdataobj = @rtv_plr_data[pPlayer.entindex() - 1];
  array<string> mapsNominated = GetNominatedMaps();
  array<string> mapList = GetMapList();


  if ( mapList.find( szMapName ) < 0 )
  {

    MessageWarnPlayer( pPlayer, "Map does not exist." );
    return;

  }

  if (prevmaps.find( szMapName ) >= 0)
  {

    MessageWarnPlayer( pPlayer, "Map has already been played and will be excluded until later.");
    return;

  }

  if ( forcenommaps.find( szMapName ) >= 0 )
  {

    MessageWarnPlayer( pPlayer, "\"" + szMapName + "\" was found in the admin's list of nominated maps.");
    return;

  }

  if ( mapsNominated.find( szMapName ) >= 0 )
  {

    MessageWarnPlayer( pPlayer, "Someone nominated \"" + szMapName + "\" already.");
    return;

  }

  if ( int(mapsNominated.length()) > g_MaxMapsToVote.GetInt() )
  {

    MessageWarnPlayer( pPlayer, "Players have reached maxed number of nominations!" );
    return;

  }

  if ( rtvdataobj.szNominatedMap.IsEmpty() )
  {

    MessageWarnAllPlayers( pPlayer, rtvdataobj.szPlayerName + " has nominated \"" + szMapName + "\"." );
    rtvdataobj.szNominatedMap = szMapName;
    return;

  }
  else
  {

    MessageWarnAllPlayers( pPlayer, rtvdataobj.szPlayerName + " has changed their nomination to \"" + szMapName + "\"." );
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

      //Remove any maps found in the previous map exclusion list or force nominated maps
      for (uint i = 0; i < mapList.length();)
      {

        if ((prevmaps.find(mapList[i]) >= 0))
          mapList.removeAt(i);
        else if((forcenommaps.find(mapList[i]) >= 0))
          mapList.removeAt(i);
        else
          ++i;

      }

      mapList.sortAsc();

      for (uint i = 0; i < mapList.length(); i++)
        nommenu.AddItem( mapList[i], any(mapList[i]));

      if (!(nommenu.IsRegistered()))
        nommenu.Register();

      nommenu.Open( 0, 0, pPlayer );

}

void RockTheVote(CBasePlayer@ pPlayer)
{

  RTV_Data@ rtvdataobj = @rtv_plr_data[pPlayer.entindex() - 1];
  int rtvRequired = CalculateRequired();

  if (rtvdataobj.bHasRTV)
  {

    MessageWarnPlayer(pPlayer,"You have already Rocked the Vote!");
    MessageWarnAllPlayers(pPlayer,"" + GetRTVd() + " of " + rtvRequired + " players until vote initiates!");

  }
  else
  {

    rtvdataobj.bHasRTV = true;
    MessageWarnPlayer(pPlayer,"You have Rocked the Vote!");
    MessageWarnAllPlayers(pPlayer,"" + GetRTVd() + " of " + rtvRequired + " players until vote initiates!");

  }

  if (GetRTVd() >= rtvRequired)
  {

    if (!isVoting)
    {

      isVoting = true;
      BeginVote();

    }

    @g_TimeToVote = g_Scheduler.SetTimeout("PostVote", g_VotingPeriodTime.GetInt());

  }

}

void rtv_MenuCallback(CTextMenu@ rtvmenu, CBasePlayer@ pPlayer, int page, const CTextMenuItem@ item)
{

  if (item !is null && pPlayer !is null)
    vote(item.m_szName,pPlayer);

}

void VoteMenu(array<string> rtvList)
{

  canRTV = true;
  MessageWarnAllPlayers( PickRandomPlayer(), "You have " + g_VotingPeriodTime.GetInt() + " seconds to vote!");

  @rtvmenu = CTextMenu(@rtv_MenuCallback);
  rtvmenu.SetTitle("RTV Vote");
  for (uint i = 0; i < rtvList.length(); i++)
  {

    rtvmenu.AddItem(rtvList[i], any(rtvList[i]));

  }

  if (!(rtvmenu.IsRegistered()))
  {

    rtvmenu.Register();

  }

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

    rtvdataobj.szVotedMap = votedMap;
    MessageWarnPlayer(pPlayer,"You voted for " + votedMap);

  }
  else
  {

    rtvdataobj.szVotedMap = votedMap;
    MessageWarnPlayer(pPlayer,"You changed your vote to "+ votedMap);

  }


}

void BeginVote()
{

  canRTV = true;

  array<string> rtvList;
  array<string> mapsNominated = GetNominatedMaps();
  array<string> templist = GetMapList();

  for (uint i = 0; i < forcenommaps.length(); i++)
    rtvList.insertLast(forcenommaps[i]);

  for (uint i = 0; i < mapsNominated.length(); i++)
    rtvList.insertLast(mapsNominated[i]);


  //If our given list of maps is less than g_MaxMapsToVote, then fill rtvList with rest of un-nominated list of maps
  if (int(templist.length()) < g_MaxMapsToVote.GetInt())
  {

    for (uint i = 0; i < templist.length(); i++)
    {

      if (rtvList.find(templist[i]) < 0)
      {

        rtvList.insertLast(templist[i]);

      }

    }

  }
  else /* Else fill remaining with randoms*/
  {

    while ( int(rtvList.length()) < g_MaxMapsToVote.GetInt())
    {

      string rMap = RandomMap();

      if ( ((rtvList.find(rMap)) < 0) && (prevmaps.find(rMap) < 0))
      {

        rtvList.insertLast(rMap);

      }

    }

  }

  //Give Menus to Vote!
  VoteMenu(rtvList);

}

void PostVote()
{

  array<string> rtvList = GetVotedMaps();
  dictionary rtvVotes;
  int highestVotes = 0;

  //Initialize Dictionary of votes
  for (uint i = 0; i < rtvList.length(); i++)
  {

    rtvVotes.set( rtvList[i], 0);

  }

  for (uint i = 0; i < rtvList.length(); i++)
  {

    int val = int(rtvVotes[rtvList[i]]);
    rtvVotes[rtvList[i]] = val + 1;

  }

  //Find highest amount of votes
  for (uint i = 0; i < rtvList.length(); i++)
  {

    if ( int( rtvVotes[rtvList[i]] ) >= highestVotes)
    {

      highestVotes = int(rtvVotes[rtvList[i]]);

    }
  }

  //Nobody voted?
  if (highestVotes == 0)
  {

    string chosenMap = RandomMap();
    MessageWarnAllPlayers( PickRandomPlayer(), "\"" + chosenMap +"\" has been randomly chosen since nobody picked");
    ChooseMap(chosenMap, false);
    return;

  }

  //Find how many maps were voted at the highest
  array<string> candidates;
  array<string> singlecount = rtvVotes.getKeys();
  for (uint i = 0; i < singlecount.length(); i++)
  {

    if ( int(rtvVotes[singlecount[i]]) == highestVotes)
    {

      candidates.insertLast( singlecount[i] );

    }
  }
  singlecount.resize(0);

  //Revote or random choose if more than one map is at highest vote count
  if (candidates.length() > 1)
  {

    if (g_ChooseEnding.GetInt() == 1)
    {

      ClearVotedMaps();
      MessageWarnAllPlayers( PickRandomPlayer(), "There was a tie! Revoting...");
      @g_TimeToVote = g_Scheduler.SetTimeout("PostVote", g_VotingPeriodTime.GetInt());
      VoteMenu(candidates);
      return;

    }
    else if (g_ChooseEnding.GetInt() == 2)
    {

      string chosenMap = RandomMap(candidates);
      MessageWarnAllPlayers( PickRandomPlayer(), "\"" + chosenMap +"\" has been randomly chosen amongst the tied");
      ChooseMap(chosenMap, false);
      return;

    }
    else if (g_ChooseEnding.GetInt() == 3)
    {

      ClearVotedMaps();
      ClearRTV();

      MessageWarnAllPlayers( PickRandomPlayer(), "There was a tie! Please RTV again...");

    }
    else
      g_Game.AlertMessage(at_console, "[RTV] Fix your ChooseEnding CVar!\n");
  }
  else
  {

    MessageWarnAllPlayers( PickRandomPlayer(), "\"" + candidates[0] +"\" has been chosen!");
    ChooseMap(candidates[0], false);
    return;

  }

}

void ChooseMap(string chosenMap, bool forcechange)
{

  //After X seconds passed or if CVar WhenToChange is 0
  if (forcechange || (g_WhenToChange.GetInt() == 0) )
    g_EngineFuncs.ServerCommand("changelevel " + chosenMap + "\n");

  //Change after X Seconds
  if (g_WhenToChange.GetInt() > 0)
  {

    g_Scheduler.SetTimeout("ChooseMap", g_WhenToChange.GetInt(), chosenMap, true);

  }
  //Change after map end
  if (g_WhenToChange.GetInt() < 0)
  {

    //Handle "infinite time left" maps by setting time left to X minutes
    if (g_EngineFuncs.CVarGetFloat("mp_timelimit") == 0)
    {

      //Can't set mp_timeleft...
      //g_EngineFuncs.CVarSetFloat("mp_timeleft", 600);
      g_Scheduler.SetTimeout("ChooseMap", abs(g_WhenToChange.GetInt()), chosenMap, true);

    }

    /*
    NetworkMessage@ netmsg(CLIENT_ALL, NetworkMessages::NetworkMessageType type, const Vector& in vecOrigin, edict_t@ pEdict = null);
    netmsg.WriteString(chosenMap);
    netmsg.End();
    */
    g_EngineFuncs.ServerCommand("mp_nextmap " + chosenMap + "\n");
    g_EngineFuncs.ServerCommand("mp_nextmap_cycle " + chosenMap + "\n");
    MessageWarnAllPlayers( PickRandomPlayer(), "Next map has been set to \"" + chosenMap + "\".");

  }

}

// Utility Functions

int CalculateRequired()
{

  return int(ceil( g_PlayerFuncs.GetNumPlayers() * (g_PercentageRequired.GetInt() / 100.0f) ));

}

string RandomMap()
{

  array<string> mapList = GetMapList();

  return mapList[ Math.RandomLong( 0, mapList.length() - 1) ];

}

string RandomMap(array<string> mapList)
{

  return mapList[ Math.RandomLong( 0, mapList.length() - 1) ];

}

string RandomMap(array<string> mapList, uint length)
{

  return mapList[ Math.RandomLong(0, length) ];

}

array<string> GetNominatedMaps()
{
  array<string> nommaps;

  for (uint i = 0; i < rtv_plr_data.length(); i++)
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

  array<string> mapList;

  if ( !(g_MapList.GetString() == "mapcycle.txt" ) )
  {

    File@ file = g_FileSystem.OpenFile(g_MapList.GetString(), OpenFile::READ);

    if(file !is null && file.IsOpen())
    {

      g_Game.AlertMessage(at_console, "[RTV] Opening file!!!\n");
      while(!file.EOFReached())
      {

        string sLine;
        file.ReadLine(sLine);
        string sFix = sLine.SubString(sLine.Length()-1,1);

        if(sFix == " " || sFix == "\n" || sFix == "\r" || sFix == "\t")
          sLine = sLine.SubString(0, sLine.Length() - 1);

        if(sLine.SubString(0,1) == "#" || sLine.IsEmpty())
          continue;

        //g_Game.AlertMessage(at_console, "" + sLine + "\n");
        //array<string> parsed = sLine.Split(" ");
        mapList.insertLast(sLine);

      }

      file.Close();

      //Probably wanna make sure all maps are valid...
      for (uint i = 0; i < mapList.length();)
      {

        if ( !(g_EngineFuncs.IsMapValid(mapList[i])) )
        {

          mapList.removeAt(i);

        }
        else
          ++i;

      }

    }

    return mapList;

  }

  g_Game.AlertMessage(at_console, "[RTV] Using MapCycle.txt\n");
  return g_MapCycle.GetMapCycle();

}


array<string> GetVotedMaps()
{

  array<string> votedmaps;

  for (uint i = 0; i < rtv_plr_data.length(); i++)
  {

    if (@rtv_plr_data[i] !is null)
      if ( !(rtv_plr_data[i].szVotedMap.IsEmpty()) )
        votedmaps.insertLast(rtv_plr_data[i].szVotedMap);

  }

  return votedmaps;

}

int GetRTVd()
{

  int counter = 0;
  for (uint i = 0; i < rtv_plr_data.length(); i++)
  {

    if (@rtv_plr_data[i] !is null)
      if (rtv_plr_data[i].bHasRTV)
        counter += 1;

  }

  return counter;

}

void ClearVotedMaps()
{

  for (uint i = 0; i < rtv_plr_data.length(); i++)
  {

    if (@rtv_plr_data[i] !is null)
    {

      rtv_plr_data[i].szVotedMap = "";

    }

  }

}

void ClearRTV()
{

  for (uint i = 0; i < rtv_plr_data.length(); i++)
  {

    if (@rtv_plr_data[i] !is null)
    {

      rtv_plr_data[i].bHasRTV = false;

    }

  }

}

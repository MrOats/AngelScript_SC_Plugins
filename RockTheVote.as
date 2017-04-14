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

int rtvVoted = 0;

CCVar@ g_SecondsUntilVote;
CCVar@ g_MapList;
CCVar@ g_WhenToChange;
CCVar@ g_MaxMapsToVote;
CCVar@ g_VotingPeriodTime;
CCVar@ g_PercentageRequired;
CCVar@ g_ChooseRandom;

//Global Timers/Schedulers

CScheduledFunction@ g_TimeToVote = null;
CScheduledFunction@ g_TimeUntilVote = null;

//Hooks

void PluginInit()
{

  g_Module.ScriptInfo.SetAuthor("MrOats");
  g_Module.ScriptInfo.SetContactInfo("N/A");
  g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect, @DisconnectCleanUp);
  g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @AddPlayer);
  g_Hooks.RegisterHook(Hooks::Game::MapChange,@ResetCVars);

  @g_SecondsUntilVote = CCVar("secondsUntilVote", 120, "Delay before players can RTV after map has started", ConCommandFlag::AdminOnly);
  @g_MapList = CCVar("szMapListPath", "mapcycle.txt", "Path to list of maps to use. Defaulted to map cycle file", ConCommandFlag::AdminOnly);
  @g_WhenToChange = CCVar("iChangeWhen", 0, "When to change maps post-vote: <0 for end of map, 0 for immediate change, >1 for seconds until change", ConCommandFlag::AdminOnly);
  @g_MaxMapsToVote = CCVar("iMaxMaps", 9, "How many maps can players nominate and vote for later", ConCommandFlag::AdminOnly);
  @g_VotingPeriodTime = CCVar("secondsToVote", 25, "How long can players vote for a map before a map is chosen", ConCommandFlag::AdminOnly);
  @g_PercentageRequired = CCVar("iPercentReq", 66, "0-100, percent of players required to RTV before voting happens", ConCommandFlag::AdminOnly);
  @g_ChooseRandom = CCVar("bChooseRandom",false, "Set to false to revote when a tie happens or true to choose randomly amongst the ties", ConCommandFlag::AdminOnly);

}

void MapActivate()
{

  //Clean up Vars and Menus
  rtvVotes.deleteAll();
  canRTV = false;
  isVoting = false;
  g_Scheduler.ClearTimerList();
  @g_TimeToVote = null;
  @g_TimeUntilVote = null;


  rtv_plr_data.resize(g_Engine.maxClients);
  for (size_t i = 0; i < rtv_plr_data.length(); i++)
  {
    rtv_plr_data[i] = null;
  }

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

HookReturnCode ResetCVars()
{

  g_Scheduler.ClearTimerList();
  @g_TimeToVote = null;
  @g_TimeUntilVote = null;

  g_SecondsUntilVote.SetInt(120);
  g_MapList.SetString("/path/to/file");
  g_WhenToChange.SetInt(0);
  g_MaxMapsToVote.SetInt(9);
  g_VotingPeriodTime.SetInt(25);
  g_PercentageRequired.SetInt(66);
  g_ChooseRandom.SetBool(false);

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

int CalculateRequired()
{

  return int(ceil( g_PlayerFuncs.GetNumPlayers() * (g_PercentageRequired.GetInt() / 100) ));

}

void RtvPush(const CCommand@ pArguments)
{

  CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
  if (canRTV)
  {

    RockTheVote(pPlayer);

  }
  else
  {

    g_PlayerFuncs.SayTextAll(pPlayer, "RTV will enable in " + g_SecondsUntilVote.GetInt() +" seconds.\n" );

  }


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

  if ( mapsNominated.length() > g_MaxMapsToVote.GetInt() )
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

  if (rtvdataobj.bHasRTV)
  {

    g_PlayerFuncs.SayText(pPlayer,"You have already Rocked the Vote!\n");
    g_PlayerFuncs.SayTextAll(pPlayer,"" + rtvVoted + " of " + CalculateRequired() + " players until vote initiates!\n");

  }
  else
  {

    rtvdataobj.bHasRTV = true;
    rtvVoted += 1;
    g_PlayerFuncs.SayText(pPlayer,"You have Rocked the Vote!");
    g_PlayerFuncs.SayTextAll(pPlayer,"" + rtvVoted + " of " + CalculateRequired() + " players until vote initiates!\n");

  }

  if (rtvVoted >= CalculateRequired())
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

  if (@rtvmenu !is null && rtvmenu.IsRegistered())
  {

    rtvmenu.Unregister();
    @rtvmenu = null;

  }

}

void VoteMenu(array<string> rtvList)
{

  g_PlayerFuncs.CenterPrintAll("You have " + g_VotingPeriodTime.GetInt() + " seconds to vote!\n");
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

void BeginVote()
{

  array<string> rtvList;
  array<string> mapsNominated = GetNominatedMaps();

  for (uint i = 0; i < mapsNominated.length(); i++)
  {

    rtvList.insertLast(mapsNominated[i]);

  }

  while (rtvList.length() < g_MaxMapsToVote.GetInt())
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

void PostVote()
{

  //Find highest amount of votes
  array<string> rtvList = GetVotedMaps();

  int highestVotes = 0;

  for (size_t i = 0; i < rtvList.length(); i++)
  {

    if ( int( rtvVotes[rtvList[i]] ) >= highestVotes)
    {

      highestVotes = int(rtvVotes[rtvList[i]]);

    }
  }

  //Nobody voted?
  if (highestVotes == 0)
  {

    string chosenMap = RandomMap(candidates);
    g_PlayerFuncs.CenterPrintAll("\"" + chosenMap +"\" has been randomly chosen since nobody picked\n");
    ChooseMap(chosenMap, false);

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

  //Revote or random choose if more than one map is at highest vote count
  if (candidates.length() > 1)
  {

    if (g_ChooseRandom.GetBool())
    {

      string chosenMap = RandomMap(candidates);
      g_PlayerFuncs.CenterPrintAll("\"" + chosenMap +"\" has been randomly chosen amongst the tied\n");
      ChooseMap(chosenMap, false);

    }
    else
    {

      ClearVotedMaps();
      g_PlayerFuncs.CenterPrintAll("There was a tie! Revoting...\n");
      @g_TimeToVote = g_Scheduler.SetTimeout("PostVote", g_VotingPeriodTime.GetInt());
      VoteMenu(candidates);

    }

  }
  else
  {

    g_PlayerFuncs.CenterPrintAll("\"" + candidates[0] +"\" has been chosen!\n");
    ChooseMap(candidates[0], false);

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

    //Handle "infinite time left" maps by setting time left to 10 minutes
    if (g_EngineFuncs.CVarGetFloat("mp_timelimit") == 0)
    {

      g_EngineFuncs.CVarSetFloat("mp_timeleft", 600);

    }

    /*
    NetworkMessage@ netmsg(CLIENT_ALL, NetworkMessages::NetworkMessageType type, const Vector& in vecOrigin, edict_t@ pEdict = null);
    netmsg.WriteString(chosenMap);
    netmsg.End();
    */
    g_EngineFuncs.ServerCommand("mp_nextmap_cycle " + chosenMap + "\n");
    g_PlayerFuncs.CenterPrintAll("Next map has been set to \"" + chosenMap + "\".\n");

  }

}

// Utility Functions

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

  array<string> mapList;

  if ( !(g_MapList.GetString() == "mapcycle.txt" ) )
  {

    File@ file = g_FileSystem.OpenFile(g_MapList.GetString(), OpenFile::READ);

    if(file !is null && file.IsOpen())
    {

      while(!file.EOFReached())
      {

        string sLine;
        file.ReadLine(sLine);
        if(sLine.SubString(0,1) == "#" || sLine.IsEmpty())
          continue;

        array<string> parsed = sLine.Split(" ");
        if(parsed.length() < 2)
          continue;

        mapList.insertLast(parsed[1]);

      }

      file.Close();

      //Probably wanna make sure all maps are valid...
      for (size_t i = 0; i < mapList.length(); i++)
      {

        if ( !(g_EngineFuncs.IsMapValid(mapList[i])) )
        {

          mapList.removeAt(i);

        }

      }

    }

    return mapList;

  }

}
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

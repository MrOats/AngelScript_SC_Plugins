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
CClientCommand rtv("rtv", "Rock the Vote!", @RtvPush);
CClientCommand nominate("nominate", "Nominate a Map!", @NomPush);

//Vars
CTextMenu@ rtvmenu = null;
CTextMenu@ nommenu = null;
array<RTV_Data@> rtv_plr_data;
array<string> mapList = g_MapCycle.GetMapCycle();
array<string> mapNominated;
array<string> rtvList;
dictionary rtvVotes;
const int g_MAXPLAYERS = g_Engine.maxClients;
bool isVoting = false;
bool canRTV = false;
int rtvRequired;
int rtvVoted = 0;
int secondsUntilVote = 60 * 3;

//Timers/Schedulers
CScheduledFunction@ g_TimeToVote = null;
CScheduledFunction@ g_TimeUntilVote = null;

final class RTV_Data
{

  private string m_szVotedMap = "";
  private string m_szNominatedMap = "";
  private bool m_bHasRTV = false;
  private CBasePlayer@ m_pPlayer;
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
  }
  string szSteamID
  {
    set { m_szSteamID = value; }
  }

//Constructor

  RTV_Data(CBasePlayer@ pPlr)
  {

    @pPlayer = @pPlr;
    szSteamID = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );

  }

//RTV Data Functions



}
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
  mapList.resize(0);
  mapNominated.resize(0);
  rtvList.resize(0);
  rtvVotes.deleteAll();
  canRTV = false;
  isVoting = false;

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

  @g_TimeUntilVote = g_Scheduler.SetInterval("DecrementSeconds", 1, secondsUntilVote);
}

void DecrementSeconds()
{
  if (secondsUntilVote < 1)
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

  rtvdataobj = rtv_plr_data[pPlayer.entindex() - 1];
  //Next line might be removed in case player leaves and RTV voting begins
  mapNominated.removeAt( mapNominated.find( string( pNominatedDict[playerID] )));
  rtvRequired = int(ceil( g_PlayerFuncs.GetNumPlayers() * .66 ));
  rtvdataobj = null;

  return HOOK_HANDLED;

}

HookReturnCode AddPlayer(CBasePlayer@ pPlayer)
{

  RTV_Data@ rtvdataobj = RTV_Data(pPlayer);
  rtv_plr_data[pPlayer.entindex() - 1] = rtvdataobj;
  rtvRequired = int( ceil( g_PlayerFuncs.GetNumPlayers() * .66 ) );

  return HOOK_HANDLED;

}

void NominateMap( CBasePlayer@ pPlayer, string szMapName )
{

  rtvdataobj = rtv_plr_data[pPlayer.entindex() - 1];

  if (mapNominated.length > 9)
    g_PlayerFuncs.SayText( pPlayer, "Players have reached maxed number of nominations." );
  else if ( ( mapNominated.find( szMapName ) < 0 ) && ( !(rtvdataobj.szNominatedMap.isEmpty()) ) && ( mapList.find( szMapName ) < 0 ) )
  {

    mapNominated.removeAt( mapNominated.find( rtvdataobj.szNominatedMap ) ) );
    g_PlayerFuncs.SayText( pPlayer, "Changing your nomination to \"" + szMapName + "\"." );
    mapNominated.insertLast( szMapName );
    rtvdataobj.szNominatedMap = szMapName;

  }
  else if ( (mapNominated.find( szMapName ) < 0 ) && ( rtvdataobj.szNominatedMap.isEmpty() ) && ( mapList.find( szMapName ) < 0 ) )
  {

    g_PlayerFuncs.SayTextAll( pPlayer, pPlayer. nominated \"" + szMapName + "\"." );
    mapNominated.insertLast( szMapName );
    rtvdataobj.szNominatedMap = szMapName;

  }
  else if ( mapList.find( szMapName ) < 0)
  {

    g_PlayerFuncs.SayText( pPlayer, "\"" + szMapName + "\" does not exist." );

  }
  else g_PlayerFuncs.SayText( pPlayer, "Somebody has already nominated \"" + szMapName + "\"." );

}

void nominate_MenuCallback( CTextMenu@ nommenu, CBasePlayer@ pPlayer, int page, const CTextMenuItem@ item)
{

  if ( item !is null && pPlayer !is null )
    NominateMap( pPlayer,item.m_szName );

  if ( @nommenu !is null && rtvmenu.IsRegistered() )
    nommenu.Unregister();
    @nommenu = null;

}

void NominateMenu( CBasePlayer@ pPlayer )
{
      @nommenu = CTextMenu(@nominate_MenuCallback);
      nommenu.SetTitle("Nominate...");

      for (uint i = 0; i < mapList.length(); ++i) {
        nommenu.AddItem( mapList[i], any(mapList[i]));
      }

      nommenu.Register();
      nommenu.Open( 0, 0, pPlayer );
}

void RockTheVote(CBasePlayer@ pPlayer) {

  rtvdataobj = rtv_plr_data[pPlayer.entindex() - 1];
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

void VoteMenu()
{

  g_PlayerFuncs.CenterPrintAll("You have 25 seconds to vote!");

  @rtvmenu = CTextMenu(@rtv_MenuCallback);
  rtvmenu.SetTitle("RTV Vote");
  for (uint i = 0; i < rtvList.length(); ++i)
  {

    rtvmenu.AddItem(rtvList[i], any(rtvList[i]));

  }

  //Fill in Dictionary of Voted Maps
  for (size_t i = 0; i < rtvList.length(); i++)
  {

    rtvVoted.set(rtvList[i], 0);

  }

  rtvmenu.Register();

  for (int i = 1; i <= g_MAXPLAYERS; i++)
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

  rtvdataobj = rtv_plr_data[pPlayer.entindex() - 1];
  //I should make a dictionary then parse it for most voted map.
  if (rtvdataobj.szVotedMap.isEmpty())
  {

    rtvVotes.set(votedMap, int(rtvVotes[votedMap] += 1);
    rtvdataobj.szVotedMap = votedMap;

  }
  else
    g_PlayerFuncs.SayText(pPlayer,"You voted already!"); /* Should give player ability to change votes someday */

}

string RandomMap()
{

  return mapList[Math.RandomLong(0,mapList.length())];

}

void BeginVote()
{

  string rMap;
  for (uint i = 0; i < mapNominated.length(); i++)
  {

    rtvList.insertLast(mapNominated[i]);

  }
  while (rtvList.length() < 9)
  {

    rMap = RandomMap();

    if (rMap != (rtvList.find(rMap)) )
    {

      rtvList.insertLast(rMap);

    }

  }

  //Give Menus to Vote!
  VoteMenu();

}

void ChooseMap(string chosenMap)
{

  g_EngineFuncs.ServerCommand("changelevel " + chosenMap + "\n");

}

void PostVote()
{

  //Find highest amount of votes
  int highestVotes = 0;
  for (size_t i = 0; i < rtvVotes.getSize(); i++)
  {

    if ( int(rtvVotes[rtvList[i]) >= highestVotes)
    {

      highestVotes = int(rtvVotes[rtvList[i]]);

    }
  }

  //Find how many maps were voted at the highest
  array<string> candidates;
  for (size_t i = 0; i < rtvVotes.getSize(); i++)
  {

    if ( int(rtvVotes[rtvList[i]) == highestVotes)
    {

      candidates.insertLast( rtvList[i] );

    }
  }

  if (candidates.length() > 1)
  {

    //Time to Revote!
    rtvList.resize(candidates.length());

    for (size_t i = 0; i < candidates.length(); i++)
    {

      rtvList[i] = candidates[1];

    }
    @g_TimeToVote = g_Scheduler.SetTimeout("PostVote", 25);
    VoteMenu();

  }
  else
  {

    g_PlayerFuncs.CenterPrintAll("Changing map to \"" + candidates[0] +"\"\n");
    g_Scheduler.SetTimeout("ChooseMap", 5, candidates[0]);

  }

}

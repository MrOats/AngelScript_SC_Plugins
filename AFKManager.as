/*
Copyright (c) 2017 Drake "MrOats" Denston

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

/*
Current Status: Unstable/Under Development, report bugs on forums.
Documentation: https://github.com/MrOats/AngelScript_SC_Plugins/wiki/AFKManager.as
*/

final class AFK_Data
{

  private Vector m_lastOrigin;
  private float m_lastMove;
  private bool m_isSpectate = false;
  private int m_secondsUntilSpec = 0;
  private int m_secondsUntilKick = 0;
  private CBasePlayer@ m_pPlayer;
  private string m_szPlayerName = "";
  private string m_szSteamID = "";

  private CScheduledFunction@ initTimer = null;

  //AFK Data Properties

  Vector lastOrigin
  {
    get const { return m_lastOrigin; }
    set { m_lastOrigin = value; }
  }
  float lastMove
  {
    get const { return m_lastMove; }
    set { m_lastMove = value; }
  }
  bool isSpectate
  {
    get const { return m_isSpectate; }
    set { m_isSpectate = value; }
  }
  int secondsUntilSpec
  {
    get const { return m_secondsUntilSpec; }
    set { m_secondsUntilSpec = value; }
  }
  int secondsUntilKick
  {
    get const { return m_secondsUntilKick; }
    set { m_secondsUntilKick = value; }
  }
  CBasePlayer@ pPlayer
  {
    get const { return m_pPlayer; }
    set { @m_pPlayer = value; }
  }
  string szSteamID
  {
    get const { return m_szSteamID; }
  }
  string szPlayerName
  {
    get const { return m_szPlayerName; }
  }


  //AFK Data Functions

  void ClearInitTimer()
  {

    g_Scheduler.RemoveTimer(@initTimer);
    @initTimer = null;

  }

  void Initiate()
  {

    @initTimer = g_Scheduler.SetInterval(this, "CheckAFK", 1, g_Scheduler.REPEAT_INFINITE_TIMES);

  }

  void UpdateLastOrigin()
  {

    lastOrigin = pPlayer.GetOrigin();

  }

  void UpdateLastMove()
  {

    lastMove = pPlayer.m_flLastMove;

  }

  void KickPlayer()
  {

    if ( g_KickAdmins.GetBool() && (g_PlayerFuncs.AdminLevel(pPlayer) >= ADMIN_YES) )
    {

      g_EngineFuncs.ServerCommand("kicksteamid \"" + szSteamID + "\"\n");
      //g_AdminControl.KickPlayer(pPlayer, 1);

    }
    else
    {

      g_EngineFuncs.ServerCommand("kicksteamid \"" + szSteamID + "\"\n");
      //g_AdminControl.KickPlayer(pPlayer, -1);

    }

  }

  bool HasMoved()
  {

    if ( (pPlayer !is null) && (pPlayer.IsConnected()) )
    {

      if (lastMove == pPlayer.m_flLastMove)
      {

        //Player did not move
        return false;

      }
      else
      {

        //Player moved!
        return true;

      }

    }
    else
      return false;

/*
    if ( (pPlayer !is null) && (pPlayer.IsConnected()) )
    {

      if (lastOrigin.opEquals(pPlayer.GetOrigin()))
      {

        //Player did not move
        return false;

      }
      else
      {

        //Player moved!
        return true;

      }

    }
    else return false;
*/

  }

  void CheckAFK()
  {

    if ( (pPlayer !is null) && (pPlayer.IsConnected()) )
    {

      if (!HasMoved())
      {

        //Player is AFK!

        //If Spectate is Enabled, then move to Spectate First

        if (g_ShouldSpec.GetBool())
        {

          //We should warn player every few seconds about their AFK Status
          if ( ((secondsUntilSpec % g_WarnInterval.GetInt()) == 0) && !isSpectate && (secondsUntilSpec != g_SecondsUntilSpec.GetInt()) )
          {

            MessageWarnPlayer(pPlayer, string(secondsUntilSpec) + " seconds until you are moved to Specate for being AFK.");

          }

          if ( ((secondsUntilKick % g_WarnInterval.GetInt()) == 0) && isSpectate && (secondsUntilKick != g_SecondsUntilKick.GetInt()) && g_ShouldKick.GetBool())
          {

            MessageWarnPlayer(pPlayer, "Move around a bit if you want to get out of Specate.");
            MessageWarnPlayer(pPlayer, string(secondsUntilKick) + " seconds until you are kicked for being AFK.");

          }

          //If AFK for X seconds, move to spectate if they aren't already.
          if ( (secondsUntilSpec <= 0) && !isSpectate)
          {

            MoveToSpectate();
            MessageWarnAllPlayers(pPlayer, (szPlayerName + " has been moved to spectate for being AFK."));

          }
          //If AFK for X seconds, kick them if they have been spectating, if config allows
          else if ( (secondsUntilKick <= 0) && isSpectate && g_ShouldKick.GetBool() )
          {

            MessageWarnAllPlayers(pPlayer, (szPlayerName) + " has been kicked for being AFK.");
            KickPlayer();

          }
          //Otherwise, decrease their count(s) until AFK action
          else
          {

            secondsUntilSpec -= 1;

            if (g_ShouldKick.GetBool())
            {

              if ( g_KickAdmins.GetBool() && (g_PlayerFuncs.AdminLevel(pPlayer) >= ADMIN_YES) && isSpectate)
              {

                secondsUntilKick -= 1;

              }
              else if (isSpectate)
              {

                secondsUntilKick -= 1;

              }

            }

            UpdateLastMove();

          }

        }
        else /* If no Spectate, then assume kick only */
        {

          //Again warn players, see above
          if ( ((secondsUntilKick % g_WarnInterval.GetInt()) == 0))
          {

            MessageWarnPlayer(pPlayer, string(secondsUntilKick) + " seconds until you are kicked for being AFK.");

          }

          //Kick player if AFK after X seconds
          if ( secondsUntilKick <= 0)
          {

            MessageWarnAllPlayers(pPlayer, (szPlayerName) + " has been kicked for being AFK.");
            KickPlayer();

          }
          //Otherwise decrease count
          else
          {

            if ( g_KickAdmins.GetBool() && (g_PlayerFuncs.AdminLevel(pPlayer) >= ADMIN_YES) )
            {

              secondsUntilKick -= 1;

            }
            else secondsUntilKick -= 1;

            UpdateLastMove();

          }

        }

      }
      else
      {

        //Player is not AFK!

        if (g_ShouldSpec.GetBool())
        {

          secondsUntilSpec = g_SecondsUntilSpec.GetInt();

        }
        if (g_ShouldKick.GetBool())
        {

          secondsUntilKick = g_SecondsUntilKick.GetInt();

        }

        //Get them out of Spectate because they are not AFK!
        if (isSpectate)
        {

          MessageWarnPlayer(pPlayer, "Moving you back to the game through respawn...");
          isSpectate = false;
          g_PlayerFuncs.RespawnPlayer(pPlayer, true, true);
          g_AdminControl.KillPlayer(pPlayer, 0); /* Set to 0 because we don't want to add onto mp_respawndelay */

        }

        UpdateLastMove();

      }

    }

  }

  void MoveToSpectate()
  {

    isSpectate = true;
    pPlayer.GetObserver().StartObserver( pPlayer.GetOrigin(), pPlayer.pev.angles, false );
    g_Scheduler.SetTimeout("SetRespawnTime", .75f, @pPlayer);

  }

  //Constructor

  AFK_Data(CBasePlayer@ pPlr)
  {

    @m_pPlayer = pPlr;
    m_szSteamID = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
    m_szPlayerName = pPlayer.pev.netname;
    //lastOrigin = pPlayer.GetOrigin();
    m_lastMove = pPlayer.m_flLastMove;
    m_secondsUntilSpec = g_SecondsUntilSpec.GetInt();
    m_secondsUntilKick = g_SecondsUntilKick.GetInt();

  }

  //Adding a default constructor for the SetInterval @ Initiate();
  AFK_Data()
  {


  }

}

//Global Vars

array<AFK_Data@> afk_plr_data;

CCVar@ g_ShouldSpec;
CCVar@ g_SecondsUntilSpec;
CCVar@ g_ShouldKick;
CCVar@ g_SecondsUntilKick;
CCVar@ g_KickAdmins;
CCVar@ g_WarnInterval;

//Begin!

void PluginInit()
{

  g_Module.ScriptInfo.SetAuthor("MrOats");
  g_Module.ScriptInfo.SetContactInfo("http://forums.svencoop.com/showthread.php/44666-Plugin-AFK-Manager");
  g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @AddPlayer);
  g_Hooks.RegisterHook(Hooks::Player::PlayerSpawn, @CheckSpectate);
  g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect, @DisconnectCleanUp);
  g_Hooks.RegisterHook(Hooks::Game::MapChange, @ResetVars);

  @g_ShouldSpec = CCVar("bShouldSpec", true, "Should player be moved to spectate for being AFK?", ConCommandFlag::AdminOnly);
  @g_SecondsUntilSpec = CCVar("secondsUntilSpec", 180, "Seconds until player should be moved to Spectate for being AFK", ConCommandFlag::AdminOnly);
  @g_ShouldKick = CCVar("bShouldKick", true, "Should player be kicked for being AFK?", ConCommandFlag::AdminOnly);
  @g_SecondsUntilKick = CCVar("secondsUntilKick", 600, "Seconds until player ", ConCommandFlag::AdminOnly);
  @g_KickAdmins = CCVar("bKickAdmins", true, "Should admins/owners be kicked for being AFK?", ConCommandFlag::AdminOnly);
  @g_WarnInterval = CCVar("secondsWarnInterval", 30, "How many seconds should lapse until player is warned that AFK action will be taken", ConCommandFlag::AdminOnly);

}

void MapActivate()
{

  afk_plr_data.resize(g_Engine.maxClients);
  for (uint i = 0; i < afk_plr_data.length(); i++)
  {
    @afk_plr_data[i] = null;
  }

}

HookReturnCode AddPlayer(CBasePlayer@ pPlayer)
{

  if (g_ShouldSpec.GetBool() || g_ShouldKick.GetBool())
  {

    AFK_Data@ afkdataobj = AFK_Data(pPlayer);
    @afk_plr_data[pPlayer.entindex() - 1] = @afkdataobj;

    //afkdataobj.UpdateLastMove();
    afkdataobj.Initiate();

    return HOOK_HANDLED;

  }
  else
  {

    g_Game.AlertMessage(at_logged, "AFK Manager disabled due to both functions being turned off.\n");
    return HOOK_HANDLED;

  }


}

HookReturnCode CheckSpectate(CBasePlayer@ pPlayer)
{

  AFK_Data@ afkdataobj = @afk_plr_data[pPlayer.entindex() - 1];

  if (afkdataobj !is null && pPlayer.IsConnected())
  {

    if (afkdataobj.isSpectate)
    {

      afkdataobj.MoveToSpectate();
      return HOOK_HANDLED;

    }
    else
      return HOOK_HANDLED;

  }
  else
    return HOOK_HANDLED;

}

HookReturnCode DisconnectCleanUp(CBasePlayer@ pPlayer)
{

  AFK_Data@ afkdataobj = @afk_plr_data[pPlayer.entindex() - 1];
  afkdataobj.ClearInitTimer();
  @afkdataobj = null;

  return HOOK_HANDLED;

}

HookReturnCode ResetVars()
{

  for (uint i = 0; i < afk_plr_data.length(); i++)
  {

    afk_plr_data[i].ClearInitTimer();

  }

  return HOOK_HANDLED;

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

  g_PlayerFuncs.SayText(pPlayer, "[AFKM] " + msg + "\n");

}

void MessageWarnAllPlayers(CBasePlayer@ pPlayer, string msg)
{

  g_PlayerFuncs.SayTextAll(pPlayer, "[AFKM] " + msg + "\n");

}

void SetRespawnTime(CBasePlayer@ pPlayer)
{

  pPlayer.m_flRespawnDelayTime = Math.FLOAT_MAX;
  return;

}

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
  private bool m_isSpectate = false;
  private bool m_specTimerOn = false;
  private bool m_kickTimerOn = false;
  private CBasePlayer@ m_pPlayer;
  private string m_szPlayerName = "";
  private string m_szSteamID = "";

  private CScheduledFunction@ specTimer = null;
  private CScheduledFunction@ kickTimer = null;
  private CScheduledFunction@ initTimer = null;

  //RTV Data Properties

  Vector lastOrigin
  {
    get const { return m_lastOrigin; }
    set { m_lastOrigin = value; }
  }
  bool isSpectate
  {
    get const { return m_isSpectate; }
    set { m_isSpectate = value; }
  }
  bool specTimerOn
  {
    get const { return m_specTimerOn; }
    set { m_specTimerOn = value; }
  }
  bool kickTimerOn
  {
    get const { return m_kickTimerOn; }
    set { m_kickTimerOn = value; }
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

  void ClearSpecTimer()
  {

    g_Scheduler.RemoveTimer(@specTimer);
    @specTimer = null;
    specTimerOn = false;

  }

  void ClearKickTimer()
  {

    g_Scheduler.RemoveTimer(@kickTimer);
    @kickTimer = null;
    kickTimerOn = false;

  }

  void ClearInitTimer()
  {

    g_Scheduler.RemoveTimer(@initTimer);
    @initTimer = null;

  }

  void ClearAllTimers()
  {

    g_Scheduler.RemoveTimer(@specTimer);
    @specTimer = null;
    specTimerOn = false;
    g_Scheduler.RemoveTimer(@kickTimer);
    @kickTimer = null;
    kickTimerOn = false;
    g_Scheduler.RemoveTimer(@initTimer);
    @initTimer = null;

  }

  void Initiate()
  {

    @initTimer = g_Scheduler.SetTimeout(this, "CheckAFK", 5);

  }

  void BeginSpecTimer()
  {

    @specTimer = g_Scheduler.SetTimeout(this, "CheckAFK", g_SecondsUntilSpec.GetFloat());
    specTimerOn = true;
    MessageWarnPlayer(pPlayer, string("You have " + g_SecondsUntilSpec.GetInt() + " seconds before you are moved to spectate") );

  }

  void BeginKickTimer()
  {

    @kickTimer = g_Scheduler.SetTimeout(this, "CheckAFK", g_SecondsUntilKick.GetFloat());
    kickTimerOn = true;
    MessageWarnPlayer(pPlayer, string("You have " + g_SecondsUntilSpec.GetInt() + " seconds before you are kicked") );

  }

  void UpdateLastOrigin()
  {

    lastOrigin = pPlayer.GetOrigin();

  }

  bool HasMoved()
  {

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

  }

  void HasMovedSinceSpec()
  {

    if (isSpectate && HasMoved())
    {

      MessageWarnPlayer(pPlayer, "Moving you back to the game through respawn...");
      g_PlayerFuncs.RespawnPlayer(pPlayer, true, true);
      g_AdminControl.KillPlayer(pPlayer, 3);
      isSpectate = false;
      ClearAllTimers();
      Initiate();

    }

  }

  void CheckAFK()
  {

    if ( (pPlayer !is null) && (pPlayer.IsConnected()) )
    {

      if (!HasMoved())
      {

        //Player is AFK!

        //If Spectate is Enabled, then move to Spectate First
        MessageWarnPlayer(pPlayer, "Before SpecTimer is: " + string(specTimerOn));

        if (g_ShouldSpec.GetBool())
        {

          if (!specTimerOn && !kickTimerOn)
          {

            ClearInitTimer();
            BeginSpecTimer();
            UpdateLastOrigin();
            MessageWarnPlayer(pPlayer, "SpecTimer is: " + string(specTimerOn));
            //g_Scheduler.SetInterval("HasMovedSinceSpec", );

          }
          else if (specTimerOn && !kickTimerOn)
          {

            MoveToSpectate();
            MessageWarnPlayer(pPlayer, "SpecTimer2 is: " + string(specTimerOn));
            ClearSpecTimer();
            UpdateLastOrigin();

            if (g_ShouldKick.GetBool())
            {

              BeginKickTimer();

            }

          }
          else if (!specTimerOn && kickTimerOn)
          {

            //Time to kick player
            g_AdminControl.KickPlayer(pPlayer, -1);
            g_PlayerFuncs.SayTextAll(pPlayer, "[AFKM] " + szPlayerName + " has been kicked for being AFK." + "\n" );

          }
          else
          {

            MessageWarnPlayer(pPlayer, "Uh... we shouldn't be here.");
            ClearAllTimers();
            Initiate();

          }

        }
        else /* If no Spectate, then assume kick only */
        {

          if (!kickTimerOn)
          {

            BeginKickTimer();
            ClearInitTimer();
            UpdateLastOrigin();

          }
          else
          {

            //Time to kick player
            g_AdminControl.KickPlayer(pPlayer, -1);
            g_PlayerFuncs.SayTextAll(pPlayer, "[AFKM] " + szPlayerName + " has been kicked for being AFK." + "\n" );

          }

        }

      }
      else
      {

        //Player is not AFK!
        ClearAllTimers();
        UpdateLastOrigin();
        if (isSpectate)
        {

          MessageWarnPlayer(pPlayer, "Moving you back to the game through respawn...");
          g_PlayerFuncs.RespawnPlayer(pPlayer, true, true);
          g_AdminControl.KillPlayer(pPlayer, 3);

        }

        @initTimer = g_Scheduler.SetTimeout(this, "CheckAFK", 5);

      }

    }

  }

  void MoveToSpectate()
  {

    isSpectate = true;
    pPlayer.GetObserver().StartObserver( pPlayer.pev.origin, pPlayer.pev.angles, false );
    g_Scheduler.SetTimeout("SetRespawnTime", .75f, @pPlayer);

  }

  //Constructor

  AFK_Data(CBasePlayer@ pPlr)
  {

    @m_pPlayer = pPlr;
    m_szSteamID = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
    m_szPlayerName = pPlayer.pev.netname;
    lastOrigin = pPlayer.GetOrigin();

  }
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


//Begin!

void PluginInit()
{

  g_Module.ScriptInfo.SetAuthor("MrOats");
  g_Module.ScriptInfo.SetContactInfo("http://forums.svencoop.com/showthread.php/44609-Plugin-RockTheVote");
  g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @AddPlayer);
  g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect, @DisconnectCleanUp);
  g_Hooks.RegisterHook(Hooks::Game::MapChange,@ResetVars);

  @g_ShouldSpec = CCVar("bShouldSpec", true, "Should player be moved to spectate for being AFK?", ConCommandFlag::AdminOnly);
  @g_SecondsUntilSpec = CCVar("secondsUntilSpec", 30, "Seconds until player should be moved to Spectate for being AFK", ConCommandFlag::AdminOnly);
  @g_ShouldKick = CCVar("bShouldKick", true, "Should player be kicked for being AFK?", ConCommandFlag::AdminOnly);
  @g_SecondsUntilKick = CCVar("secondsUntilKick", 90, "Seconds until player ", ConCommandFlag::AdminOnly);

}

void MapActivate()
{

  afk_plr_data.resize(g_Engine.maxClients);
  for (size_t i = 0; i < afk_plr_data.length(); i++)
  {
    @afk_plr_data[i] = null;
  }

}

HookReturnCode AddPlayer(CBasePlayer@ pPlayer)
{

  AFK_Data@ afkdataobj = AFK_Data(pPlayer);
  @afk_plr_data[pPlayer.entindex() - 1] = @afkdataobj;

  afkdataobj.Initiate();

  return HOOK_HANDLED;

}

HookReturnCode DisconnectCleanUp(CBasePlayer@ pPlayer)
{

  AFK_Data@ afkdataobj = @afk_plr_data[pPlayer.entindex() - 1];
  afkdataobj.ClearAllTimers();
  @afkdataobj = null;

  return HOOK_HANDLED;

}

HookReturnCode ResetVars()
{

  for (size_t i = 0; i < afk_plr_data.length(); i++)
  {

    afk_plr_data[i].ClearAllTimers();

  }

  return HOOK_HANDLED;

}

void MessageWarnPlayer(CBasePlayer@ pPlayer, string msg)
{

  g_PlayerFuncs.SayText( pPlayer, "[AFKM] " + msg + "\n");

}

void SetRespawnTime(CBasePlayer@ pPlayer)
{

  pPlayer.m_flRespawnDelayTime = Math.FLOAT_MAX;
  return;

}

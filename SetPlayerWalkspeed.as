/*
Copyright (c) 2016 Drake "MrOats" Denston

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

CClientCommand setspeed( "setspeed", ".setspeed name speed", @setspeed, ConCommandFlag::AdminOnly);

void PluginInit()
{

  g_Module.ScriptInfo.SetAuthor("MrOats");
  g_Module.ScriptInfo.SetContactInfo("Discord ID: #3419");

}

void setspeed(const CCommand@ pArguments)
{

  CBasePlayer@ pPlayer=pPlayer.FindPlayerByName(pArguments.Arg(2));
  pPlayer.pev.maxspeed=pArguments.Arg(3);
  g_PlayerFuncs.SayText(pPlayer,"Your speed has been set to: "+pPlayer.pev.maxspeed+"\n");

}

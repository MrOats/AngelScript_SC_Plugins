/*
Copyright (c) 2016 Drake "MrOats" Denston

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

/*
Current status: In Development, will not work at the moment.
Desc: Helper class for creating Chat commands from your console commands.
Documentation:
Create a new object with your console command object as a parameter:
  chatCommand chat_MyCommand=new chatCommand(CConCommand@ MyCommand);
Chat Triggers should be created then, I hope idk, I'm working on this part haha.
*/
private string m_szConCMD;
private string m_szPubPrefix;
private string m_szPrivPrefix;
private string m_szPubTrigger;
private string m_szPrivTrigger;
class chatCommand{
  chatCommand(CConCommand@ ConCMD){

    m_szConCMD=ConCMD.GetCommandString();
    m_szPubPrefix="!";
    m_szPrivPrefix="/";

  }
void CreateTrigger(string szConCMD[0],string szPubPrefix,string szPrivPrefix){
  m_szPubTrigger=m_szPubPrefix+szConCMD;
  m_szPrivTrigger=m_szPrivPrefix+szConCMD;
  }
}
bool isSilent(){
  if()
  return true;
  else return false;
}

HookReturnCode PlayerSay(SayParameters@ pParams){
  const CCommand@ pArguments=pParams.GetArguments;

}

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
namespace ChatTriggers{
final class chatCommand{
  private string m_szConCMD;
  private string m_szPubPrefix="!";
  private string m_szPrivPrefix="/";
  private string m_szPubTrigger;
  private string m_szPrivTrigger;
  private int m_adminOnly=0;
  private string m_szFuncName

//Properties
  string szConCMD
  {
    get const {return m_szConCMD;}
    set {m_szConCMD=value;}
  }
  string szPubPrefix
  {
    get const {return m_szPubPrefix;}
    set {m_szPubPrefix=value;}
  }
  string szPrivPrefix
  {
    get const {return m_szPrivPrefix;}
    set {m_szPrivPrefix=value;}
  }
  string szPubTrigger
  {
    get const {return m_szPubTrigger;}
    set {m_szPubTrigger=value;}
  }
  string szPrivTrigger
  {
    get const {return m_szPrivTrigger;}
    set {m_szPrivTrigger=value;}
  }
  int adminLevel
  {
    get const {return m_adminOnly;}
    set {m_adminOnly=value;}
  }
  string szFuncName
  {
    get const {return m_szFuncName;}
    set {m_szFuncName=value;}
  }

//Functions
  chatCommand(CClientCommand@ ConCMD, string str_FuncName, int i_adminLevel){
      str_szConCMD=ConCMD.GetName();
      adminLevel=i_adminLevel;
      szFuncName=str_FuncName;
      CreateTrigger(str_szConCMD);
    }
    
  void CreateTrigger(string szConCMD){
    szPubTrigger=szPubPrefix+szConCMD;
    szPrivTrigger=szPrivPrefix+szConCMD;
    }
  }

  SetPrivatePrefix(string setPriv){
    szPrivPrefix=
  }

  bool isSilent(string szPrivString){
    if(szPrivString[0]=="/");
    return true;
    else return false;
  }

HookReturnCode PlayerSay(SayParameters@ pParams){
  const CCommand@ pArguments=pParams.GetArguments;

}
}

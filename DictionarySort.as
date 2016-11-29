dictionary mydict={
  {"map1",15},
  {"map2",14},
  {"map3",30},
  {"map4",20}
};
CClientCommand sortDict( "sortDict", "Dictionary sort test", @DoTheThing );


void PluginInit(){
  g_Module.ScriptInfo.SetAuthor("MrOats");
  g_Module.ScriptInfo.SetContactInfo("N/A");
}


void DoTheThing(const CCommand@ args){
  dictionary meh=PostVote(mydict);
  array<string> mehkeys=meh.getKeys();
  g_PlayerFuncs.ShowMessageAll(""+int(mydict["map1"]));
}


dictionary PostVote(dictionary votedmaps){
  uint length=votedmaps.getSize();
  array<int> myvalues(length);
  array<int> sortedvalues(length);
  array<string> mykeys=votedmaps.getKeys();

  //Fill array of keys with dictionary keys
  for (uint i = 0; i < length; i++) {
    myvalues[i]=int(votedmaps[mykeys[i]]);
  }

  //Organize mykeys to match order of Dictionary
  /*for (uint i = 0; i < length; i++) {
    if () {

    }
  }*/

  sortedvalues=myvalues;
  sortedvalues.sortDesc();

  //Begin sorting
  for (uint i = 0; i < myvalues.length(); i++){
    for (uint x = 0; x < length; x++){
      if (int(votedmaps[mykeys[i]])==myvalues[x]) {
        votedmaps.set(mykeys[i],sortedvalues[x]);
        myvalues.removeAt(x);
        length--;
      }
    }
  }
  return votedmaps;
}

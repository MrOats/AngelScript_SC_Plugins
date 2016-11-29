dictionary mydict={{"map1",2},{"map2",3},{"map3",10}};
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
  for (uint i = 0; i < length; i++) {
    myvalues[i]=int(votedmaps[mykeys[i]]);
  }
  sortedvalues=myvalues;
  sortedvalues.sortDesc();
  for (uint i = 0; i < myvalues.length(); i++){
    for (uint x = 0; x < length; x++){
      if (int(mydict[mykeys[i]])==myvalues[x]) {
        mydict.set(mykeys[i],sortedvalues[x]);
        myvalues.removeAt(x);
        length--;
      }
    }
  }
  return votedmaps;
}

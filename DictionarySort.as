dictionary mydict;
mydict.set("map1",5);
mydict.set("map2",3);
mydict.set("map3",10);
CClientCommand sortDict( "sortDict", "Dictionary sort test", @DoTheThing );
void PluginInit(){
  g_Module.ScriptInfo.SetAuthor("MrOats");
  g_Module.ScriptInfo.SetContactInfo("N/A");
}
void DoTheThing(){
  dictionary meh=PostVote(mydict);
  array<string> mehkeys=meh.getKeys();
  ShowMessageAll(mehkeys[0]);
}
dictionary PostVote(dictionary votedmaps){
  uint length=votedmaps.GetSize();
  array<int> myvalues(length);
  array<string> mykeys=votedmaps.getKeys();
  array<int> sortedvalues(length);
  for (uint i = 0; i < length; i++) {
    myvalues[i]=int(votedmaps[mykeys[i]]);
  }
  sortedvalues=myvalues.sortDesc();
  for (uint i = 0; i < myvalues.length(); i++)
    for (uint x = 0; x < length; x++)
      if (int(mydict[mykeys[i]])==myvalues[x]) {
        mydict.set(mykeys[i],myvalues[x]);
        myvalues.removeAt(x);
        length--;
      }
  return votedmaps;
}

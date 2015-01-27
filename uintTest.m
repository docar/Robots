clc
clear all
path(path, [cd '\rules']);
path(path, [cd '\tasks']);
TimeFrames = [1 5 10 15 30 60];

TimeIntervalIn =  {'01-Jan-2009' '31-Dec-2014'};
mo = marketData('RTS',TimeIntervalIn);  
CurrentObject = positionParent.loadFromFile('long_trend2.xlsx');

mo2 = mo.castData;
 tic
 d = CurrentObject.getFinalState(mo2);
  statistics(d)
  toc
  
   tic
 t = CurrentObject.getFinalState(mo);
  statistics(t)
  toc

 tic
m = CurrentObject.getFinalState(mo2);
  statistics(m)
  toc
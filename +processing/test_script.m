path(path, [cd '\rules']); 
path(path, [cd '\tasks']);
TimeIntervalReal =  {'01-Jan-2014' '31-Dec-2014'};
res = processing.evalOutSel(obj);
res = res.evalOutSelScores({'01-Jan-2009' '31-Dec -2012'});
res = res.selectPositions;
res = res.evalRealTime(TimeIntervalReal);
res.plotSelPositions;

clear all
path(path, [cd '\rules']);

s = positionParent.loadFromFile('marketStructure.xlsx');
TimeInterval =  {'01-Jan-2012' '31-Feb-2012'};
tic
res = s.getFinalState(TimeInterval);
toc
statistics(res)
figure
plot(res.FinalState.ProfitVector)
% tic
% Market = marketData('RTSI', TimeInterval );
% toc
% 
% tic
% Market2 = marketData2('RTS', TimeInterval );
% toc
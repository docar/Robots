obj.ProfitPlot = figure;
obj.ResultsPlot = figure;
figure(obj.ResultsPlot)
plot(obj.History.TestedGensScores, 'blueo')
f = @(obj2, event_obj)plotOutSelectionResults(obj2,event_obj, obj);
dcm_obj = datacursormode(obj.ResultsPlot);
set(dcm_obj, 'Enable', 'on','SnapToDataVertex','off', 'UpdateFcn', f)

figure
hold on
for i = 1:100
    CurrentObject = positionParent.createObject(...
    obj.getStructure(obj.History.TestedGens(i,:)));
Market = getMarkets(obj, 'InSelection');
CurrentObject = CurrentObject.getFinalState(Market);
plot(CurrentObject.FinalState.ProfitVector, '-r')
end
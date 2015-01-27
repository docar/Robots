function output_txt = plotResults(~, event_obj, obj)
% Display the position of the data cursor
% obj          Currently not used (empty)
% event_obj    Handle to event object
% output_txt   Data cursor text string (string or cell array of strings).
pos = get(event_obj,'Position');
output_txt = {['X: ',num2str(pos(1),4)],...
    ['Y: ',num2str(pos(2),4)]};
% If there is a Z-coordinate in the position, display it as well
if length(pos) > 2
    output_txt{end+1} = ['Z: ',num2str(pos(3),4)];
end
[~, Indexes] = sort(obj.History.BestScoresInSelection);
CurrentObject = positionParent.createObject(...
    obj.getStructure(obj.History.BestIndividualsInSelection(Indexes(pos(1)),:)));
figure(obj.ProfitPlot)
clf
plot(obj.History.BestOutSelectionStates{Indexes(pos(1))}.ProfitVector, '-g')
hold on
Markets = getMarkets(obj, 'InSelection');
CurrentObject = CurrentObject.getFinalState(Markets);
plot(CurrentObject.FinalState.ProfitVector, '-r')
legend('OutSelectionProfit','InSelectionProfit')
end

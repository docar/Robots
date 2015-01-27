function output_txt = plotSelPositions(~, event_obj, obj)
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

plotSelection(obj, pos, 'InSelection', obj.ProfitPlotIn)
plotSelection(obj, pos,  'OutSelection', obj.ProfitPlotOut)

    function plotSelection(obj, pos, Selection, plotHandle)
        CurrentObject = positionParent.createObject(...
            obj.OptTaskObj.getStructure(obj.SelGens(pos(1),:)));
        Market = getMarkets(obj.OptTaskObj, Selection);
        CurrentObject = CurrentObject.getFinalState(Market);
        nRules = length(CurrentObject.Fields);
        
        %
        
        %%Plot profit vector, active openings and closings
        
        clf(plotHandle)
        set(0,'CurrentFigure',plotHandle)
        %
        subplot(nRules,2,[1 nRules*2 - 1]);
        Prices = double(CurrentObject.Market.DataBase{1}.prices);
        plotyy(1:length(Prices),Prices(:,4),1:length(Prices),CurrentObject.FinalState.ProfitVector)
        hold on
        Markers = Prices(CurrentObject.FinalState.ActiveOpenings, 4);
        plot(CurrentObject.FinalState.ActiveOpenings, Markers, 'go','MarkerFaceColor', 'g', 'MarkerSize',5)
        Markers = Prices(CurrentObject.FinalState.ActiveClosings, 4);
        plot(CurrentObject.FinalState.ActiveClosings, Markers, 'ro','MarkerFaceColor', 'r', 'MarkerSize',5)
        legend(strrep(obj.OptTaskObj.TaskName, '_', ' '),'Location','NorthWest')
        
        %%Plot enters
        Enters = find(strcmp(CurrentObject.ObjectStructure.RuleType, 'Enter') == 1);
        for i = 1:length(Enters)
            subplot(nRules,2,Enters(i)*2);
            plotObj = CurrentObject.Fields{Enters(i)};
            if isa(plotObj, 'boll')
                plotMAIndicator(plotObj, 'g')
            else
                plotOSIndicator(plotObj, 'g')
            end
        end
        
        
        %%Plot exits
        Exits = find(strcmp(CurrentObject.ObjectStructure.RuleType, 'Exit') == 1);
        for i = 1:length(Exits)
            subplot(nRules,2,Exits(i)*2);
            plotObj = CurrentObject.Fields{Exits(i)};
            if isa(plotObj, 'boll')
                plotMAIndicator(plotObj, 'r')
            else
                plotOSIndicator(plotObj, 'r')
            end
        end
    end
    function plotMAIndicator(plotObj, color)
        Prices = double(plotObj.Market.DataBase{plotObj.TimeFrame}.prices);
        candle(Prices(:,2), Prices(:,3), Prices(:,4), Prices(:,1))
        hold on
        plot(plotObj.Indicator, ['-' color],'LineWidth',2)
        Markers = Prices(plotObj.RuleActiveBarsRaw, 4);
        plot(plotObj.RuleActiveBarsRaw, Markers, [color 'o'],'MarkerFaceColor', color, 'MarkerSize',5)
    end

    function plotOSIndicator(plotObj, color)
        RuleParameters = str2num(cell2mat(plotObj.ObjectStructure.RuleParameters));
        Prices = double(plotObj.Market.DataBase{plotObj.TimeFrame}.prices);
        [ax,hlines1,hlines2] = plotyy(1:length(Prices), Prices(:,4), 1:length(Prices),plotObj.Indicator);
        hold on
        Markers = Prices(plotObj.RuleActiveBarsRaw, 4);
        plot(plotObj.RuleActiveBarsRaw, Markers, [color 'o'],'MarkerFaceColor', color, 'MarkerSize',5)
        
        %         gca = ax(2);
        %         plot(1:length(Prices), RuleParameters(end-2), '-ro','LineWidth',2)
    end

end

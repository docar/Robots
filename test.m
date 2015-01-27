% obj.testSyntheticMarket('OutSelection')
% obj.testSyntheticMarket('InSelection')
 %clear all
 
 clc
 clear all
 
%   res = marketData('RTS', {'01-Jan-2013' '31-Jan-2013'});
%  Content = position.loadFile('SystemInvariants.xlsx');
%  TimeFrame = Content(2:end,strcmp(Content(1,:), 'TimeFrame'));
%  TimeFrame = cell2mat(TimeFrame(cellfun(@(x) ~isempty(x) , Content(2:end,strcmp(Content(1,:), 'TimeFrame')))));
path(path, [cd '\rules']);
path(path, [cd '\tasks']);
  TimeIntervalIn =  {'01-Jan-2013' '31-Dec-2013'};
 CurrentObject = positionParent.loadFromFile('short_trend.xlsx');
 t = CurrentObject.getFinalState(TimeIntervalIn);
  statistics(t)
  
  
  
% % figure
% % plot(t.Market.DataBase{1, 1}.prices(:,1))
%   figure
%   plot(t.FinalState.ProfitVector)
% hold on
% plot(t.Fields{1}.FinalState.ProfitVector, 'g')
% plot(t.Fields{2}.FinalState.ProfitVector, 'r')
% plot(t.Fields{3}.FinalState.ProfitVector, '-black')
% plot(t.Fields{4}.FinalState.ProfitVector, 'm')
% 
% hold off
% for i = 1:10
%     disp(i)
% 
%     synthData = syntheticData(t.Market);
% 
%     d = CurrentObject.getFinalState(synthData.MarketObject);
%     statistics(d)
%     figure
%     plot(d.FinalState.ProfitVector)
%      figure
%      plot(d.Market.DataBase{1, 1}.prices(:,1))
% end
%     prr(i) = statistics(d).ProfitRiskRatio;
%     nerpr(i) = statistics(d).NetProfit;
%     obj{i} = d;
    % figure
    % plot(d.Market.DataBase{1, 1}.prices(:,1))
    % figure
    % plot(d.FinalState.ProfitVector)
    % hold on
    
    % plot(d.Fields{1}.FinalState.ProfitVector, 'g')
    % plot(d.Fields{2}.FinalState.ProfitVector, 'r')
    % plot(d.Fields{3}.FinalState.ProfitVector, '-black')
    % plot(d.Fields{4}.FinalState.ProfitVector, 'm')
% end
% plotyy(1:length(t.FinalState.ProfitVector),...
%     t.Market.DataBase{1}.prices(:,4),...
%     1:length(t.FinalState.ProfitVector),...
%     t.FinalState.ProfitVector)
%
%  hold on
%  for i=1:10
%      tic
%      synthData = syntheticData(t.Market);
%      d = CurrentObject.getFinalState(synthData.MarketObject);
%      statistics(d)
% % % %     plotyy(1:length(t.FinalState.ProfitVector),...
% % % %     t.Market.DataBase{1}.prices(:,4),...
% % % %     1:length(t.FinalState.ProfitVector),...
% % % %     t.FinalState.ProfitVector)
%      plot(d.FinalState.ProfitVector, '-r')
% %      plot(synthData.MarketObject.DataBase{1, 1}.prices(:,1), '-r')
%      toc
%  end
% figure
% prices = t.Fields(1).Market.DataBase{t.Fields(1).TimeFrame}.prices;
%
% candle(prices(:,2), prices(:,3), prices(:,4), prices(:,1))
% hold on
% plot(t.Fields(1).Indicator, '-r')
% plot(t.FinalState.ActiveOpenings, t.FinalState.OpeningPrices, 'go',...
%                 'MarkerEdgeColor','k',...
%                 'MarkerFaceColor','g',...
%                 'MarkerSize',10);
% plot(t.FinalState.ActiveClosings, t.FinalState.ClosingPrices, 'ro',...
%                 'MarkerEdgeColor','k',...
%                 'MarkerFaceColor','r',...
%                 'MarkerSize',10);


% figure
% prices = t.Fields(2).Market.DataBase{t.Fields(2).TimeFrame}.prices;
% candle(prices(:,2), prices(:,3), prices(:,4), prices(:,1))
% hold on
% plot(t.Fields(2).Indicator, '-r')


%   plot(t.Fields(1).FinalState.ProfitVector, '-r')
%   plot(t.Fields(2).FinalState.ProfitVector, '-g')
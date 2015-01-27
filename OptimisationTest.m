%%
clc
clear all
path(path, [cd '\rules']); 
path(path, [cd '\tasks']);

TimeIntervalIn =  {'01-Jan-2013' '31-Dec-2013'};
TimeIntervalOut =  {'01-Jan-2013' '31-Dec-2013'};

obj = optimisationTask('RTS_short_counter_optimisation.xlsx', TimeIntervalIn, 'ProfitRiskRatio');
%%
clc
clear all
path(path, [cd '\rules']); 
path(path, [cd '\tasks']);

TimeIntervalIn =  {'01-Jan-2012' '31-Dec-2012'};
TimeIntervalOut =  {'01-Jan-2013' '31-Dec -2013'};

obj = optimisationTask('RTS_filter_long_counter_optimisation.xlsx', TimeIntervalIn, 'ProfitRiskRatio');
%%
clc
clear all
path(path, [cd '\rules']); 
path(path, [cd '\tasks']);

TimeIntervalIn =  {'01-Jan-2012' '31-Dec-2012'};
TimeIntervalOut =  {'01-Jan-2013' '31-Dec -2013'};

obj = optimisationTask('RTS_filter_long_trend_optimisation.xlsx', TimeIntervalIn, 'ProfitRiskRatio');
%%
clc
clear all
path(path, [cd '\rules']); 
path(path, [cd '\tasks']);

TimeIntervalIn =  {'01-Jan-2012' '31-Dec-2012'};
TimeIntervalOut =  {'01-Jan-2013' '31-Dec -2013'};

obj = optimisationTask('RTS_filter_short_trend_optimisation.xlsx', TimeIntervalIn,'ProfitRiskRatio');
%%

% pause(60)
% clear obj
% obj = optimisationTask('boll_long_trend_optimisation.xlsx', TimeIntervalIn, TimeIntervalOut,'ProfitFactor');
% pause(60)
% clear obj
% obj = optimisationTask('boll_long_trend_optimisation.xlsx', TimeIntervalIn, TimeIntervalOut,'ProfitRiskRatio');
% pause(60)
% clear obj
% obj = optimisationTask('boll_short_trend_optimisation.xlsx', TimeIntervalIn, TimeIntervalOut,'ProfitRiskRatio');



 
 
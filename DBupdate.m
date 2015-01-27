DataBase.DBMaster;
UpdateTimes = DataBase.readSetup('UpdateTimes');

for i=1:length(UpdateTimes)
    Timer{i} = timer('TimerFcn',@DataBase.DBupdate_caller,...
        'Period', 60*60*24, 'ExecutionMode', 'fixedDelay',...
        'TasksToExecute', 1e8);
    try
        startat(Timer{i}, UpdateTimes{i});
    catch
        startat(Timer{i}, [datestr(now+1,...
            'dd-mmm-yyyy ') UpdateTimes{i}]);
    end
end

wait([Timer{:}])
%Class defines format of market data objects

%input parameters: 
%varargin{1} - name of market (string);
%varargin{2} - dates of sample begin and end (cell) 
% format {'DD-MMM-YYYY','DD-MMM-YYYY'} );

%output parameters
%obj - (marketObject)

classdef marketData2 < handle
    
    properties (Constant)           
        Connection = database(DataBase.readSetup('DBName'),...
            'root','selena', 'Vendor','MySQL');
        DBContractDataFolder = ...
            DataBase.readSetup('DBContractDataFolder');
    end
    
    properties (SetAccess = private)     
        MarketName            
        BeginDateStr 
        EndDateStr
        BeginDateNum 
        EndDateNum 
        RequestedTickers
        BeginInterval
        EndInterval
        DataBase 
        nTicks
        nDays
        Comission
    end %properties
    
    methods
        
        function obj = marketData2(varargin) %constructor
            if nargin == 0
            elseif isa(varargin{1}, 'marketData2')
                obj = varargin{1};
            else
                obj.MarketName = varargin{1};
                obj.BeginDateStr = cell2mat( varargin{2}(1) );
                obj.EndDateStr = cell2mat( varargin{2}(2) );             
                obj.BeginDateNum = datenum(obj.BeginDateStr);
                obj.EndDateNum = datenum(obj.EndDateStr);
            end %if          
            obj.loadDataBase;
            obj = getTicksNum(obj);
            obj = getDayNum(obj);
            obj = getComission(obj);
            
        end %constructor
        
        function obj = getTicksNum(obj)
            for i = 1:size(obj.DataBase, 2)
                obj.nTicks(i) = 1;
%                 obj.nTicks(i) = length(obj.DataBase{i}.prices(:,1));
            end
        end
        
        function obj = getContractInfo(obj)
             
            TimeInterval = [obj.BeginDateNum obj.EndDateNum];
            FuturesData = strtrim( fetch( obj.Connection, [...
                ' SELECT DISTINCT ticker, delivery_date '...
                ' FROM futures '...
                ]));
            if  length(FuturesData(:,1)) ~=  length(unique(FuturesData(:,1)))
                [~, UniqueIndexes, ~] = unique(FuturesData(:,1), 'stable');
                FuturesData = FuturesData(UniqueIndexes,:);
            end
            indexes = cell2mat( cellfun( @(x) ...
                ~isempty(regexp(x, [obj.MarketName  '(-[369].*|-12.*)'], 'match')),...
                FuturesData(:,1), 'UniformOutput', false));

            AllTickerData = FuturesData(indexes,:);           
            Dates = datenum(AllTickerData(:,2), 'dd.mm.yyyy');
            SortedDates = sort(Dates);
            
            FirstTickerDate = find( SortedDates > TimeInterval(1), 1 );
            LastTickerDate = find( SortedDates < TimeInterval(2), 1, 'last' );
            
            if length(SortedDates) > LastTickerDate
                LastTickerDate = LastTickerDate + 1;
            end
            if isempty(LastTickerDate)
                LastTickerDate = 1;
            end
            RequestedDates = SortedDates(FirstTickerDate:LastTickerDate);
            [~, indexes, ~] = intersect(Dates, RequestedDates);

            obj.RequestedTickers = AllTickerData(indexes,1);

            for i = 2:length(RequestedDates)
                obj.BeginInterval(i) = RequestedDates(i-1);
                obj.EndInterval(i-1) = RequestedDates(i-1) - 1;
            end
            
            obj.BeginInterval(1) = TimeInterval(1);
            obj.EndInterval(i) = TimeInterval(2);
            
            if isempty( obj.EndInterval)
                 obj.EndInterval =  TimeInterval(2);
            end
            
        end
        
        function obj= getComission(obj)
            TempComission = cell(1,length(obj.RequestedTickers));
            for i=1:length(obj.RequestedTickers)
                TempComission{i} = fetch(obj.Connection, [...
                    ' SELECT intra_day_comission '...
                    ' FROM comissions '...
                    ' WHERE ticker = ''' obj.RequestedTickers{i} ''''...
                    ]);
            end
            if strcmp(obj.MarketName, 'RTS' ) == 1
                k=2.5;
            else
                k=1;
            end
            obj.Comission = 4*cell2mat(TempComission{1})*k; 
        end %setComission
               
        function loadDataBase(obj)
        	obj.getContractInfo;  
            TimeFrames = [1 5 10 15 30 60];
            obj.DataBase = cell(1,6);
            for i=1:length(TimeFrames)
            obj.DataBase{i} = [{NaN(fix(2e6/TimeFrames(i)),4)}; {NaN(fix(2e6/TimeFrames(i)),1)};...
                {NaN(fix(2e6/TimeFrames(i)),1)}; {NaN(fix(2e6/TimeFrames(i)),1)}];
            end
            for i = 1:length(obj.RequestedTickers)
                expr = 'result';
                counter = 0;
                while ~isempty(expr)
                    try
                        Res = load([obj.DBContractDataFolder...
                            obj.RequestedTickers{i+counter}], '-mat');
                        expr = [];
                    catch expr 
                        disp('LOAD ERROR')
                        counter = counter + 1;
                    end
                end
                for j=1:length(Res.dataBar)
                    Res.dataBar{j}.volume = Res.dataBar{j}.volume(:);
                    Res.dataBar{j}.deals = Res.dataBar{j}.deals(:);
                    [indexes, ~]= find( fix( Res.dataBar{j}.minuteNumbers(:,1)) >=...
                        obj.BeginInterval(i) & fix(Res.dataBar{j}.minuteNumbers(:,1)) <=...
                        obj.EndInterval(i));
                    FieldNames = fieldnames(Res.dataBar{j});
                    BarData = struct2cell(Res.dataBar{j});
                    TempDataBase{i,j} = cellfun(@(x) x(indexes,:), BarData,...
                        'UniformOutput', false);
                    %TempDataBase = cell2struct(TempDataBase, FieldNames, 1);
                end
            end  
            re
%             for i=1:length(obj.DataBase)
%             obj.DataBase{i}.endOfDayIndexes =...
%                 [ find( diff( fix( obj.DataBase{i}.minuteNumbers(:,1) ) ) >= 1) - 2; ...
%                 length( obj.DataBase{i}.minuteNumbers(:,1)) - 1];
%             end
        end
        
        function obj = getDayNum(obj)
            obj.nDays = 1;
%             obj.nDays = size(obj.DataBase{1}.endOfDayIndexes, 1);
        end
        
    end %methods
    
end %classdef


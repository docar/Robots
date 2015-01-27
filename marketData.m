%Class defines format of market data objects

%input parameters:
%varargin{1} - name of market (string);
%varargin{2} - dates of sample begin and end (cell)
% format {'DD-MMM-YYYY','DD-MMM-YYYY'} );

%output parameters
%obj - (marketObject)

classdef marketData
    
    properties (Constant)
        Connection = database(DataBase.readSetup('DBName'),...
            'root','selena', 'Vendor','MySQL');
        DBContractDataFolder = ...
            DataBase.readSetup('DBContractDataFolder');
        ExitAtEndOfDay  = DataBase.readSetup('ExitAtEndOfDay');
        TimeFrames = DataBase.readSetup('TimeFrames');
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
        NormalComission
        IntraDayComission
        ActiveComission
        PriceTick
        CostOfPriceTick
        ActiveTimeFrames
    end %properties
    
    methods
        
        function obj = marketData(varargin) %constructor
            if nargin == 0
            elseif isa(varargin{1}, 'marketData')
                obj = varargin{1};
            else
                obj.MarketName = varargin{1};
                obj.BeginDateStr = cell2mat( varargin{2}(1) );
                obj.EndDateStr = cell2mat( varargin{2}(2) );
                obj.BeginDateNum = datenum(obj.BeginDateStr);
                obj.EndDateNum = datenum(obj.EndDateStr);
                %Take active time frames from system invariants table
                Content = position.loadFile('SystemInvariants.xlsx');
                obj.ActiveTimeFrames = Content(2:end,strcmp(Content(1,:), 'TimeFrame'));
                obj.ActiveTimeFrames = cell2mat(obj.ActiveTimeFrames(...
                    cellfun(@(x) ~isempty(x) , Content(2:end,strcmp(Content(1,:), 'TimeFrame'))))');
           
            end %if
            obj = obj.loadDataBase;
            obj = obj.getDayNum;
            obj = obj.getContractInfo;
            obj = obj.castData;
            
        end %constructor
        
        function obj = getContractData(obj)
            
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
        
        function obj = getContractInfo(obj)
            
            ContractName = cell2mat(regexp(obj.RequestedTickers{end}, '(.*-)', 'match'));          

            obj.IntraDayComission = unique(4*cell2mat(fetch(obj.Connection, [...
                ' SELECT intra_day_comission '...
                ' FROM contract_info '...
                ' WHERE ticker REGEXP ''' [ContractName '[0-9].[0-9]?[0-9]'] ''''...
                ])));
            
            obj.NormalComission = unique(4*cell2mat(fetch(obj.Connection, [...
                ' SELECT normal_comission '...
                ' FROM contract_info '...
                ' WHERE ticker REGEXP ''' [ContractName '[0-9].[0-9]?[0-9]'] ''''...
                ])));

            if eval(obj.ExitAtEndOfDay)
                obj.ActiveComission = obj.IntraDayComission;
            else
                obj.ActiveComission = obj.NormalComission;
            end
            
            obj.PriceTick = unique(cell2mat(fetch(obj.Connection, [...
                ' SELECT price_tick '...
                ' FROM contract_info '...
                ' WHERE ticker REGEXP ''' [ContractName '[0-9].[0-9]?[0-9]'] ''''...
                ])));
            
            obj.CostOfPriceTick = unique(cell2mat(fetch(obj.Connection, [...
                ' SELECT cost_of_price_tick '...
                ' FROM contract_info '...
                ' WHERE ticker REGEXP ''' [ContractName '[0-9].[0-9]?[0-9]'] ''''...
                ])));
        end 
        
        function obj = loadDataBase(obj)
            obj = obj.getContractData;
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
                        disp(expr.message)
                        counter = counter + 1;
                        if counter > length(obj.RequestedTickers)
                            expr = [];
                        end
                    end
                end
                
                [~, ActiveIndexes] = intersect(obj.TimeFrames, obj.ActiveTimeFrames);
                
                for j=1:length(ActiveIndexes)
                    if size( Res.dataBar{ActiveIndexes(j)}.volume, 1 ) == 1
                        Res.dataBar{ActiveIndexes(j)}.volume = Res.dataBar{ActiveIndexes(j)}.volume';
                        Res.dataBar{ActiveIndexes(j)}.deals = Res.dataBar{ActiveIndexes(j)}.deals';
                    end
                    [indexes, ~]= find( fix( Res.dataBar{ActiveIndexes(j)}.minuteNumbers(:,1)) >=...
                        obj.BeginInterval(i) & fix(Res.dataBar{ActiveIndexes(j)}.minuteNumbers(:,1)) <=...
                        obj.EndInterval(i));
                    FieldNames = fieldnames(Res.dataBar{ActiveIndexes(j)});
                    TempDataBase = cell(1,length( FieldNames ));
                    for k=1:length( FieldNames )
                        TempDataBase{j}.(FieldNames{k}) =...
                            Res.dataBar{ActiveIndexes(j)}.(FieldNames{k})(indexes,:);
                    end
                    if i == 1
                        obj.DataBase{j} = TempDataBase{j};
                    else
                        FieldNames = fieldnames(TempDataBase{j});
                        for k=1:length( FieldNames )
                            if ~isempty(TempDataBase{j}.(FieldNames{k}))
                                obj.DataBase{j}.(FieldNames{k}) = ...
                                    [obj.DataBase{j}.(FieldNames{k}); ...
                                    TempDataBase{j}.(FieldNames{k})];
                            end
                        end
                    end
                end
            end
            
            for i=1:length(obj.DataBase)
                obj.DataBase{i}.endOfDayIndexes =...
                    [ find( diff( fix( obj.DataBase{i}.minuteNumbers(:,1) ) ) >= 1) - 2; ...
                    length( obj.DataBase{i}.minuteNumbers(:,1)) - 1];
            end
        end
        
        function obj = getDayNum(obj)
            obj.nDays = size(obj.DataBase{1}.endOfDayIndexes, 1);
        end
        
        function obj =  changeDataBase(obj, NewDataBase)
            obj.DataBase = [];
            obj.DataBase = NewDataBase;
        end
        
        function obj = castData(obj)
            %tic
            for i = 1:length(obj.DataBase)
                %Convert prices to rubles
                obj.DataBase{i}.prices = int32((obj.DataBase{i}.prices/obj.PriceTick)*obj.CostOfPriceTick);
                obj.DataBase{i}.volume =single(obj.DataBase{i}.volume);
                obj.DataBase{i}.deals =single(obj.DataBase{i}.deals);
                obj.DataBase{i}.endOfDayIndexes = single(obj.DataBase{i}.endOfDayIndexes);
                
                %Convert minimal time step
                if obj.ActiveTimeFrames(1) > 1 
                    MinuteNumbers = uint64(floor(obj.DataBase{i}.minuteNumbers/(1/((obj.ActiveTimeFrames(1)/60)*60*24))+1e-6));
                    
                    if i == 1                   
                        Result = unique(MinuteNumbers, 'stable');
                        Result(Result == 0) = [];                
                    else
                                               
                    TimeConstant = obj.ActiveTimeFrames(i)/obj.ActiveTimeFrames(1);
                    Result = zeros(size(MinuteNumbers,1),TimeConstant);

                        for j = 1:size(MinuteNumbers,1)
                            UniqueValues = unique(MinuteNumbers(j,:), 'stable'); 
                            Result(j,1:length(UniqueValues)) = UniqueValues;
                        end

                        if size(Result,2) > TimeConstant
                            Result(:,TimeConstant+1) = [];
                        end
                    end
                    
                    obj.DataBase{i}.minuteNumbers = double(Result)*(1/((obj.ActiveTimeFrames(1)/60)*60*24));
                    
                    if size(obj.DataBase{i}.minuteNumbers, 1) ~= size(obj.DataBase{i}.prices, 1)
                        err = MException('ResultChk:OutOfRange', ...
                            'Resulting value is outside expected range');
                        throw(err)
                    end
                        
                end
                    
                %Get ticks number
                obj.nTicks(i) = length(obj.DataBase{i}.prices(:,1));
            end
            %disp(num2str(toc))
        end

        
    end %methods
    
end %classdef


classdef roci < rule
    
    properties
        Treshold
        WindowSize
        Prices
    end
    
    methods
        
        function obj = roci(varargin) %constructor
            obj.ObjectStructure = varargin{1};
            if isa( varargin{1}.RuleParameters, 'cell')
                RuleParameters = str2num(cell2mat( varargin{1}.RuleParameters));
            else
                RuleParameters = varargin{1}.RuleParameters;
            end
            obj.WindowSize = RuleParameters(end);
            obj = transformObjectStructure(obj);
        end %constructor
        
        function obj = getIndicator(obj)
            obj.Prices = obj.Market.DataBase{obj.TimeFrame}.prices(:,4);
            obj.Indicator( 1:length(obj.Prices) ) = NaN;
            obj.Indicator =  obj.Indicator(:);
            obj.Indicator(obj.WindowSize+1:length(obj.Prices)) =...
                ((obj.Prices(obj.WindowSize+1:length(obj.Prices))- ...
                obj.Prices(1:length(obj.Prices)-obj.WindowSize)...
                )./obj.Prices(1:length(obj.Prices)-obj.WindowSize))*100;
        end
        
        function obj = findActiveBars(obj, Market)
            obj.Market = Market;
            obj = getIndicator(obj);
            if obj.ObjectStructure.IndicatorCondition
                obj.RuleActiveBars = find( obj.Indicator > 0 );
            else
                obj.RuleActiveBars = find( obj.Indicator < 0 );
            end
            obj.RuleActiveBarsRaw = obj.RuleActiveBars;
            if obj.TimeFrame > 1
                MinuteNumbers = obj.Market.DataBase{obj.TimeFrame...
                    }.minuteNumbers(obj.RuleActiveBars,:);
                LastMinuteNumbers = MinuteNumbers(sub2ind(size(MinuteNumbers),...
                    1:size(MinuteNumbers,1),...
                    sum(~ismember(MinuteNumbers, 0),2)'));
                [~,obj.RuleActiveBars,~] = intersect(...
                    obj.Market.DataBase{1}.minuteNumbers, LastMinuteNumbers);
            end
        end
        
    end
    
    methods(Static)
        
        function Indicator = selfTest(obj)
            tic
            obj = getIndicator(obj);
            disp(['Rule calculation time ' num2str(toc)])
            tic
            Indicator = indicators(obj.Prices, ...
                'roc', obj.WindowSize);
            disp(['Reference calculation time ' num2str(toc)])
        end
        
    end
    
end


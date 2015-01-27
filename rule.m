classdef rule < positionParent
    
%     properties (Constant)
%         TimeFrames = DataBase.readSetup('TimeFrames');
%     end
    
    properties (SetAccess = public)
        RuleActiveBars = single(NaN) %active bars prices and indexes
        Indicator = single(NaN) %counted indicator values
        RuleActiveBarsRaw
    end %properties
    
    properties (Dependent)
        nTicks
        TimeFrame
    end %properties
    
    methods
        
        function obj = transformObjectStructure(obj)
            if strcmp(obj.ObjectStructure.IndicatorCondition, 'MoreThanIndicator')
                obj.ObjectStructure.IndicatorCondition = 1;
            else
                obj.ObjectStructure.IndicatorCondition = 0;
            end
            if strcmp(obj.ObjectStructure.RuleType, 'Enter')
                obj.ObjectStructure.RuleType = 1;
            else
                obj.ObjectStructure.RuleType = 2;
            end
            %obj.TimeFrame = find(( obj.TimeFrames == obj.ObjectStructure.TimeFrame ) == 1 );
        end
        
        function obj = findActiveBars(obj, Market) % standart for boll, sma, ema
            obj.Market = Market;
            obj = getIndicator(obj);
            ShiftedPrices = circshift(obj.Prices,[1 1]);
            ShiftedIndicator = circshift(obj.Indicator,[1 1]);
            if obj.ObjectStructure.IndicatorCondition
                obj.RuleActiveBars = find( obj.Prices >= obj.Indicator(:)...
                    & ShiftedPrices <= ShiftedIndicator(:) );
            else
                obj.RuleActiveBars = find( obj.Prices <= obj.Indicator(:)...
                    & ShiftedPrices >= ShiftedIndicator(:) );
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
                obj.RuleActiveBars = single(obj.RuleActiveBars);
            end
        end
        
        function nTicks = get.nTicks(obj)
            if ~isempty(obj.Market)
                nTicks = obj.Market.nTicks(1);
            else
                nTicks = 0;
            end
        end
        
        function TimeFrame = get.TimeFrame(obj)
            if ~isempty(obj.Market)
                TimeFrame = find(( obj.Market.ActiveTimeFrames == obj.ObjectStructure.TimeFrame ) == 1 ) ;
            else
                TimeFrame = 0;
            end
        end
        
                
        
    end %methods
    
end %classdef




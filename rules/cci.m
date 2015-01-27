classdef cci < rule
    
    properties
        Treshold
        SmaWindowSize
        MadWindowSize
        Prices
    end
    
    methods
        
        function obj = cci(varargin) %constructor
            obj.ObjectStructure = varargin{1};
            RuleParameters = str2num( cell2mat(varargin{1}.RuleParameters ));
            obj.Treshold = RuleParameters(end-2);
            obj.MadWindowSize =  RuleParameters(end-1);
            obj.SmaWindowSize = RuleParameters(end);
            obj = transformObjectStructure(obj);
        end %constructor
        
        function obj = getIndicator(obj)
   
            obj.Prices = obj.Market.DataBase{obj.TimeFrame}.prices;
            TypicalPrices = single((obj.Prices(:,2) + obj.Prices(:,3) + obj.Prices(:,4))/3);
            sma = single(filter(ones(1,obj.SmaWindowSize)/obj.SmaWindowSize,1,TypicalPrices));
            tmat = single(zeros(length(obj.Prices) - obj.MadWindowSize + 1, obj.MadWindowSize));
            for i=1:obj.MadWindowSize
                tmat(:,i) = TypicalPrices(i:end - obj.MadWindowSize + i);
            end
            %tmat = abs(bsxfun(@minus, tmat, sma(obj.MadWindowSize:end)));
            tmat = abs(tmat - repmat(sma(obj.MadWindowSize:end), [1 obj.MadWindowSize]));
            smad =[nan(1,obj.MadWindowSize-1)'; sum(tmat,2)/obj.MadWindowSize];
            obj.Indicator  = single(nan(length(obj.Prices),1));
            i1 = obj.MadWindowSize:length(obj.Prices);
            obj.Indicator(i1) = single( TypicalPrices(i1) - sma(i1)) ./ (0.015*smad(i1) );
        end
        
        function obj = findActiveBars(obj, Market)
            obj.Market = Market;
            obj = getIndicator(obj);
            if obj.ObjectStructure.IndicatorCondition
                obj.RuleActiveBars = single(find( obj.Indicator > obj.Treshold ));
            else
                obj.RuleActiveBars = single(find( obj.Indicator < obj.Treshold ));
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
        
    end
    
    methods(Static)
        
        function Indicator = selfTest(obj)
            tic
            obj = getIndicator(obj);
            disp(['Rule calculation time ' num2str(toc)])
            tic
            Indicator = indicators(obj.Prices(:,2:4), ...
                cell2mat(obj.ObjectStructure.RuleName),...
                obj.SmaWindowSize,obj.MadWindowSize,...
                0.015);
            disp(['Reference calculation time ' num2str(toc)])
        end
        
    end
    
end


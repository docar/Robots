classdef boll < rule
    
    properties
        WindowSize
        nStandartDeviations
        Prices
    end
    
    methods
        
        function obj = boll(varargin) %constructor
            obj.ObjectStructure = varargin{1};
            RuleParameters = str2num( cell2mat(varargin{1}.RuleParameters));
            obj.nStandartDeviations =  RuleParameters(end-1);
            obj.WindowSize = RuleParameters(end);
            obj = transformObjectStructure(obj);
        end %constructor
        
        function obj = getIndicator(obj)
            obj.Prices = obj.Market.DataBase{obj.TimeFrame}.prices(:,4);
            obj.Indicator( 1:length(obj.Prices) ) = single(NaN);
            sma = filter(ones(1,obj.WindowSize)/obj.WindowSize,1,double(obj.Prices));
            if obj.nStandartDeviations ~=0
                NormalPrices = double(obj.Prices - mean(obj.Prices));
                SqrPrice =  NormalPrices.^2;
                B = ones(1,obj.WindowSize);
                stdDev = sqrt((filter(B,1,SqrPrice) - (filter(B,1,NormalPrices).^2)*(1/obj.WindowSize))/(obj.WindowSize-1));
                obj.Indicator(obj.WindowSize:end) = single(sma(obj.WindowSize:end) +...
                    obj.nStandartDeviations .* stdDev(obj.WindowSize:end));
            else
                obj.Indicator(obj.WindowSize:end) = sma(obj.WindowSize:end);
            end
            %             t = getCurrentTask();
            %             disp(t.ID)
        end
        
    end
    
    methods(Static)
        
        function Indicator = selfTest(obj)
            tic
            obj = getIndicator(obj);
            disp(['Rule calculation time ' num2str(toc)])
            tic
            Result = indicators(obj.Prices, ...
                cell2mat(obj.ObjectStructure.RuleName),...
                obj.WindowSize,0,abs(obj.nStandartDeviations));
            if obj.nStandartDeviations < 0
                Indicator = Result(:,3)';
            else
                Indicator = Result(:,2)';
            end
            disp(['Reference calculation time ' num2str(toc)])
        end
        
    end
    
end


classdef ema < rule
    
    properties
        WindowSize
        Prices
    end
    
    methods
        
        function obj = ema(varargin) %constructor
            obj.ObjectStructure = varargin{1};
            RuleParameters = str2num( cell2mat(varargin{1}.RuleParameters));            
            obj.WindowSize = RuleParameters(end);
            obj = transformObjectStructure(obj);
        end %constructor 

        function obj = getIndicator(obj)
            obj.Prices = obj.Market.DataBase{obj.TimeFrame}.prices(:,4);
            nTicks = length(obj.Prices);
            obj.Indicator( 1:nTicks ) = NaN;
            obj.Indicator = obj.Indicator(:);
            alpha = 2/(obj.WindowSize+1);
            Ralpha = 1-alpha;
            AlphaPrices = alpha * obj.Prices;
            
            obj.Indicator(obj.WindowSize) =...
                sum(obj.Prices(1:obj.WindowSize))/obj.WindowSize;
            
            obj.Indicator(obj.WindowSize) =...
                AlphaPrices(obj.WindowSize) +...
                Ralpha*obj.Indicator(obj.WindowSize);


            for i = obj.WindowSize+1:nTicks
                obj.Indicator(i) = AlphaPrices(i) + Ralpha * obj.Indicator(i-1);
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
                cell2mat(obj.ObjectStructure.RuleName),...
                obj.WindowSize);
            disp(['Reference calculation time ' num2str(toc)])
        end 
        
    end
    
end
classdef sma < rule
    
    properties
        WindowSize
        Prices
    end
    
    methods
        
        function obj = sma(varargin) %constructor
            obj.ObjectStructure = varargin{1};
            RuleParameters = str2num( cell2mat(varargin{1}.RuleParameters));            
            obj.WindowSize = RuleParameters(end);
            obj = transformObjectStructure(obj);
        end %constructor 

        function obj = getIndicator(obj)
            obj.Prices = obj.Market.DataBase{obj.TimeFrame}.prices(:,4);
            obj.Indicator( 1: length(obj.Prices) ) = single(NaN);
            obj.Indicator = obj.Indicator(:);
            sma = single(filter(ones(1,obj.WindowSize)/obj.WindowSize,1,obj.Prices));
            obj.Indicator(obj.WindowSize:end) = sma(obj.WindowSize:end);
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

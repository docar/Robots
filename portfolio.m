classdef portfolio < positionParent
    
    methods

        function obj = portfolio(varargin) %constructor
            if nargin == 0
            elseif isa(varargin{1}, 'portfolio')
                obj = varargin{1};
            elseif isa(varargin{1}, 'dataset')
                obj = positionParent.createObject(varargin{1});
            end          
        end %constructor   
        
        function obj = getFinalState(obj, varargin)
            if isa (varargin{1}{1}, 'marketData') %Market data object as input               
                obj.Market = varargin{1};
            else %Time interval as input  
                obj.Market = obj.setMarket(varargin{1}); 
            end
            for i=1:obj.nFields
                obj.Fields{i} = obj.Fields{i}.getFinalState(obj.Market{i});
            end
        obj.FinalState.nDeals = sum(cellfun(@(x) x.FinalState.nDeals,  obj.Fields));
        obj.FinalState.DealsRate = mean(cellfun(@(x) x.FinalState.DealsRate,  obj.Fields)); 
        obj.FinalState.Profits = cell2mat(cellfun(@(x) x.FinalState.Profits(:)',  obj.Fields,  'UniformOutput', false));
        obj.FinalState.ActiveClosings = cell2mat(cellfun(@(x)...
            x.FinalState.ActiveClosings(:)',  obj.Fields,  'UniformOutput', false));
            if length(unique(obj.ObjectStructure.MarketName)) > 1
                obj = obj.convertProfitVector;
            else
                obj.FinalState.ProfitVector = 0;
                for i=1:obj.nFields
                    if ~isempty(obj.Fields(i).FinalState.ProfitVector)
                        obj.FinalState.ProfitVector = obj.FinalState.ProfitVector +...
                            obj.Fields(i).FinalState.ProfitVector; 
                    end
                end 
            end
        end 
        
        function obj = convertProfitVector(obj)
        UniversalTimeNet = [];
            for i=1:length(obj.Fields)
                UniversalTimeNet = union(UniversalTimeNet, obj.Fields{i}.Market.DataBase{1}.minuteNumbers);
            end
        obj.FinalState.ProfitVector(1:length(UniversalTimeNet)) = 0;
            for i=1:length(obj.Fields)  
                obj.Fields{i}.FinalState.PortfolioProfitVector = zeros(1,length(UniversalTimeNet));
                if ~isempty(obj.Fields{i}.FinalState.ProfitVector)
                    [~, gapIndexes] = setdiff(UniversalTimeNet, obj.Fields{i}.Market.DataBase{1}.minuteNumbers, 'stable');
                    if ~isempty(gapIndexes)
                        ia = setdiff(1:length(UniversalTimeNet), gapIndexes, 'stable');
                        firstPos = [gapIndexes(1)  gapIndexes( find( diff( gapIndexes) > 1) + 1)' ];
                        lastPos = [gapIndexes( find( diff( gapIndexes) > 1) )' gapIndexes(end)];
                        obj.Fields{i}.FinalState.PortfolioProfitVector(ia) =  obj.Fields{i}.FinalState.ProfitVector;
                        for j=1:length( firstPos )
                            obj.Fields{i}.FinalState.PortfolioProfitVector(firstPos(j):lastPos(j)) =...
                                obj.Fields{i}.FinalState.PortfolioProfitVector(firstPos(j) - 1); 
                        end
                    else
                         obj.Fields{i}.FinalState.PortfolioProfitVector = obj.Fields{i}.FinalState.ProfitVector;
                    end
                end
                obj.FinalState.ProfitVector = obj.FinalState.ProfitVector + obj.Fields{i}.FinalState.PortfolioProfitVector;
            end
        end
        
        function Market = setMarket(obj, TimeInterval)
                [~,MarketIndexes,~] = unique(obj.ObjectStructure.MarketNumber);
                Market = cell(1,length(MarketIndexes));
                for i=1:max(obj.ObjectStructure.MarketNumber)
                Market{i} = marketData(...
                    obj.ObjectStructure.MarketName{MarketIndexes(i)}, TimeInterval );
                end
        end
        
    end
        
end



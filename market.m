classdef market < positionParent

    methods
        
        function obj = market(varargin) %constructor
            if nargin == 0
            elseif isa(varargin{1}, 'market')
                obj = varargin{1};
            elseif isa(varargin{1}, 'dataset')
                obj = positionParent.createObject(varargin{1});
            end          
        end %constructor
        
        function obj = getFinalState(obj, varargin)
            if isa (varargin{1}, 'marketData') %Market data object as input
                obj.Market = varargin{1};
            elseif isa (varargin{1}, 'cell') 
                if isa (varargin{1}{1}, 'marketData')
                    obj.Market = varargin{1}{1};
                else
                    obj.Market = obj.setMarket(varargin{1}); 
                end
            end
            obj.FinalState.ProfitVector = 0;
            for i=1:obj.nFields
                obj.Fields{i} = obj.Fields{i}.getFinalState(obj.Market); 
                if ~isempty(obj.Fields{i}.FinalState.ProfitVector)
                    obj.FinalState.ProfitVector = obj.FinalState.ProfitVector +...
                        obj.Fields{i}.FinalState.ProfitVector; 
                end
            end  
            obj.FinalState.nDeals = sum(cellfun(@(x) x.FinalState.nDeals,  obj.Fields));
            obj.FinalState.DealsRate = mean(cellfun(@(x) x.FinalState.DealsRate,  obj.Fields)); 
            obj.FinalState.Profits = cell2mat(cellfun(@(x) x.FinalState.Profits(:)',  obj.Fields,  'UniformOutput', false));
            obj.FinalState.ActiveClosings = cell2mat(cellfun(@(x)...
                x.FinalState.ActiveClosings(:)',  obj.Fields,  'UniformOutput', false));
        end        
        
    end
    
end


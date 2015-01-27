classdef positionState < handle
    
    properties (Dependent)
        ProfitVector
    end
    
    properties (SetAccess = public) %properties
        AllOpenings %openings defined by rules
        AllClosings %closings defined by rules
        ActiveOpenings %number of bars that open the position ( = ActiveClosings)
        ActiveClosings %number of bars that close the position ( = ActiveOpenings)
        OpeningPrices
        ClosingPrices
        nTicks
        nDeals %total number of deals
        nDays
        DealsRate %Deals per day
        Profits
        Prices
        PortfolioProfitVector
        PositionType
        PositionSize
        Comission      
    end %properties

    methods
        %position initialisation
        function obj = positionState(varargin) %constructor
            if nargin == 0
                obj.nDeals = 0;  
                obj.DealsRate = 0;
                obj.Profits = [];
            elseif isa(varargin{1}, 'position')
                obj.AllOpenings = ...
                    varargin{1}.PositionActiveBars{1};
                obj.AllClosings = ...
                    varargin{1}.PositionActiveBars{2};
                obj.Comission = varargin{1}.Market.ActiveComission;
                obj.Prices = varargin{1}.Market.DataBase{1}.prices;
                obj.nDays = varargin{1}.Market.nDays;
                obj.PositionType = varargin{1}.ObjectStructure.PositionType;
                obj.nTicks = varargin{1}.Market.nTicks(1);
                obj.PositionSize = unique(...
                    varargin{1}.ObjectStructure.PositionSize);
            end
        end %constructor
        
        function obj = getPositionFinalState(obj)     
            obj.AllOpenings( obj.AllOpenings == obj.nTicks ) = [];
            obj.AllClosings( obj.AllClosings == obj.nTicks ) = [];
            AllBars = union(obj.AllClosings, obj.AllOpenings);
            obj.ActiveClosings = AllBars(find(diff(ismember(AllBars, obj.AllClosings)) == 1) + 1);
            obj.ActiveOpenings = AllBars(find(diff(ismember(AllBars, obj.AllClosings)) == -1) + 1);
            obj.ActiveOpenings = obj.ActiveOpenings(:);
            obj.ActiveClosings = obj.ActiveClosings(:);
            
            if find( ~ismember(AllBars, obj.AllClosings), 1) == 1%If first bar in union is opening 
               obj.ActiveOpenings = [AllBars(1); obj.ActiveOpenings];%Then put it in ActiveOpenings vector
            end 
            
            obj.nDeals = min([ length(obj.ActiveClosings) length(obj.ActiveOpenings) ]); 
            obj.DealsRate =  obj.nDeals / obj.nDays;
            
            if obj.nDeals > 0
                obj.OpeningPrices = obj.Prices(obj.ActiveOpenings + 1, 4);%Means closing prose of the next bar after bar crossed indicator
                obj.ClosingPrices = obj.Prices(obj.ActiveClosings + 1, 4);
                obj.Prices = [];
                obj.Profits = getProfits(obj);
            else
                obj.Profits = [];
            end
        end 
        
        %Function calculates profits
        function Profits = getProfits(obj) 
            if strcmp(obj.PositionType, 'Long')
                Profits = double(obj.PositionSize * 100 * (obj.ClosingPrices - obj.OpeningPrices -...
                obj.Comission))./double(obj.OpeningPrices);
            else 
                Profits =  double(obj.PositionSize * 100*(obj.OpeningPrices - obj.ClosingPrices - ...
                obj.Comission))./double(obj.OpeningPrices);
            end
        end
        
        function ProfitVector = get.ProfitVector(obj)
            if ~isempty(obj.ActiveClosings)
                ProfitVector( 1 : obj.nTicks ) = 0;
                cumSum = cumsum(double(obj.Profits));
                for i=1:length(obj.ActiveClosings) - 1
                    try
                        ProfitVector( obj.ActiveClosings(i) + 1:...
                            obj.ActiveClosings( i + 1 ) ) = cumSum(i);
                    end
                end
                ProfitVector( obj.ActiveClosings(end) + 1:end ) = cumSum(end);
                %ProfitVector = int16(ProfitVector*100);
            else
                ProfitVector = [];
            end
        end
        
    end %methods
end
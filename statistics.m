classdef statistics < handle
    
    properties
        PositionObject
    end
    
    properties(Dependent)
        NetProfit
        MaxProfit
        ProfitDeals
        AverageProfit
        MaxLoss
        LossDeals
        AverageLoss
        MinimumLow
        MaximumHigh
        MaxDrawdown
        ProfitRiskRatio
        ProfitFactor
    end
    
    properties
        ProfitIndexes
        LossIndexes
        DealsRate
        nDeals
    end
    
    methods
        function obj = statistics(varargin) %constructor
            if nargin == 0
            elseif isa(varargin{1}, 'statistics')
                obj = varargin{1};
            else
                obj.PositionObject = varargin{1}.FinalState;
                obj.nDeals = varargin{1}.FinalState.nDeals;
                obj.DealsRate =  varargin{1}.FinalState.DealsRate;
            end
            %obj.showReport
            
        end %constructor
        
        function NetProfit = get.NetProfit(obj)
            NetProfit = sum( obj.PositionObject.Profits );
        end
         
        function MaxProfit = get.MaxProfit(obj)
            MaxProfit = max( obj.PositionObject.Profits );
        end
        
        function ProfitDeals = get.ProfitDeals(obj)
            obj.ProfitIndexes = find ( obj.PositionObject.Profits > 0);           
            ProfitDeals = length( obj.ProfitIndexes ) ;
         end
         
        function AverageProfit = get.AverageProfit(obj)
            AverageProfit = sum( obj.PositionObject.Profits ...
                (obj.ProfitIndexes)) / obj.ProfitDeals;
        end
         
        function MaxLoss = get.MaxLoss(obj)
            MaxLoss = min( obj.PositionObject.Profits(...
                obj.PositionObject.Profits < 0 ) );
        end
        
        function LossDeals = get.LossDeals(obj)
            obj.LossIndexes = find ( obj.PositionObject.Profits <= 0);           
            LossDeals =  length( obj.LossIndexes ) ;
         end
         
        function AverageLoss = get.AverageLoss(obj)
            AverageLoss = sum( obj.PositionObject.Profits ...
                (obj.LossIndexes)) / obj.LossDeals;
        end
        
        function MinimumLow = get.MinimumLow(obj)
            MinimumLow = min(obj.PositionObject.Profits);
        end
        
        function MaximumHigh = get.MaximumHigh(obj)
            MaximumHigh = max(obj.PositionObject.Profits);
        end
        
        function MaxDrawdown = get.MaxDrawdown(obj)
        CumSum = cumsum( double(obj.PositionObject.Profits ));
%         CumSum =  obj.PositionObject.ProfitVector(...
%             diff(obj.PositionObject.ProfitVector)~=0)/100;
        
        maxPeack.value = 0; maxPeack.index = 1;
        minValley.value = 0; minValley.index = 1;
        if obj.nDeals == 1
           MaxDrawdown = CumSum;
        else
            MaxDrawdown = minValley.value - maxPeack.value;
        end
            for i = 2:length(CumSum)
                if CumSum(i) >= maxPeack.value
                    maxPeack.value = CumSum(i);
                    maxPeack.index = i;
                    minValley.value = CumSum(i);
                    minValley.index = i;
                elseif CumSum(i) <= minValley.value
                    minValley.value = CumSum(i);
                    minValley.index = i;
                end
                if (minValley.value - maxPeack.value < MaxDrawdown) &&...
                    (minValley.index > maxPeack.index)
                    MaxDrawdown = minValley.value - maxPeack.value;
%                     disp(maxPeack)
%                     disp(minValley)
%                     disp(MaxDrawdown)
                end
            end
        end
         
        function ProfitRiskRatio = get.ProfitRiskRatio(obj)
            ProfitRiskRatio = sign(obj.NetProfit)*obj.NetProfit^2 / double(obj.MaxDrawdown);
        end
        
        function ProfitFactor = get.ProfitFactor(obj)
            ProfitFactor = sum( obj.PositionObject.Profits ...
                (obj.PositionObject.Profits > 0)) / sum( obj.PositionObject.Profits ...
                (obj.PositionObject.Profits <= 0));
        end
        
        function showReport(obj)
            disp('--------------------------------------------------')
            disp(strcat('NET INCOME_', num2str( obj.NetProfit )));
            disp(strcat('NUMBER OF DEALS_', num2str( obj.nDeals )));
            disp(strcat('DEALS RATE_', num2str( obj.DealsRate )));
            disp(strcat('MAX PROFIT_', num2str( obj.MaxProfit )));
            disp(strcat('PROFIT DEALS_', num2str( obj.ProfitDeals )));
            disp(strcat('AVERAGE PROFIT_', num2str( obj.AverageProfit )));
            disp(strcat('MAX LOSS_', num2str( obj.MaxLoss )));
            disp(strcat('LOSS DEALS_', num2str( obj.LossDeals )));
            disp(strcat('AVERAGE LOSS_', num2str( obj.AverageLoss)));
            disp(strcat( 'MINIMUM LOW_', num2str( obj.MinimumLow ) ) );
            disp(strcat( 'MAXIMUM HIGH_', num2str( obj.MaximumHigh ) ) );
            disp(strcat( 'MAXIMUM_DRAWDOWN_', num2str( obj.MaxDrawdown ) ) );
            disp(strcat( 'PROFIT_RISK_RATIO_', num2str( obj.ProfitRiskRatio ) ) );     
            disp(strcat( 'PROFIT_FACTOR_', num2str( obj.ProfitFactor ) ) );    
            %disp(strcat( 'N_PLANNED_EXITS_', num2str( statistics.nPlanedExits ) ) );
            %disp(strcat( 'N_END_OF_DAY_EXITS_', num2str( statistics.nEndOfDayExits ) ) );
            %disp(strcat( 'N_RISK_MANAGMENT_EXITS_', num2str( statistics.nRiskManagmentExits ) ) );
            %disp(strcat( 'N_STOP_LOSSES_', num2str( statistics.nStopLoss ) ) );
            %disp(strcat( 'N_TAKE_PROFITS_', num2str( statistics.nTakeProfit ) ) );
            disp('--------------------------------------------------')
        end
    end
    
end


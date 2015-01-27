classdef position < positionParent
    
    properties (Constant)
        ExitAtEndOfDay  = DataBase.readSetup('ExitAtEndOfDay');
        ExitAtEndOfContract  = DataBase.readSetup('ExitAtEndOfContract');
    end
    
    properties (SetAccess = private)
        PositionActiveBars
    end %properties
    
    methods
        
        function obj = position(varargin) %constructor
            if nargin == 0
            elseif isa(varargin{1}, 'position')
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
            obj = obj.findActiveBars;
        end
        
        function obj = findActiveBars( obj )
            for i = 1:obj.nFields
                obj.Fields{i} = obj.Fields{i}.findActiveBars(obj.Market);
            end
            obj.PositionActiveBars{1} = single(0);
            obj.PositionActiveBars{2} = single(0);
            obj = obj.fillPositionActiveBars;
            if ~isempty(obj.PositionActiveBars{1})
                if eval(obj.ExitAtEndOfDay)
                    obj = obj.addEndOfDayClosings;
                else
                    obj = obj.addEndOfSampleClosing;
                end
                obj.FinalState = positionState(obj).getPositionFinalState;
            else
                obj.FinalState = positionState;
            end
        end
        
        function obj = fillPositionActiveBars( obj )
            for i=1:obj.nFields
                if obj.PositionActiveBars{obj.Fields{i}.ObjectStructure.RuleType} == 0
                    obj.PositionActiveBars{obj.Fields{i}.ObjectStructure.RuleType} = ...
                        obj.Fields{i}.RuleActiveBars;
                else
                    obj.PositionActiveBars{obj.Fields{i}.ObjectStructure.RuleType} = ...
                        intersect( obj.PositionActiveBars{obj.Fields{i}.ObjectStructure.RuleType}, ...
                        obj.Fields{i}.RuleActiveBars );
                end
            end
        end
        
        function obj = addEndOfDayClosings(obj)
            obj.PositionActiveBars{2} = union( obj.PositionActiveBars{2}, ...
                obj.Market.DataBase{1}.endOfDayIndexes);
        end
        
        function obj = addEndOfSampleClosing(obj)
            obj.PositionActiveBars{2} = union( obj.PositionActiveBars{2}, ...
                obj.Market.DataBase{1}.endOfDayIndexes(end));
        end
        
        %         function plotPosition(obj)
        %             subplot(2,1,1); plot(obj.Fields(1).Prices(1:100))
        %             subplot(2,1,2); plot(obj.Fields(1).Indicator(1:100))
        %         end
        
    end %methods
    
end %classdef




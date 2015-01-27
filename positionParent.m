classdef positionParent

    properties (SetAccess = public) 
        ObjectStructure
        Fields
        FinalState
        Market
    end %properties
    
    properties (Dependent)      
        nFields
    end %properties
    
    methods
                
        function nFields = get.nFields(obj)
            nFields = size( obj.Fields, 2 );
        end
        
        function Market = setMarket(obj, TimeInterval)
        Market = marketData(cell2mat(unique(...
            obj.ObjectStructure.MarketName)), TimeInterval );
        end
                
    end
    
    methods(Static)
        
        function Object = createObject(ObjectStructure)
            if size(unique(ObjectStructure.MarketNumber),1) > 1
                Object = positionParent.createObjectWithType('portfolio',...
                    ObjectStructure.MarketNumber, ObjectStructure);
            elseif size(unique(ObjectStructure.PositionNumber),1) > 1
                Object = positionParent.createObjectWithType('market',...
                    ObjectStructure.PositionNumber, ObjectStructure);
            elseif size(unique(ObjectStructure.RuleNumber),1) > 1
                Object = positionParent.createObjectWithType('position',...
                    ObjectStructure.RuleNumber, ObjectStructure);
            else
                Object = positionParent.createRule(ObjectStructure);
            end
        end
           
        function Object = createRule(RuleStructure)
            Object = eval([cell2mat(RuleStructure.RuleName) '(RuleStructure)']);       
         end
        
        function Object = createObjectWithType(Type,Counter, Structure)
            Object = eval(Type);
            Object.ObjectStructure = Structure;        
            for i = 1:max(Counter)
                Fields{i} = positionParent.createObject(...
                    Structure(Counter == i,:));
            end         
            Object.Fields = Fields;
        end
         
        function obj = loadFromFile( FileName )        
        obj = positionParent.createObject(...
            cell2dataset( positionParent.loadFile( FileName ))); 
        end
        
        function Structure = loadFile (FileName)
        [~, ~, Structure] = xlsread(FileName);
            if strcmp(FileName, 'SystemInvariants.xlsx')
                Structure(cellfun(@(x) ~isempty(x) && isnumeric(x) ...
                && isnan(x),Structure)) = {''};
            end      
        end
        
    end
    
    
end


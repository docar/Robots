classdef portfolioStructure
    %PORTFOLIOSTRUCTURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        PortfolioStructure
    end
    
    methods 
        function obj = portfolioStructure(varargin) %constructor
            if nargin == 0              
            elseif isa(varargin{1}, 'portfolioStructure')
                obj = varargin{1};
            elseif isa(varargin{1}, 'char')
                TempPortfolioStructure = portfolioStructure.loadFile(varargin{1});
                if obj.checkInvariants(TempPortfolioStructure)
                    obj.PortfolioStructure = TempPortfolioStructure;
                end
            elseif isa(varargin{1}, 'cell')
            end          
        end %constructor   
              
        function result = checkInvariants(obj, MarketStructure)
        InvariantsStructure = portfolio.loadFile ('SystemInvariants.xlsx');
        result = obj.checkHeaders(MarketStructure, InvariantsStructure) && ...
                    obj.checkEmptyCells(MarketStructure) && ...
                    obj.checkMembers(MarketStructure, InvariantsStructure) && ...
                    obj.checkMarketUniqueness(MarketStructure) &&...
                    obj.checkNumeration(MarketStructure);
            if result == 1
                disp('INVARIANTS ARE OK')
            else
                disp('INVARIANTS FILED')
        end
        end

        function result = checkHeaders(obj, MarketStructure, InvariantsStructure)
            checkVariable = cellfun(@ismember, { MarketStructure(1,:) }, ...
            {InvariantsStructure(1,:)}, 'UniformOutput', false);
            result = all(checkVariable{:});
                if result == 1
                    disp('HEADERS ARE OK')
                else
                    disp('HEADERS FILED')
                end    
        end

        function result = checkEmptyCells(obj, MarketStructure)
            ResultsMatrix =  cellfun( @any, ( cellfun( @isnan, ...
            MarketStructure, 'UniformOutput', false)));
            result = ~any(ResultsMatrix(:));
                if result == 1
                    disp('EMPTY CELLS ARE OK')
                else
                    disp('EMPTY CELLS FILED')
                end
        end

        function result = checkMembers(obj, MarketStructure, InvariantsStructure)
            result =  all( all( ismember( obj.getTextMatrix( MarketStructure), ...
            obj.getTextMatrix( InvariantsStructure))));
                if result == 1
                    disp('MEMBERS ARE OK')
                else
                    disp('MEMBERS CELLS FILED')
                end
        end

        function result = checkMarketUniqueness(obj, MarketStructure)
            Header = MarketStructure( 1,:);
            [~,~,TestVector] = unique( MarketStructure( ...
            2:end, strcmp( 'MarketName', Header)), 'stable');
            result = all( TestVector == cell2mat( MarketStructure( ...
            2:end,strcmp( 'MarketNumber', Header))));
                if result == 1
                    disp('MARKET UNIQUENESS IS OK')
                else
                    disp('MARKET UNIQUENESS FILED')
                end
        end

        function result = checkNumeration(obj, MarketStructure)
        NumerationMatrix = obj.getNumerationMatrix(MarketStructure);
        result = obj.checkNumerationMatrix(NumerationMatrix);
                if result == 1
                    disp('NUMERATION IS OK')
                else
                    disp('NUMERATION FILED')
                end
        end

        function result = checkNumerationMatrix(obj, NumerationMatrix)
        Size = size(NumerationMatrix,2);
            if Size ~=1
                TempResult = isequal(unique(NumerationMatrix(:,1))',...
                1:max(NumerationMatrix(:,1)));
                if TempResult
                    for i=1:max(NumerationMatrix(:,1))
                        result(i) = obj.checkNumerationMatrix(NumerationMatrix(...
                            NumerationMatrix(:, 1)==i, 2:end));  
                    end
                    result = all(result);
                else
                    result = 0;
                end
            else
                result = isequal(NumerationMatrix(:,1)', 1:max(...
                NumerationMatrix(:,1))) & size(NumerationMatrix,1)~=1;
            end
        end

        function TextMatrix = getTextMatrix(obj, MarketStructure)
            HeaderLessMarketStructure = MarketStructure( 2:end, 1:end-1 );
            TextMatrix = HeaderLessMarketStructure( ...
            :, any( cellfun(@(x) ~isnumeric(x) && ~isempty(x),...
            HeaderLessMarketStructure)));
        end

        function NumerationMatrix = getNumerationMatrix(obj, MarketStructure)
            HeaderLessMarketStructure = MarketStructure( 2:end, 1:end-1 );
            NumerationMatrix = cell2mat( HeaderLessMarketStructure( ...
            :, any( cellfun(@(x) isnumeric(x) && ~isempty(x),...
            HeaderLessMarketStructure))));
        end
        
    end
    
end


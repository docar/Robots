classdef optimisationTask < handle
    
    properties (Constant)
        ResDataFolder  = DataBase.readSetup('ResDataFolder');
        OptimComplexity  = DataBase.readSetup('OptimComplexity');
        NumberOfSyntheticTests  = DataBase.readSetup('NumberOfSyntheticTests');
        TestList  = DataBase.readSetup('TestList');
        OutSelectionTestReductionCoefficient = 10;
    end
    
    properties
        Invariants
        ObjectStructure
        TextData
        Variable
        nVariables
        Bounds
        MarketList
        TimeIntervalIn
        History
        ObjectiveParameter
        TaskName
        ExecutionTime
        GenerationCalculationTime
        StartGATime
    end
    
    properties (SetAccess = public)
        ResultsPlot
        ProfitPlot
    end
    
    methods
        
        function obj = optimisationTask(varargin) %constructor
            if nargin == 0
            elseif isa(varargin{1}, 'optimisationTask')
                obj = varargin{1};
            elseif isa(varargin{1}, 'char')
                Content = position.loadFile('SystemInvariants.xlsx');
                FieldNames = Content(1,:);
                Data = arrayfun(@(x) Content([false; ~cellfun(@isempty,...
                    Content(2:end,x))], x), 1:size(Content,2),  'UniformOutput', false);
                obj.Invariants = cell2struct(cell(1,size(Content,2)), Content(1,:), 2);
                for i=1:length(FieldNames)
                    obj.Invariants.(FieldNames{i}) = Data{i};
                end
                obj.TaskName = varargin{1};
                InputStructure = position.loadFile(obj.TaskName);
                obj.TimeIntervalIn = varargin{2};
                obj.ObjectiveParameter = varargin{3};
                obj.ObjectStructure = cell2dataset(InputStructure);
                disp('LOADING MARKET DATA')
                for i=1:length(obj.Invariants.MarketName)
                    obj.MarketList.(obj.Invariants.MarketName{i}).InSelection = marketData(...
                        obj.Invariants.MarketName{i}, obj.TimeIntervalIn );
                    %obj.MarketList.(obj.Invariants.MarketName{i}).OutSelection = [];% marketData(...
                    %obj.Invariants.MarketName{i}, obj.TimeIntervalOut );
                end
                disp('MARKET DATA LOADED')
                obj.TextData = cellfun( @(x) cast(x,'char'),...
                    InputStructure(2:end,:), 'UniformOutput', false);
                
                OptimisationVariableIndexes = cellfun(@(x) ~isempty(x),...
                    regexp( obj.TextData ,{'Optimise'},'match'));
                obj.Variable.List = unique(obj.TextData(OptimisationVariableIndexes));
                [obj.Variable.Rows, obj.Variable.Colons] = find(OptimisationVariableIndexes == 1);
                obj.fillVariableMatrix;
                obj.setBounds;
                obj.startGeneticOptimisation;
                for i=1:length(obj.TestList)
                    if ~isempty(obj.TestList{i})
                        eval(['obj.' obj.TestList{i}]);
                    end
                end
                obj.saveResults
            end
        end %constructor
        
        function obj = fillVariableMatrix(obj)
            obj.nVariables = 0;
            for i = 1:length(obj.Variable.List)
                CurVarInd = cellfun(@(x) ~isempty(x), ...
                    regexp( obj.TextData ,[obj.Variable.List{i} '\>'],'match'));
                [CurVar.Rows, CurVar.Colons] = find(CurVarInd == 1);
                CurVar.Colons = unique(CurVar.Colons);
                if strcmp(obj.ObjectStructure.Properties.VarNames(CurVar.Colons),...
                        'RuleParameters') == 1
                    ParametersVectors = eval( obj.Invariants.RuleParameters{ ...
                        strcmp(obj.Invariants.RuleName,...
                        obj.ObjectStructure.RuleName{CurVar.Rows})});
                    for j = 1:size(ParametersVectors,1)
                        obj.nVariables = obj.nVariables + 1;
                        obj.Variable.Matrix{obj.nVariables} = ...
                            cell2mat(ParametersVectors(j));
                    end
                else
                    obj.nVariables = obj.nVariables + 1;
                    obj.Variable.Matrix{obj.nVariables} =...
                        obj.Invariants.(obj.ObjectStructure.Properties.VarNames{CurVar.Colons});
                end
            end
        end
        
        function obj = setBounds(obj)
            obj.Bounds.Lower = ones(1, obj.nVariables);
            Sizes = cellfun(@size,  obj.Variable.Matrix , 'UniformOutput', false);
            obj.Bounds.Upper = cell2mat(cellfun(@max,  Sizes , 'UniformOutput', false));
        end
        
        function FinalStructure = getStructure(obj, GaVector)
            VariableNum = 0;
            FinalStructure = dataset2cell(obj.ObjectStructure);
            for i = 1:length(obj.Variable.List)
                CurVarInd = cellfun(@(x) ~isempty(x), ...
                    regexp( obj.TextData ,[obj.Variable.List{i} '\>'],'match'));
                [CurVar.Rows, CurVar.Colons] = find(CurVarInd == 1);
                CurVar.Colons = unique(CurVar.Colons);
                obj.ObjectStructure.Properties.VarNames(CurVar.Colons);
                if strcmp(obj.ObjectStructure.Properties.VarNames(CurVar.Colons),...
                        'RuleParameters') == 1
                    ParametersVectors = eval( obj.Invariants.RuleParameters{ ...
                        strcmp(obj.Invariants.RuleName,...
                        obj.ObjectStructure.RuleName{CurVar.Rows})});
                    Parameter = nan(1,length(ParametersVectors));
                    for j = 1:length(ParametersVectors)
                        VariableNum = VariableNum + 1;
                        Parameter(j) = obj.Variable.Matrix{VariableNum}(GaVector(VariableNum));
                    end
                    FinalStructure(CurVar.Rows + 1,...
                        CurVar.Colons) = {int2str(Parameter)};
                else
                    VariableNum = VariableNum + 1;
                    FinalStructure(CurVar.Rows + 1, CurVar.Colons) =...
                        obj.Variable.Matrix{VariableNum}(GaVector(VariableNum));
                end
            end
            FinalStructure = cell2dataset(FinalStructure);
        end
        
        function obj = startGeneticOptimisation(obj)
            fitnessFunction = @( x ) obj.gaSocket( x );
            options = gaoptimset('CrossoverFraction', 0.6,...
                'EliteCount', obj.nVariables*obj.OptimComplexity,...
                'PlotFcns', {@gaplotbestf @gaplotbestindiv...
                @gaplotscores @gaplotstopping}, ...
                'Generations', obj.nVariables*obj.OptimComplexity,... %obj.nVariables*obj.OptimComplexity
                'PopulationSize', obj.nVariables*obj.OptimComplexity*10,...
                'MigrationDirection','forward',...
                'MigrationFraction', 0.2,...
                'MigrationInterval', 10,...
                'StallGenLimit',  obj.nVariables*obj.OptimComplexity ,...
                'OutputFcns', {@getOutputArray}, ...
                'UseParallel', 'always'...
                );
            %'UseParallel', 'always'...
            %Auxilary function for saving of results of genetic algorithm
            %on each step
            function [state, options, changed] = getOutputArray(options,state,~)%Saves best results from each generation
                %Exclude elite individuals from population and scores
                if state.Generation == 0
                    Scores = state.Score;
                    Population = state.Population;
                else
                    Scores = state.Score(options.EliteCount+1:end);
                    Population = state.Population(options.EliteCount+1:end,:);
                    
                end
                
                %Find list of unique individuals in tested population
                [~, Indexes] = unique(Population, 'stable', 'rows');
                
                %Create new scores vector and population matrix with unique
                %values and socres less than 1000
                Scores = Scores(Indexes);
                Population = Population(Indexes,:);
                Population = Population(Scores < 0,:);
                Scores = Scores(Scores < 0);
                
                %Find already included in the database individuals
                if state.Generation == 0
                    IncludedMembers = zeros(1,length(Population));
                else
                    IncludedMembers = ismember( Population, obj.History.TestedGens, 'rows');
                end
                
                %Save unique and not yet included scores and individuals
                try
                    obj.History.TestedGens = uint8([obj.History.TestedGens; Population((~IncludedMembers),:)]);
                    obj.History.TestedGensScores = int16([obj.History.TestedGensScores; Scores(~IncludedMembers)]);
                catch
                    obj.History.TestedGens = uint8(Population((~IncludedMembers),:));
                    obj.History.TestedGensScores = int16(Scores(~IncludedMembers));
                end
                
                try
                    obj.History.AllTestedGens = uint8([obj.History.AllTestedGens; state.Population]);
                    obj.History.AllTestedGensScores = int16([obj.History.AllTestedGensScores; state.Score]);
                catch
                    obj.History.AllTestedGens = uint8(state.Population);
                    obj.History.AllTestedGensScores = int16(state.Score);
                end
                %Save GA state
                obj.History.GAState = state; 
                changed = 0;
                %Show information about current gereration processing
                disp(['GENERATION NUMBER ' num2str(state.Generation)])
                obj.GenerationCalculationTime(state.Generation + 1) = now;
                if state.Generation == 0
                    disp(['PROCESSING TIME ' datestr(now - obj.StartGATime, 'HH:MM:SS')]);
                else
                    disp(['PROCESSING TIME ' datestr(now - obj.GenerationCalculationTime(state.Generation), 'HH:MM:SS')]);
                end
            end
            
            %Start genetic algorithm
            obj.StartGATime = now;
            ga(fitnessFunction, obj.nVariables,[], [],[],[],...
                obj.Bounds.Lower,obj.Bounds.Upper,[], 1:obj.nVariables, options);
            [obj.History.TestedGensScores, Indexes] = sort(obj.History.TestedGensScores);
            obj.History.TestedGens = obj.History.TestedGens(Indexes,:);
            disp(datestr(now - obj.StartGATime, 'HH:MM:SS'))
            obj.ExecutionTime = datestr(now - obj.StartGATime, 'HH:MM:SS');
        end

        function score = gaSocket(obj, GaVector)
%             try
%                 indexes = find(ismember(obj.History.AllTestedGens, GaVector, 'rows'));
%             catch
%                 indexes = [];
%             end
%             if ~isempty(indexes)
%                 score = obj.History.AllTestedGensScores(indexes(1));
%             else
                CurrentObject = positionParent.createObject(obj.getStructure(GaVector));
                Markets = getMarkets(obj, 'InSelection');
                CurrentObject = CurrentObject.getFinalState(Markets);
                if isa(CurrentObject, 'position')
                    if CurrentObject.FinalState.DealsRate >= 1/5;
                        Statistics = statistics(CurrentObject);
                        score = Statistics.(obj.ObjectiveParameter);
                    else
                        score = 1000;
                    end
                else
                    if min(cellfun(@(x) x.FinalState.DealsRate, CurrentObject.Fields)) >= 1/5;
                        Statistics = statistics(CurrentObject);
                        score = Statistics.(obj.ObjectiveParameter);
                    else
                        score = 1000;
                    end
                end
%             end
        end
        
        function Markets = getMarkets(obj, Selection)
            MarketNames = unique(obj.ObjectStructure.MarketName);
            Markets = cell(1,length(MarketNames));
            for i=1:length(MarketNames)
                Markets{i} =  obj.MarketList.(MarketNames{i}).(Selection);
            end
        end
        
        function plotOptResults(obj)
            obj.ResultsPlot = figure;
            plot(obj.History.TestedGensScores, 'blueo')
            obj.ProfitPlot = figure;
            f = @(obj2, event_obj)processing.plotOptResults(obj2,event_obj, obj);           
            dcm_obj = datacursormode(obj.ResultsPlot);
            set(dcm_obj, 'Enable', 'on','SnapToDataVertex','off', 'UpdateFcn', f)
            
%             figure
%             hold on
%             for i = 1:10
%                 CurrentObject = positionParent.createObject(...
%                     obj.getStructure(obj.History.TestedGens(i,:)));
%                 Market = getMarkets(obj, 'InSelection');
%                 CurrentObject = CurrentObject.getFinalState(Market);
%                 plot(CurrentObject.FinalState.ProfitVector, '-r')
%             end
        end
        
        %         function obj = testOutSelection(obj)
        %             disp('EVALUATION OF OUT SELECTION SCORES')
        %             [~, Indexes] = unique([obj.History.TestedGens obj.History.TestedGensScores], 'rows');
        %             OutSelectionSize = ceil(...
        %                 length(Indexes)/obj.OutSelectionTestReductionCoefficient);
        % %             OutSelectionSize = ceil(length(Indexes));
        %             obj.History.BestScoresInSelection = obj.History.TestedGensScores(Indexes(1:OutSelectionSize));
        %             obj.History.BestIndividualsInSelection = obj.History.TestedGens(Indexes(1:OutSelectionSize),:);
        %
        %             BestOutSelectionScores = zeros(  OutSelectionSize,1);
        %             BestOutSelectionStates = cell(  OutSelectionSize,1);
        %             BestInSelectionStates = cell(  OutSelectionSize,1);
        %             MarketsOut = getMarkets(obj, 'OutSelection');
        %             MarketsIn = getMarkets(obj, 'InSelection');
        %             parfor i=1:OutSelectionSize
        %                 tic
        %                 OutSelectionObject = positionParent.createObject(...
        %                     obj.getStructure(obj.History.BestIndividualsInSelection(i,:)));
        %                 OutSelectionObject = OutSelectionObject.getFinalState(MarketsOut);
        %                 Statistics = statistics(OutSelectionObject);
        %                 BestOutSelectionStates{i} = OutSelectionObject.FinalState;
        %                 BestOutSelectionScores(i) = Statistics.(obj.ObjectiveParameter);
        %
        %                 InSelectionObject = positionParent.createObject(...
        %                     obj.getStructure(obj.History.BestIndividualsInSelection(i,:)));
        %                 InSelectionObject = InSelectionObject.getFinalState(MarketsIn);
        %                 BestInSelectionStates{i} = InSelectionObject.FinalState;
        %                 toc
        %             end
        %             obj.History.BestOutSelectionScores = int16(BestOutSelectionScores);
        %             obj.History.BestOutSelectionStates = BestOutSelectionStates;
        %             obj.History.BestInSelectionStates = BestInSelectionStates;
        %             [obj.History.MedianScoreOOS, obj.History.MedianIndexesOOS] =...
        %                 sort( - real( ( single(obj.History.BestScoresInSelection)...
        %                 .*single(obj.History.BestOutSelectionScores )) .^0.5 ));
        %             obj.History.OutSelectionFilteredIndexes =  obj.History.MedianIndexesOOS(...
        %                 1:fix(length(obj.History.MedianIndexesOOS)/10));
        %             obj.History.OutSelectionFilteredIndividuals =...
        %                 obj.History.BestIndividualsInSelection(...
        %                 obj.History.OutSelectionFilteredIndexes,:);
        %         end
        %
        %         function obj = testOutMarket(obj)
        %             OutOfMarketNames = setdiff(...
        %                 obj.Invariants.MarketName, unique(...
        %                 obj.ObjectStructure.MarketName));
        %             BestOutOfMarketScores = zeros(...
        %                 size(obj.History.OutSelectionFilteredIndividuals, 1),...
        %                 length(OutOfMarketNames));
        %             BestOutOfMarketStates = cell(...
        %                 size(obj.History.OutSelectionFilteredIndividuals, 1),...
        %                 length(OutOfMarketNames));
        %             for i=1:length(OutOfMarketNames)
        %                 CurrentMarket = obj.MarketList.(OutOfMarketNames{i}).OutSelection;
        %                 disp(['EVALUATION RESULTS FOR MARKET ' OutOfMarketNames{i}])
        %                 for j=1:size(obj.History.OutSelectionFilteredIndividuals, 1)
        %                     tic
        %                     CurrentObject = positionParent.createObject(...
        %                         obj.getStructure(obj.History.OutSelectionFilteredIndividuals(j,:)));
        %                     CurrentObject = CurrentObject.getFinalState(CurrentMarket);
        %                     BestOutOfMarketStates{j,i} = CurrentObject.FinalState;
        %                     Statistics = statistics(CurrentObject);
        %                     BestOutOfMarketScores(j,i) = Statistics.(obj.ObjectiveParameter);
        %                     toc
        %                 end
        %             end
        %             obj.History.BestOutOfMarketStates = BestOutOfMarketStates;
        %             obj.History.BestOutOfMarketScores = BestOutOfMarketScores;
        %         end
        %
        %         function obj = testSyntheticMarket(obj, Selection)
        %             MarketsOut = getMarkets(obj, Selection);
        %             for i=1:100
        %                 CurrentMarket = syntheticData(MarketsOut{1}).MarketObject;
        %                 disp(['EVALUATION RESULTS FOR SYNTHETIC MARKET ' num2str(i)])
        %                 parfor j=1:size(obj.History.OutSelectionFilteredIndividuals, 1)
        %                     tic
        %                     CurrentObject = positionParent.createObject(...
        %                         obj.getStructure(obj.History.OutSelectionFilteredIndividuals(j,:)));
        %                     CurrentObject = CurrentObject.getFinalState(CurrentMarket);
        %                     Statistics = statistics(CurrentObject);
        %                     SyntheticResult(j,i) = Statistics.(obj.ObjectiveParameter);
        %                     toc
        %                 end
        %             end
        %             obj.History.(['SyntheticResult',Selection]) =  SyntheticResult;
        %         end
        %
        %         function obj = getFullTimeProfitVectors(obj)
        %             TimeIntervalFull =  {'01-Jan-2009' '31-Dec-2013'};
        %             parfor j=1:length(obj.History.OutSelectionFilteredIndividuals)
        %                 tic
        %                 CurrentObject = positionParent.createObject(...
        %                     obj.getStructure(obj.History.OutSelectionFilteredIndividuals(j,:)));
        %                 CurrentObject = CurrentObject.getFinalState(TimeIntervalFull);
        %                 Statistics = statistics(CurrentObject);
        %                 FullTimeScore(j) = Statistics.(obj.ObjectiveParameter);
        %                 FullTimeVector(:,j) = CurrentObject.FinalState.ProfitVector;
        %                 toc
        %             end
        %             obj.History.FullTimeScore = FullTimeScore;
        %             obj.History.FullTimeVector = FullTimeVector;
        %         end
        %
        %         function optimisePortfolio(obj, Return)
        %             Correlation = corrcoef(obj.History.FullTimeVector);
        %             stdDev_return = std(obj.History.FullTimeVector)';
        %             mean_return = mean(obj.History.FullTimeVector)';
        %             Covariance = Correlation .* (stdDev_return * stdDev_return');
        %             nAssets = numel(mean_return); r =Return;
        %             Aeq = ones(1,nAssets); beq = 1;
        %             Aineq = -mean_return'; bineq = -r;
        %             lb = zeros(nAssets,1); ub = ones(nAssets,1);
        %             c = zeros(nAssets,1);
        %             options = optimoptions('quadprog','Algorithm','interior-point-convex');
        %             options = optimoptions(options,'Display','iter','TolFun',1e-10);
        %             [x1,fval1] = quadprog(Covariance,c,Aineq,bineq,Aeq,beq,lb,ub,[],options);
        %             figure
        %             plot(x1, 'ro')
        %             data = obj.History.FullTimeVector(:,x1>0.01);
        %             mult = x1(x1>0.01);
        %             clear res
        %             for i = 1:size(data, 2)
        %                 res(:,i)=data(:,i)*mult(i);
        %             end
        %             figure
        %             plot(sum(res,2),'r.')
        %             hold on
        %             plot(res)
        %         end
        %
        %         function plotOutSelection(obj)
        %             obj.ProfitPlot = figure;
        %             obj.ResultsPlot = figure;
        %             figure(obj.ResultsPlot)
        %             plot(obj.History.MedianScoreOOS, 'blueo')
        %             hold on
        %             plot(obj.History.BestOutSelectionScores(obj.History.MedianIndexesOOS), 'go')
        %             plot(obj.History.BestScoresInSelection(obj.History.MedianIndexesOOS), 'ro')
        % %             plot(median(obj.History.SyntheticResultOutSelection'), 'mo')
        % %             plot(median(obj.History.SyntheticResultInSelection'), 'co')
        % %             legend('Median Score','Out Selection Score','In Selection Score',...
        % %                 'Synthetic Out Selection Mean','Synthetic In Selection Mean','Location','SouthEast');
        %             f = @(obj2, event_obj)plotOutSelectionResults(obj2,event_obj, obj);
        %             dcm_obj = datacursormode(obj.ResultsPlot);
        %             set(dcm_obj, 'Enable', 'on','SnapToDataVertex','off', 'UpdateFcn', f)
        %         end
        %
        %         function plotOutMarket(obj)
        %             Colors = 'brgymck';
        %             obj.ProfitPlot = figure;
        %             obj.ResultsPlot = figure;
        %             figure(obj.ResultsPlot)
        %             plot(obj.History.MedianScoreOOS(...
        %                 1:length(obj.History.OutSelectionFilteredIndexes)), [Colors(end) 'o'])
        %             for i=1:size(obj.History.BestOutOfMarketScores, 2)
        %                 hold on
        %                 plot(obj.History.BestOutOfMarketScores(:,i), [Colors(i) 'o'])
        %             end
        %             f = @(obj2, event_obj)plotOutMarketResults(obj2,event_obj, obj);
        %             dcm_obj = datacursormode(obj.ResultsPlot);
        %             set(dcm_obj, 'Enable', 'on','SnapToDataVertex','off', 'UpdateFcn', f)
        %         end
        %
        function saveResults(obj)
            save([obj.ResDataFolder cell2mat(...
                regexp(obj.TaskName, '(.*)(?=_optimisation.xlsx)', 'match'))...
                '_' obj.ObjectiveParameter '_'...
                datestr(now, 'dd-mmm-yyyy_HHMMSS') '.mat'], 'obj', '-v7.3')
        end

        function saveToXls(obj, PositionNumber, FileName)
            ObjectToSave = positionParent.createObject(...
                obj.getStructure(obj.History.BestIndividualsInSelection(...
                obj.History.MedianIndexesOOS(PositionNumber),:)));
            xlswrite(FileName,dataset2cell(ObjectToSave.ObjectStructure));
        end
        
    end
    
end


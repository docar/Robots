classdef evalOutSel
    %EVALOUTSEL Summary of this class goes here
    %   Detailed explanation goes here
    properties(Constant)
        SelectPopSize = 50;
    end
    properties
        OptTaskObj
        TimeIntervalOut
        InSelScores
        OutSelScores
        AvScores
        RealScores
        SelInScores
        SelOutScores
        SelGens
        ResultsPlot
        ProfitPlotIn
        ProfitPlotOut
        TimeIntervalReal
    end
    
    methods
        function obj = evalOutSel(varargin) %constructor
            if nargin == 0
                obj.OptTaskObj = [];
                obj.TimeIntervalOut= [];
                obj.InSelScores= [];
                obj.OutSelScores= [];
                obj.AvScores= [];
                obj.SelInScores= [];
                obj.SelOutScores= [];
                obj.SelGens= [];
                obj.ResultsPlot= [];
                obj.ProfitPlot= [];
                %disp('ERROR NOT ENOUGH INPUT ARGUMENTS')
            elseif ~isa(varargin{1}, 'optimisationTask')
                disp('ERROR INPUT ARGUMENT HAS TO BE optimisationTask TYPE')
            elseif isa(varargin{1}, 'evalOutSel')
                obj = varargin{1};
            else
                obj.OptTaskObj = varargin{1};
                %obj.TimeIntervalOut = varargin{2};
                %obj = obj.evalOutSelScores;
            end
        end %constructor
        
        function obj = evalOutSelScores(obj, TimeIntervalOut) %Evaluation of out selection scores
            obj.TimeIntervalOut = TimeIntervalOut;
            tic
            disp('LOAD OUT SELECTION MARKET')            
            obj.OptTaskObj.MarketList.(cell2mat(unique(obj.OptTaskObj.ObjectStructure.MarketName))).OutSelection = marketData(...
                cell2mat(unique(obj.OptTaskObj.ObjectStructure.MarketName)), obj.TimeIntervalOut );
            toc
            %MarketIn = obj.OptTaskObj.getMarkets('InSelection');
            MarketOut = obj.OptTaskObj.getMarkets('OutSelection');
            tic
            parfor i=1:length(obj.OptTaskObj.History.TestedGens)
                tic
%                disp(['Evaluation gen ' num2str(i) ' of ' num2str(length(obj.OptTaskObj.History.TestedGens))])
                CurrentObject = positionParent.createObject(...
                    obj.OptTaskObj.getStructure(obj.OptTaskObj.History.TestedGens(i,:)));
%                 InSelObject = CurrentObject.getFinalState(MarketIn); 
%                 Statistics = statistics(InSelObject);
%                 InSelStates{i} = InSelObject.FinalState;
%                 InSelScores(i) = Statistics.(obj.OptTaskObj.ObjectiveParameter);
                
                OutSelObject = CurrentObject.getFinalState(MarketOut); 
                Statistics = statistics(OutSelObject);
                %OutSelStates{i} = OutSelObject.FinalState;
                OutSelScores(i) = Statistics.(obj.OptTaskObj.ObjectiveParameter);
                toc
            end
            
            %obj.InSelStates = InSelStates;
            obj.InSelScores = obj.OptTaskObj.History.TestedGensScores;
            
            %obj.OutSelStates = OutSelStates;
            obj.OutSelScores = OutSelScores;
            
            disp(['Total evaluation time ' num2str(toc)])
        end

        function obj = selectPositions(obj) % Selection of 300 best positions 
            %(from results of in and out selections evaluations)
            i = 0;
            InitTreshold = min(obj.InSelScores);
            ValidGens = 0;
            while ValidGens < obj.SelectPopSize

                InSelInd = obj.InSelScores(:) <= InitTreshold + i;
                OutSelInd = obj.OutSelScores(:) <= InitTreshold + i;
                FinalInd = InSelInd & OutSelInd;
                ValidGens = length(find(FinalInd == 1));

                i = i + 1;
                if i > abs(InitTreshold)
                    break
                end
            end

            SelGens = obj.OptTaskObj.History.TestedGens(FinalInd,:);
            SelInScores = double(obj.InSelScores(FinalInd));
            SelOutScores = obj.OutSelScores(FinalInd);
            AvScores = (SelInScores(:) + SelOutScores(:)) /2;
            [obj.AvScores, ib] = sort(AvScores);
            obj.SelInScores = SelInScores(ib);
            obj.SelOutScores = SelOutScores(ib);
            obj.SelGens = SelGens(ib,:);
        end
        
        function obj = evalRealTime(obj, TimeIntervalReal)
            
            obj.TimeIntervalReal = TimeIntervalReal;
            tic
            disp('LOAD REAL MARKET')            
            MarketReal = marketData(...
                cell2mat(unique(obj.OptTaskObj.ObjectStructure.MarketName)), obj.TimeIntervalReal );
            toc
            
            tic
            parfor i=1:length(obj.SelGens)
                tic
%                disp(['Evaluation gen ' num2str(i) ' of ' num2str(length(obj.OptTaskObj.History.TestedGens))])
                CurrentObject = positionParent.createObject(...
                    obj.OptTaskObj.getStructure(obj.SelGens(i,:)));
%                 InSelObject = CurrentObject.getFinalState(MarketIn); 
%                 Statistics = statistics(InSelObject);
%                 InSelStates{i} = InSelObject.FinalState;
%                 InSelScores(i) = Statistics.(obj.OptTaskObj.ObjectiveParameter);
                
                CurrentObject = CurrentObject.getFinalState(MarketReal); 
                Statistics = statistics(CurrentObject);
                %OutSelStates{i} = OutSelObject.FinalState;
                RealScores(i) = Statistics.(obj.OptTaskObj.ObjectiveParameter);
                toc
            end
            
            %obj.InSelStates = InSelStates;
            %obj.RealScores = obj.OptTaskObj.History.TestedGensScores;
            
            %obj.OutSelStates = OutSelStates;
            obj.RealScores = RealScores;
            
            disp(['Total evaluation time ' num2str(toc)])
            
        end
        
        
        function plotSelPositions(obj) %Plotting of in and out selection profit vectors
            obj.ResultsPlot = figure;
            plot(obj.SelInScores, 'ro')
            hold on
            plot(obj.SelOutScores, 'bo')
            plot(obj.AvScores, '-g', 'LineWidth', 5)
            if ~isempty(obj.RealScores)
                plot(obj.RealScores, 'blacko')
                legend('InSelectionScores', 'OutSelectionScores', 'AverageScores', 'RealScores', 'Location', 'SouthEast')
            else
                legend('InSelectionScores', 'OutSelectionScores', 'AverageScores', 'Location', 'SouthEast')
            end
            obj.ProfitPlotIn = figure;
            obj.ProfitPlotOut = figure;
            f = @(obj2, event_obj)processing.plotSelPositions(obj2,event_obj, obj);
            dcm_obj = datacursormode(obj.ResultsPlot);
            set(dcm_obj, 'Enable', 'on','SnapToDataVertex','off', 'UpdateFcn', f)
        end
        
        
        
    end
    
end


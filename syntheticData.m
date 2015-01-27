classdef syntheticData
    %SYNTHETICDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        TimeFrames = [1 5 10 15 30 60];
    end
    
    properties
        SeedPrices
        SynthPrices
        MarketObject
        SynthObject
    end
    
    methods
        function obj = syntheticData(varargin)
            obj.MarketObject =  varargin{1};
            obj.SeedPrices = obj.MarketObject.DataBase{1}.prices;
            minPrice = -1;
            while (minPrice < 0)
                obj = generatePrices(obj);
                minPrice = min(min(obj.SynthPrices));
                if minPrice < 0
                    disp('ERROR MIN PRICE < 0 GENERATING NEW PRICES')
                end
            end
            obj = createDataBase(obj);
        end
        
        function obj = generatePrices(obj)
            
            EndOfDayRows = obj.MarketObject.DataBase{1}.endOfDayIndexes(1:end-1);
            InDayRows = setxor(2:obj.MarketObject.nTicks(1), EndOfDayRows);
            LastBarMat = repmat(circshift(obj.SeedPrices(:,4),[1 -1]),[1 4]);
            Differences = obj.SeedPrices - LastBarMat;
            Differences =  Differences(2:end,:);
            InterDayGaps = Differences(EndOfDayRows+2,:);
            InDayDiff = Differences;
            InDayDiff(EndOfDayRows+2,:) = [];
            
            RndSeedInsideDay = fix(rand(length(InDayDiff),1)*length(InDayDiff));
            Differences(InDayRows,:) = InDayDiff(RndSeedInsideDay+1,:);
            
            RndSeedInterDay = fix(rand(length(InterDayGaps),1)*length(InterDayGaps));
            Differences(EndOfDayRows,:) = InterDayGaps(RndSeedInterDay+1,:);
            
            obj.SynthPrices = zeros(size(obj.SeedPrices));
            obj.SynthPrices(1,:) = obj.SeedPrices(1,:);

            for i = 1:length(obj.SynthPrices) - 1
                obj.SynthPrices(i+1,:) = obj.SynthPrices(i,4)...
                    + Differences(i,:);
            end

        end
        
        function obj = createDataBase(obj)        
            OneMinuteData = obj.MarketObject.DataBase{1};
            OneMinuteData.prices =  obj.SynthPrices;
            SynthDataBase = DataBase.generateHighTF( obj.TimeFrames, OneMinuteData );
            obj.MarketObject = obj.MarketObject.changeDataBase(SynthDataBase);
        end
    end
    
end


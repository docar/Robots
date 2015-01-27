classdef createContractData
    
    properties (Constant)
        TimeFrames = DataBase.readSetup('TimeFrames');
        DBContractDataFolder = DataBase.readSetup('DBContractDataFolder');
    end
    
    methods
        function obj = createContractData(varargin)
            varargin{1} = cell2mat(varargin{1});
            OneMinuteData.prices = varargin{1}(:,1:4);
            OneMinuteData.minuteNumbers = datenum(num2str(varargin{1}(:, 6)), 'YYYYmmDDHHMMSS');
            OneMinuteData.volume = uint32(varargin{1}(:,5));
            OneMinuteData.deals = uint32(varargin{1}(:,7));
            dataBar = DataBase.generateHighTF( obj.TimeFrames, OneMinuteData );          
            save([obj.DBContractDataFolder varargin{2}], 'dataBar')
        end
    end
    
end


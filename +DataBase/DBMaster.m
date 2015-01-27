classdef DBMaster < handle
    
    properties (Constant)
        DBCacheFolder  = DataBase.readSetup('DBCacheFolder');
        FtpRootFolder  = DataBase.readSetup('FtpRootFolder');
        Years  = DataBase.readSetup('Years');
        FtpObject = ftp(DataBase.readSetup('FtpName'))
        Connection = database(DataBase.readSetup('DBName'),...
            'root','selena', 'Vendor','MySQL')
        Excel = actxserver('excel.application')
    end
    
    properties
        ProcessedFiles
        FtpFiles
        CacheFiles
        CorruptedFiles
        CurFtpFolder
        CurCacheFolder
        MissFiles
        CurYear
        FullCacheList
    end
    
    methods
        
        function obj = DBMaster(varargin) %constructor
            disp('START DATABASE UPDATE')
            disp( datestr(now))
            obj.UpdateCache;
            close(obj.FtpObject);
            %obj.processMissFiles;
            %if ~isempty(obj.MissFiles)
               % DataBase.MinutesExtractor
               % DataBase.ContractInfo
            %end
            disp('FINISH DATABASE UPDATE')
            disp(datestr(now))
        end %constructor
        
        function obj = UpdateCache(obj)
            obj.FullCacheList = {};
            for i =1:length(obj.Years)
                obj.CurYear = obj.Years(i);
                UnCachedFiles = 1;
                while ~isempty(UnCachedFiles)
                    obj.getCacheFileList;
                    obj.getFtpFileList;
                    UnCachedFiles = setxor(obj.FtpFiles, obj.CacheFiles);
                    cd(obj.FtpObject, obj.CurFtpFolder);
                    for i=1:length(UnCachedFiles)
                        disp('DONWLOADING UNCACHED FILE')
                        disp([obj.CurFtpFolder UnCachedFiles{i}])
                        try
                            mget(obj.FtpObject,...
                                UnCachedFiles{i}, obj.CurCacheFolder);
                        catch expr
                            disp(expr.Message)
                        end
                    end
                end
                obj.FullCacheList = [obj.FullCacheList...
                    cellfun(@(x) [obj.CurCacheFolder x],...
                    obj.CacheFiles, 'UniformOutput', false)];
            end
        end
        
        function obj = getCacheFileList(obj)
            obj.CurCacheFolder = [obj.DBCacheFolder ...
                num2str(obj.CurYear) '\'];
            RawList = struct2cell( dir([obj.CurCacheFolder '*.zip']));
            obj.CacheFiles = RawList(1,:);
        end
        
        function obj = getFtpFileList(obj)
            obj.CurFtpFolder = [obj.FtpRootFolder num2str(obj.CurYear) '/'];
            CurYearFiles = struct2cell(dir(obj.FtpObject, [obj.CurFtpFolder '*.*']));
            CurYearFiles = cellfun(@(x) cell2mat(...
                regexpi(x,'f\d.*|ft\d.*|fe\d.*|','match')), CurYearFiles(1,:),...
                'UniformOutput',false);
            obj.FtpFiles = CurYearFiles(cellfun(@(x) ~isempty(x), CurYearFiles));
        end
        
        function obj = processMissFiles(obj)
            obj.ProcessedFiles = getDbFileList(obj, 'processed_files');
            obj.CorruptedFiles = getDbFileList(obj, 'error_log');
            obj.MissFiles = setdiff(obj.FullCacheList,...
                [obj.CorruptedFiles;obj.ProcessedFiles]);
            parfor i=1:length(obj.MissFiles)
                FileNames =[];
                tic
                expr = 'Result Message';
                while ~isempty(expr)
                    expr = [];
                    try
                        FileNames = unzip(obj.MissFiles{i},...
                            [obj.DBCacheFolder 'temp\']);
                    catch expr
                        disp(expr.message)
                    end
                end
                ExtractionTime = toc;
                tic
                Result ='';
                for j=1:length(FileNames)
                    if regexpi(FileNames{j}, '.*\.csv$') == 1
                        Result = [Result DataBase.readCsv(obj, FileNames{j})];
                    elseif regexpi(FileNames{j}, '.*\.xls$') == 1
                        Result = [Result DataBase.readXls(obj, FileNames{j})];
                    else
                        fprintf(2, 'UNKNOWN FILE TYPE\r\n');
                        fprintf(2, [FileNames{j} '\r\n']);
                    end
                    delete(FileNames{j})
                end
                disp(obj.MissFiles{i})
                disp(['EXTRACTION TIME ' num2str(ExtractionTime)])
                if isempty(Result)
                    obj.addToDbFileList(obj.MissFiles{i});
                    disp('DATA PROCESSING IS OK')
                    disp(['PROCESSING TIME ' num2str(toc)])
                else
                    obj.addErrorToLog(Result, obj.MissFiles{i});
                    fprintf(2, 'ERROR DURING DATA PROCESSING\r\n');
                    fprintf(2, [Result '\r\n']);
                end
                disp(['FILE ' num2str(length(getDbFileList(obj, 'processed_files')))...
                    ' OF ' num2str(length(obj.FullCacheList))...
                    ' ' datestr(now)])
                disp('-------------------------------------------------------------------')
            end
            
        end
        
        function FileList = getDbFileList(obj, FileTable)
            try
                FileList = fetch(obj.Connection, [...
                    ' SELECT name FROM '...
                    FileTable...
                    ]);
            catch expr
                disp(expr.message)
                FileList = {};
            end
        end
        
        function obj = addToDbFileList(obj, FileName)
            exec(obj.Connection, [...
                ' CREATE TABLE IF NOT EXISTS '...
                ' processed_files ('...
                ' name CHAR(50), '...
                ' PRIMARY KEY (name))'...
                ' ENGINE = MyISAM'...
                ' DEFAULT CHARSET=utf8'...
                ' COLLATE utf8_bin'...
                ' ROW_FORMAT = FIXED'...
                ]);
            exec(obj.Connection, [...
                ' INSERT INTO processed_files '...
                '(name) VALUES '...
                '(''' strrep(FileName, '\', '\\') ''')'...
                ]);
        end
        
        function obj = addErrorToLog(obj, Result, FileName)
            exec(obj.Connection, [...
                ' CREATE TABLE IF NOT EXISTS '...
                ' error_log ('...
                ' name CHAR(50), '...
                ' error CHAR(255), '...
                ' PRIMARY KEY (name))'...
                ' ENGINE = MyISAM'...
                ' DEFAULT CHARSET=utf8'...
                ' COLLATE utf8_bin'...
                ' ROW_FORMAT = FIXED'...
                ]);
            exec(obj.Connection, [...
                ' INSERT INTO error_log '...
                '(name, error) VALUES '...
                '(''' strrep(FileName, '\', '\\') ''', ''' strrep(Result, '''','') ''')'...
                ]);
        end
        
    end
end






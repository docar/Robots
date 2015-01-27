function Result = readSetup(PropertyName)
    fileID = fopen('setup.ini');
    C = textscan(fileID,'%s %s');
    fclose(fileID);
    cellfun(@(x, y) assignin('caller', x, y), C{1}, C{2});
    Years = eval(Years);
    UpdateTimes = regexp(UpdateTimes, ',', 'split');
    OptimComplexity = str2num(OptimComplexity);
    TestList = regexp(TestList, ',', 'split');
    TimeFrames = eval(TimeFrames);
    Result = eval(PropertyName);
end


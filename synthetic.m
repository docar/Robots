clc
clear all

path(path, [cd '\rules']);
path(path, [cd '\tasks']);
obj.TimeFrames = [1 5 10 15 30 60];
load('OptimisationResults.mat')
prices = p.MarketList{1}.DataBase{1}.prices;
tic
LastBarMat = repmat(circshift(prices(:,4),[1 -1]),[1 4]);
Differences = prices - LastBarMat;
Differences = Differences(2:end,:);

RandomSeed = fix(rand(length(Differences),1)*length(Differences));
RandomisedDifferences = Differences(RandomSeed+1,:);

synth = zeros(size(prices));
synth(1,:) = prices(1,:);

for i=1:length(synth) - 1
    synth(i+1,:) = synth(i,4) + RandomisedDifferences(i,:);
end
% figure
% %hist(synth(:,4),1000)
% plot(synth(:,4))
toc
dataBar{1} = p.MarketList{1}.DataBase{1};
dataBar{1}.prices = synth;
TimeNums = dataBar{1}.minuteNumbers;
FirstDay = fix(min(dataBar{1}.minuteNumbers));
LastDay = fix(max(dataBar{1}.minuteNumbers));
counter = 0;
     for i=FirstDay:LastDay
         counter = counter +1;
         Days{counter} = datestr(i, 'YYYYmmDD');    
     end
     Hours = arrayfun(@(x) strrep(sprintf('%1.1f', x/10),'.',''), 9:23, 'UniformOutput' , false);
     tic
     times = str2num(datestr(dataBar{1}.minuteNumbers, 'YYYYmmDDHHMM'));
     toc
     for i=2:length(obj.TimeFrames)
        bar = 0;
        Minutes = arrayfun(@(x) strrep(sprintf('%1.1f', x/10),'.',''), 0:obj.TimeFrames(i):59, 'UniformOutput' , false);
        HoursMinutes = timeGen( Hours, Minutes );
        TimeMesh{i-1} =  timeGen( Days, HoursMinutes );
        tic
            for j=1:length(TimeMesh{i-1})-1
                Res = find( times >= str2num(TimeMesh{i-1}{j}) &  times <  str2num(TimeMesh{i-1}{j+1}));
                if ~isempty(Res)
                    bar = bar+1;
                    dataBar{i}.prices(bar, 1) = dataBar{1}.prices(Res(1),1);
                    dataBar{i}.prices(bar, 2) = max(max(dataBar{1}.prices(Res,1:4)));
                    dataBar{i}.prices(bar, 3) = min(min(dataBar{1}.prices(Res,1:4)));
                    dataBar{i}.prices(bar, 4) = dataBar{1}.prices(Res(end),4);      
                    dataBar{i}.minuteNumbers(bar,1:length(Res)) = TimeNums(Res);
                    dataBar{i}.volume(bar) = sum(dataBar{1}.volume(Res));     
                    dataBar{i}.deals(bar) = sum(dataBar{1}.deals(Res));     
                end
            end
        toc
     end
        testVec = datenum(TimeMesh{1}, 'YYYYmmDDHHMM');
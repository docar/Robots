clc
clear all
tic
Connection = database(DataBase.readSetup('DBName'),...
    'root','selena', 'Vendor','MySQL');

AllTickers = fetch(Connection, [...
    ' SELECT * '...
    ' FROM tickers'...
    ]);

FuturesData = strtrim( fetch(Connection, [...
    ' SELECT DISTINCT ticker, delivery_date '...
    ' FROM futures '...
    ]));

TimeInterval =  {'01-Jan-2008' '31-Jan-2008'};
TimeInterval = datenum(TimeInterval);

indexes = cell2mat( cellfun( @(x) ...
    ~isempty(regexpi(x, 'RTS-.*', 'match')),...
    FuturesData(:,1), 'UniformOutput', false));

AllTickerData = FuturesData(indexes,:);
Dates = datenum(AllTickerData(:,2), 'dd.mm.yyyy');
SortedDates = sort(Dates);

FirstTickerDate = min( find( SortedDates > TimeInterval(1)));
LastTickerDate = max( find( SortedDates < TimeInterval(2)));
if length(SortedDates) > LastTickerDate
    LastTickerDate = LastTickerDate + 1;
end


RequestedDates = SortedDates(FirstTickerDate:LastTickerDate);
[~, indexes, ~] = intersect(Dates, RequestedDates);

RequestedTickers = AllTickerData(indexes,1);

for i = 2:length(RequestedDates)
    BeginInterval(i) = RequestedDates(i-1);
    EndInterval(i-1) = RequestedDates(i-1) - 1;
end
BeginInterval(1) = TimeInterval(1);
EndInterval(i) = TimeInterval(2);
if isempty(EndInterval)
    EndInterval =  TimeInterval(2);
end
Price = [];
toc
tic 

% for i = 1:length(RequestedTickers)         
% Price = [Price; cell2mat(fetch(Connection, [...
%     ' SELECT open, high, low, close, time, volume, deals '...
%     ' FROM `' RequestedTickers{i} '_1min`'...
%     ' WHERE time BETWEEN ' [datestr(BeginInterval(i), 'YYYYmmDD') '0000'] ' AND '...
%     [datestr(EndInterval(i), 'YYYYmmDD') '0000']  ' '...
%     ]))];
% end

toc


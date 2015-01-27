clc
%clear all
% path(path, [cd '\rules']);
% path(path, [cd '\tasks']);
obj.TimeFrames = [1 5 10 15 30 60];

%a = [0:3 6:7 11:14 21:23 26:29 31:34];
%dd = cumsum(diff(a));
SynthDataBase = cell(1, length(obj.TimeFrames));
SynthDataBase{1} = obj.MarketObject.DataBase{1};
for i = 2 : length(obj.TimeFrames)
    [~,ia,~] = unique(fix(cumsum(round(diff(...
        SynthDataBase{1}.minuteNumbers)/(1/(24*60))))/obj.TimeFrames(i)));
    ia(2:end) = ia(2:end) + 1;
    ib = circshift(ia, [-1 1]) - 1;
    ib(end) = length(SynthDataBase{1}.minuteNumbers);

    newBar.minuteNumbers = zeros(length(ia),obj.TimeFrames(i));
    minutes = [diff(ia); length(SynthDataBase{1}.minuteNumbers) - ia(end) + 1];

    newBar.prices = zeros(length(ia),4);
    newBar.prices(:,1) = SynthDataBase{1}.prices(ia,1);
    newBar.prices(:,4) = SynthDataBase{1}.prices(ib,4);
    minPrices = min(SynthDataBase{1}.prices, [],2);
    maxPrices = max(SynthDataBase{1}.prices, [],2);

    Deals = cumsum(SynthDataBase{1}.deals);
    Deals = Deals(ib);
    newBar.deals = [Deals(1); diff(Deals)];

    Volume = cumsum(SynthDataBase{1}.volume);
    Volume = Volume(ib);
    newBar.volume = [Volume(1); diff(Volume)];

    for j=1:length(ia) 
        newBar.prices(j, 2:3) = [max(maxPrices( ia( j ) : ib( j )))...
            min(minPrices( ia( j ) : ib( j )))]; 
        newBar.minuteNumbers(j,1:minutes(j)) =...
            dataBar{1}.minuteNumbers( ia( j ) : ib( j ));
    end
    SynthDataBase{i} = newBar;
end


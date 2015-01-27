clc
clear all
load('TFGenerationTest.mat')
generatedMinutePriceData = res.DataBase{1, 5}.prices(:,1);
ReferenceMinutePriceData = VarName5;

TimeFrames = DataBase.readSetup('TimeFrames');
TimeConstant = TimeFrames(5)/(24*60*60);
OneMinuteData = res.DataBase{1};

%Old formula for calculation of number of bar, doesn't work with seconds
%time frame due to error in rounding
%NumBar = uint64(floor((OneMinuteData.minuteNumbers)/TimeConstant));

%New formula for calculation of number of ber, work with seconds timeframe,
%rounding error corrected by addition of 1e-6 to the results of division of
%minute number to time frame constant
NumBar = uint64(floor(OneMinuteData.minuteNumbers/TimeConstant+1e-6));
%Find indexes of the first and last minutes of the bar
[~,ia,~] = unique( NumBar, 'first' );
[~,ib,~] = unique( NumBar, 'last' );

newBar.minuteNumbers = zeros(length(ia),TimeFrames(5));
find(diff(ia)>60)
minutes = [diff(ia); length(OneMinuteData.minuteNumbers) - ia(end) + 1];
    
    newBar.prices = single(zeros(length(ia),4));
    newBar.prices(:,1) = OneMinuteData.prices(ia,1);
    newBar.prices(:,4) = OneMinuteData.prices(ib,4);
    minPrices = min(OneMinuteData.prices, [],2);
    maxPrices = max(OneMinuteData.prices, [],2);
    
    Deals = cumsum(cast(OneMinuteData.deals, 'double'));
    Deals = Deals(ib);
    newBar.deals = [Deals(1); diff(Deals)];
    
    Volume = cumsum(cast(OneMinuteData.volume, 'double'));
    Volume = Volume(ib);
    newBar.volume = [Volume(1); diff(Volume)];
    for j=1:length(ia)
        newBar.prices(j, 2:3) = [max(maxPrices( ia( j ) : ib( j )))...
            min(minPrices( ia( j ) : ib( j )))];
        newBar.minuteNumbers(j,1:minutes(j)) =...
            OneMinuteData.minuteNumbers( ia( j ) : ib( j ));
    end
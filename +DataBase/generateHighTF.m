function DataBase = generateHighTF( TimeFrames, OneMinuteData )

%Function generates higher timeframe bars form 1 minute data.
%Input parameter: TimeFrames - vector of timeframes of final data base
%(TimeFrames = [1 5 10 15 30 60]
%OneMinuteData - structure with prices, minute numbers etc. for 1 minute
%time frame (OneMinuteData.prices
%                 OneMinuteData.minuteNumbers
%                 OneMinuteData.volume
%                 OneMinuteData.deals
%                 OneMinuteData.endOfDayIndexes

DataBase = cell(1, length(TimeFrames));
DataBase{1} = OneMinuteData;

for i = 2 : length(TimeFrames)
    
    %Reverce number of minutes in day
    TimeConstant = TimeFrames(i)/(24*60*60);
    
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
    
    newBar.minuteNumbers = zeros(length(ia),TimeFrames(i));
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
    DataBase{i} = newBar;
end

end


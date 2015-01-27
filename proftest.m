pv = zeros(1,obj.History.BestInSelectionStates{1}.nTicks ) ;

csprof = cumsum(prof);
for i=1:length(prof)-1
pv(ac(i):ac(i+1)) =csprof(i);
end
setdiff(obj.History.BestInSelectionStates{1, 1}.ProfitVector , pv)
 plot(pv)
hold on
plot(obj.History.BestInSelectionStates{1}.ProfitVector, '-r')
clc
clear all

ContractPage = urlread(['http://moex.com/en/contract.aspx?code=' 'RTS-12.11']);
NormalFee = regexp(ContractPage,...
    '(?<=Contract buy/sell fee, RUB</td><td class=pvalue>)(.*?)(?=</td>)', 'match');
IntradayFee = eval(NormalFee{1});
IntradayFee = regexp(ContractPage,...
    '(?<=Intraday \(scalper\) fee, RUB</td><td class=pvalue>)(.*?)(?=</td>)', 'match');
IntradayFee = eval(IntradayFee{1});

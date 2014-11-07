%%%%% Script to run Tax-Loss Harvesting on the iShares MSCI Emerging Markets ETF 
%%%%% (Ticker EEM).

%% Use Yahoo Finance to get daily data as far back as possible to Jan/1st/2000
EEM_Data = getYahooDailyData('EEM', '1/1/2000', '10/31/2014', 'mm/dd/yyyy');
EEM_Dates = table2array(EEM_Data.EEM(:,1));
EEM_Prices = table2array(EEM_Data.EEM(:,5));

clear EFA_Data;

%% Adjust for 3:1 stock split on 06/09/2005 and 
%% 3:1 stock split on 07/24/2008
DateNumber = datenum('06/09/2005','mm/dd/yyyy');
AdjustFlag = (EEM_Dates(:,1) >= DateNumber);
EEM_Prices(AdjustFlag) = 3*EEM_Prices(AdjustFlag);

DateNumber = datenum('07/24/2008','mm/dd/yyyy');
AdjustFlag = (EEM_Dates(:,1) >= DateNumber);
EEM_Prices(AdjustFlag) = 3*EEM_Prices(AdjustFlag);

% plot(EEM_Dates,EEM_Prices);
% dateaxis('x');

clear DateNumber AdjustFlag;

%% Calculate daily log-returns
EEM_Returns = log(EEM_Prices(2:end) ./ EEM_Prices(1:(end-1)));
EEM_Dates = EEM_Dates(2:end);


%%%%%%%% Find optimal TLH thresholds based on historical daily log-returns
initialDeposit = 100000;
initialWeights = 1;
taxRate = 0.2018;  % Ontario highest bracket capital-gains rate of 50%*(29% + 13.16%)
taxRateEnd = 0.1;

thresholds = [0.02:0.001:0.2];
optimalAfterTaxReturn = -Inf;
optimalthreshold = nan;

for i = 1:length(thresholds)
    TLHOutput = TLH(EEM_Returns,initialDeposit,initialWeights,thresholds(i),taxRate,taxRateEnd);
    
    if TLHOutput.AfterTaxGrowth > optimalAfterTaxReturn
        optimalAfterTaxReturn = TLHOutput.AfterTaxGrowth;
        optimalthreshold = thresholds(i);
    end
end

TLHOutputOptimal = TLH(EEM_Returns,initialDeposit,initialWeights,optimalthreshold,taxRate,taxRateEnd);

%% Plot cumulative-return and date at which harvesting occured
EFA_CumReturns = exp(cumsum(EEM_Returns));
plot(EEM_Dates(TLHOutputOptimal.HarvestedDates{1}),EFA_CumReturns(TLHOutputOptimal.HarvestedDates{1}),'ro','markerfacecolor','r');
hold on;
plot(EEM_Dates,EFA_CumReturns);
title('EEM Cumulative Returns');
axis tight
dateaxis('x',10);

datevec(EEM_Dates([1 end]))

%%%%%%%% Find optimal TLH thresholds based on simulated future daily
%%%%%%%% log-returns, based on 100 simulations
initialDeposit = 100000;
initialWeights = 1;
taxRate = 0.2018;  % Ontario highest bracket capital-gains rate of 50%*(29% + 13.16%)
taxRateEnd = 0.1;

%% Fit a 2-state Hidden Markov Model to the data
HMMModel = MS_Regress_Fit(EEM_Returns,ones(length(EEM_Returns),1),2,[1 1]);

thresholds = [0.02:0.01:0.2];
numThresholds = length(thresholds);
AfterTaxGrowth = zeros(numThresholds,1);
AfterTaxGrowthNoTLH = zeros(numThresholds,1);

for i = 1:250
    disp(i);
    %% Simulate future return series for the current iteration.  Keep doing 
    %% so until the simulated series has a "reasonable" cumulative return. 
    simulatedSeries = 99999*ones(30*252,1);
    while( (max(exp(cumsum(simulatedSeries))) > 20) || (min(exp(cumsum(simulatedSeries))) < 0.1) )
        simulatedSeries = SimulateSeries_HMM(HMMModel,30*252);
    end
    
    for j = 1:numThresholds
        TLHOutput = TLH(simulatedSeries,initialDeposit,initialWeights,...
                         thresholds(j),taxRate,taxRateEnd);
        
        AfterTaxGrowth(j) = AfterTaxGrowth(j) + TLHOutput.AfterTaxGrowth;
        AfterTaxGrowthNoTLH(j) = AfterTaxGrowthNoTLH(j) + TLHOutput.AfterTaxGrowthNoTLH;
    end
end

AfterTaxGrowth = AfterTaxGrowth / 250;
AfterTaxGrowthNoTLH = AfterTaxGrowthNoTLH / 250;

optimalThresholdIndex = find(AfterTaxGrowth == max(AfterTaxGrowth));

AfterTaxGrowthOptimal = AfterTaxGrowth(optimalThresholdIndex)
AfterTaxGrowthNoTLHOptimal = AfterTaxGrowthNoTLH(optimalThresholdIndex)
optimalThreshold = thresholds(optimalThresholdIndex)

plot(thresholds,AfterTaxGrowth);
title('Results Based on 250 Simulations');
ylabel('After Tax Growth');
xlabel('TLH Threshold');


% plot(VTI_Dates,VTI_Returns);
%dateaxis('x',10);


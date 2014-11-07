%%%%% Script to run Tax-Loss Harvesting on the iShares MSCI EAFE ETF 
%%%%% (Ticker EFA).

%% Use Yahoo Finance to get daily data as far back as possible to Jan/1st/2000
EFA_Data = getYahooDailyData('EFA', '1/1/2000', '10/31/2014', 'mm/dd/yyyy');
EFA_Dates = table2array(EFA_Data.EFA(:,1));
EFA_Prices = table2array(EFA_Data.EFA(:,5));

clear EFA_Data;

%% Adjust for 3:1 stock split on 06/09/2005
DateNumber = datenum('06/09/2005','mm/dd/yyyy');
AdjustFlag = (EFA_Dates(:,1) >= DateNumber);
EFA_Prices(AdjustFlag) = 3*EFA_Prices(AdjustFlag);

clear DateNumber AdjustFlag;

%% Calculate daily log-returns
EFA_Returns = log(EFA_Prices(2:end) ./ EFA_Prices(1:(end-1)));
EFA_Dates = EFA_Dates(2:end);


%%%%%%%% Find optimal TLH thresholds based on historical daily log-returns
initialDeposit = 100000;
initialWeights = 1;
taxRate = 0.2018;  % Ontario highest bracket capital-gains rate of 50%*(29% + 13.16%)
taxRateEnd = 0.1;

thresholds = [0.02:0.001:0.2];
optimalAfterTaxReturn = -Inf;
optimalthreshold = nan;

for i = 1:length(thresholds)
    TLHOutput = TLH(EFA_Returns,initialDeposit,initialWeights,thresholds(i),taxRate,taxRateEnd);
    
    if TLHOutput.AfterTaxGrowth > optimalAfterTaxReturn
        optimalAfterTaxReturn = TLHOutput.AfterTaxGrowth;
        optimalthreshold = thresholds(i);
    end
end

TLHOutputOptimal = TLH(EFA_Returns,initialDeposit,initialWeights,optimalthreshold,taxRate,taxRateEnd);

%% Plot cumulative-return and date at which harvesting occured
EFA_CumReturns = exp(cumsum(EFA_Returns));
plot(EFA_Dates(TLHOutputOptimal.HarvestedDates{1}),EFA_CumReturns(TLHOutputOptimal.HarvestedDates{1}),'ro','markerfacecolor','r');
hold on;
plot(EFA_Dates,EFA_CumReturns);
title('EFA Cumulative Returns');
axis tight
dateaxis('x',10);

datevec(EFA_Dates([1 end]))

%%%%%%%% Find optimal TLH thresholds based on simulated future daily
%%%%%%%% log-returns, based on 100 simulations
initialDeposit = 100000;
initialWeights = 1;
taxRate = 0.2018;  % Ontario highest bracket capital-gains rate of 50%*(29% + 13.16%)
taxRateEnd = 0.1;

%% Fit a 2-state Hidden Markov Model to the data
HMMModel = MS_Regress_Fit(EFA_Returns,ones(length(EFA_Returns),1),2,[1 1]);

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


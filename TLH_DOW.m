%%%%% Script to run Tax-Loss Harvesting on the 
%%%%% Dow-Jones Industrial Stock Price Index for United States.

%% Use Yahoo Finance to get daily data as far back as possible to Jan/1st/2000
DOW_Data = getGoogleDailyData('INDEXDJX:.DJI', '1/1/2010', '10/31/2014', 'mm/dd/yyyy');
DOW_Dates = table2array(DOW_Data.INDEXDJX0x3A0x2EDJI(:,1));
DOW_Prices = table2array(DOW_Data.INDEXDJX0x3A0x2EDJI(:,5));

% plot(DOW_Dates,DOW_Prices);
% dateaxis('x');

clear DOW_Data;

%% Calculate daily log-returns
DOW_Returns = log(DOW_Prices(2:end) ./ DOW_Prices(1:(end-1)));
DOW_Dates = DOW_Dates(2:end);


%%%%%%%% Find optimal TLH thresholds based on historical daily log-returns
initialDeposit = 100000;
initialWeights = 1;
taxRate = 0.2018;  % Ontario highest bracket capital-gains rate of 50%*(29% + 13.16%)
taxRateEnd = 0.1;

thresholds = [0.02:0.001:0.2];
optimalAfterTaxReturn = -Inf;
optimalthreshold = nan;

for i = 1:length(thresholds)
    TLHOutput = TLH(DOW_Returns,initialDeposit,initialWeights,thresholds(i),taxRate,taxRateEnd);
    
    if TLHOutput.AfterTaxGrowth > optimalAfterTaxReturn
        optimalAfterTaxReturn = TLHOutput.AfterTaxGrowth;
        optimalthreshold = thresholds(i);
    end
end

TLHOutputOptimal = TLH(DOW_Returns,initialDeposit,initialWeights,optimalthreshold,taxRate,taxRateEnd);

%% Plot cumulative-return and date at which harvesting occured
DOW_CumReturns = exp(cumsum(DOW_Returns));
plot(DOW_Dates(TLHOutputOptimal.HarvestedDates{1}),DOW_CumReturns(TLHOutputOptimal.HarvestedDates{1}),'ro','markerfacecolor','r');
hold on;
plot(DOW_Dates,DOW_CumReturns);
title('DOW Cumulative Returns');
axis tight
dateaxis('x',10);

datevec(DOW_Dates([1 end]))

%%%%%%%% Find optimal TLH thresholds based on simulated future daily
%%%%%%%% log-returns, based on 100 simulations
initialDeposit = 100000;
initialWeights = 1;
taxRate = 0.2018;  % Ontario highest bracket capital-gains rate of 50%*(29% + 13.16%)
taxRateEnd = 0.1;

%% Fit a 2-state Hidden Markov Model to the data
HMMModel = MS_Regress_Fit(DOW_Returns,ones(length(DOW_Returns),1),2,[1 1]);

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
title('Results based on 250 Simulations');
ylabel('After Tax Growth');
xlabel('TLH Threshold');


% plot(VTI_Dates,VTI_Returns);
%dateaxis('x',10);


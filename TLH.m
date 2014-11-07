%%%%% Function to carry out Tax-Loss Harvesting (TLH).  It calculates the after-tax return 
%%%%% with and without TLH.  It is assumed that when an asset is disposed of, 
%%%%% a perfectly correlated asset is purchased.  Input assetReturns are
%%%%% assumed to be daily log-returns
function TLHOutput = TLH(assetReturns,initialDeposit,initialWeights,...
                         thresholds,taxRate,taxRateEnd)
                                                              
numAssets = length(initialWeights);

%% horizon in days
horizon = size(assetReturns,1);

%% Calculate cumulative growth for each day of each asset over the investment horizon. 
%% This speeds up calculation of growth of harvested gains and growth between
%% 2 time points (required to decide to execute TLH) considerably
cumGrowth = exp(cumsum(assetReturns))';

CumGrowthAtLastHarvest = ones(numAssets,1);
HarvestedDates = cell(numAssets,1);
HarvestedAmounts = zeros(numAssets,1);

%%%%% Iterate over the investment horizon to execute TLH
for i = 1:horizon      
    
    %% Identify assets whose cumulative return from the last harvest to the 
    %% current iteration is below the threshold
    TLH_index = find( (cumGrowth(:,i) ./ CumGrowthAtLastHarvest) < (1 - thresholds));
    
    for j = 1:length(TLH_index)
        assetIndex = TLH_index(j);
        HarvestedAmounts(assetIndex) = HarvestedAmounts(assetIndex) + ...
                              taxRate*initialDeposit*initialWeights(assetIndex)*...
                              (CumGrowthAtLastHarvest(assetIndex) - cumGrowth(assetIndex,i))*(cumGrowth(assetIndex,end)/cumGrowth(assetIndex,i))*(1 - taxRateEnd);
        CumGrowthAtLastHarvest(assetIndex) = cumGrowth(assetIndex,i);
        HarvestedDates{assetIndex} = [HarvestedDates{assetIndex} i];
    end
        
end

%%%%% Calculate statistics pertaining to the end of investment horizon
PortfolioEndValue = initialDeposit*initialWeights.*cumGrowth(:,end);
PortfolioEndValueNoTLH = PortfolioEndValue;

AfterTaxGrowthNoTLH = (1 - taxRateEnd)*(sum(PortfolioEndValue) - initialDeposit);

%% Adjust for loss of portfolio value (by each asset) due to bid-ask spread,
%% which is 0.2% each time TLH is executed
for i = 1:numAssets
    PortfolioEndValue(i) = PortfolioEndValue(i)*(0.998)^(length(HarvestedDates{i}));
end

EndCapitalGainsTax = taxRateEnd*(PortfolioEndValue - initialDeposit*initialWeights.*CumGrowthAtLastHarvest);
AfterTaxGrowth = sum(PortfolioEndValue) - initialDeposit - sum(EndCapitalGainsTax) + sum(HarvestedAmounts);
PortfolioEndValue = sum(PortfolioEndValue);

TLHOutput.HarvestedDates = HarvestedDates;
TLHOutput.HarvestedAmounts = sum(HarvestedAmounts);
TLHOutput.PortfolioEndValue = sum(PortfolioEndValue);
TLHOutput.PortfolioEndValueNoTLH = sum(PortfolioEndValueNoTLH);
TLHOutput.AfterTaxGrowth = AfterTaxGrowth;
TLHOutput.AfterTaxGrowthNoTLH = AfterTaxGrowthNoTLH;
TLHOutput.EndCapitalGainsTax = EndCapitalGainsTax;

end
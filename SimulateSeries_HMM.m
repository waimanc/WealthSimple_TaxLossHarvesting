%% Function to simulate a daily return series from a 2-state Hidden Markov
%% Model.
function simulatedSeries = SimulateSeries_HMM(HMMModel,numObs)

%% Derive the stationary distribution by calculating the first eigenvector
%% of the transition probability matrix
[V D] = eig(HMMModel.Coeff.p);
stat_dist = V(:,1) / sum(V(:,1));

%% Simulate future daily returns with numObs observations
simulatedSeries = randn(numObs,1);
states = zeros(numObs,1);
rands = rand(numObs,1);

if rand < stat_dist(1)
    currState = 1;
    states(1) = currState;
else
    currState = 2;
    states(1) = currState;
end

for k = 2:numObs
    %% Check if we jump to other state for this iteration
    if rands(k) < HMMModel.Coeff.p(currState,currState)
        states(k) = currState;
    else
        if currState == 1
            states(k) = 2; 
            currState = 2;
        else
            states(k) = 1;
            currState = 1;
        end
    end
end

%% re-scale and shift the simulatedSeries based on its state variable
simulatedSeries(states == 1) = simulatedSeries(states == 1)*sqrt(HMMModel.Coeff.covMat{1});
simulatedSeries(states == 2) = simulatedSeries(states == 2)*sqrt(HMMModel.Coeff.covMat{2});
simulatedSeries(states == 1) = simulatedSeries(states == 1) + HMMModel.Coeff.S_Param{1}(1);
simulatedSeries(states == 2) = simulatedSeries(states == 2) + HMMModel.Coeff.S_Param{1}(2);


end
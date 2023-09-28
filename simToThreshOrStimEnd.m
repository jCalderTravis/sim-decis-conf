function [State, stimHist] = simToThreshOrStimEnd(SimData, trialNum, ...
    State, stimHist)
% Simulate and continue until a threshold is crossed or the maximum number
% of frames is presented. To speed up computations we simulate lots of time
% steps forward in one go (batches)

% INPUT
% stimHist: [1 x 2 (boxes) x num frames] array.  

batchSize = 500;

while (State.Crossed1 == 0) && (State.Crossed2 == 0) ...
        && (round((State.SimTime + SimData.SimSettings.DeltaT), 10) <= ...
        round(SimData.Raw.PlannedDuration(trialNum), 10))
    
    upperLim = SimData.Raw.PlannedDuration(trialNum);
    [timePoints, stimHist] = batchSimStim(State, SimData, ...
        batchSize, upperLim, stimHist, trialNum);
    
    accumulatedDiff = simulateTimeStep(SimData, stimHist, trialNum, ...
        State, timePoints);
    
    % Find the accumulated difference in evidence favouring option 1
    % and favouring option 2
    accumulator1 = -accumulatedDiff;
    accumulator2 = accumulatedDiff;
    preComputedThresh = SimData.SimSettings.Threshold(timePoints, ...
        SimData.Raw.BlockType(trialNum));
    [State.Crossed1, State.Crossed2, crossingIndex] ...
        = compareToThreshold(accumulator1, accumulator2, ...
        preComputedThresh);
    
    % If a bound was crossed, set the state to the time of the first
    % crossing, else use the final index
    if ~isnan(crossingIndex)
        assert(isequal(size(timePoints), size(accumulator2)))
        State.SimTime = timePoints(crossingIndex);
        State.AccumulatedDiff = accumulatedDiff(crossingIndex);
        
        % Also trim stim hist to only those frames that were shown
        currentFrame = ceil( ...
            round(timePoints(crossingIndex)*SimData.SimSettings.Fps, 10));
        stimHist(:, :, currentFrame+1 : end) = [];
    else
        State.SimTime = timePoints(end);
        State.AccumulatedDiff = accumulatedDiff(end);
    end
end
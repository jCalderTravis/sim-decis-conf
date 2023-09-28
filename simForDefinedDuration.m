function [State, stimHist] = simForDefinedDuration(SimData, trialNum, ...
    State, stimHist, duration)
% Simulate evidnece accumulation for a prespecified amount of time,
% ignoring decision thresholds and other deadlines.

batchSize = 500;

origTime = State.SimTime;
endTime = origTime + duration;
while round((State.SimTime + SimData.SimSettings.DeltaT), 10) <= ...
        round(endTime, 10)
    
    [timePoints, stimHist] = batchSimStim(State, SimData, ...
        batchSize, endTime, stimHist, trialNum);
    
    accumulatedDiff = simulateTimeStep(SimData, stimHist, ...
        trialNum, State, timePoints);
    
    State.SimTime = timePoints(end);
    State.AccumulatedDiff = accumulatedDiff(end);
end

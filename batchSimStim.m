function [timePoints, stimHist] = batchSimStim(State, SimData, ...
    batchSize, upperLim, stimHist, trialNum)
% Find the next batch of timepoints for which to simulate evidnece
% accumulation for, and simulate the stimulus for these time points.
% (Simulation of the evidence accumulation itself is not conducted.)

% INPUT
% batchSize: The number of timepoints to evaluate
% upperLim: A time which specifies an upper limit on the timepoints to
%   evaluated
% stimHist: [1 x 2 (boxes) x num frames] array.  

% Which timesteps will we evaluate
timePoints = State.SimTime + SimData.SimSettings.DeltaT ...
    : SimData.SimSettings.DeltaT : ...
    (State.SimTime + (batchSize * SimData.SimSettings.DeltaT));
timePoints = timePoints';

% Don't evaluate timesteps beyond the planned duration
timePoints(round(timePoints, 10) > round(upperLim, 10)) = [];

% Simulate stimulus. First, how many frames do we need?
if isempty(stimHist)
    currentFrames = 0;
else
    currentFrames = size(stimHist, 3);
end

requiredFrames = ceil(round(...
    timePoints(end)*SimData.SimSettings.Fps, 10));
newFrames = requiredFrames - currentFrames;
stimHist = simulateStimulus(SimData, trialNum, stimHist, newFrames);
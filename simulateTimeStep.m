function accumulatedDiff = simulateTimeStep(SimData, stimHist, ...
    iTrial, State, evalTimes, ~, varargin)
% Simulates the change in accumulators

% INPUT
% State: Structure. Required fields are 'AccumulatedDiff' (accumulated
% difference in evidence favouring option 2), and 
% evalTimes: Vector. Each entry gives a timepoint at which we are to simulate
% the state of the accumulator. The first entry should be the current
% simulation time + SimData.SimSettings.DeltaT, and all subsequent steps should
% be of interval SimData.SimSettings.DeltaT, because the code assumes this
% interval when deciding on the variability to add to the accumulator.
% varargin: Number specifying the ratio of weight given to evidence for option
% 2, to the weight given to evidence for option 1. Default is equal weighting, 
% i.e. 1. Note, this weighting is applied prior to StimLambda. The two weights
% will be calculated by assuming that they sum to 2.

deltaT = SimData.SimSettings.DeltaT;
accumulatedDiffInitial = State.AccumulatedDiff;

% Checks
if length(SimData) ~= 1; error('Only processes data from one participant.'); end
if isempty(evalTimes); error('No steps to evaluate provided'); end
if isfield(SimData.SimSettings, 'AntiCorr') ...
        && SimData.SimSettings.AntiCorr ~= 1
    error('This functionality was removed.')
end
if isfield(SimData.SimSettings, 'Leak') ...
        && SimData.SimSettings.Leak ~= 0
    error('This functionality was removed.')
end
if ~all(round(diff(evalTimes), 5) == round(deltaT, 5))
    error('Script requires evalTimes to be seperated by intervals of deltaT.')
end
if round(evalTimes(1), 5) ~= round(State.SimTime + deltaT, 5)
    error('See comments regarding the evalTimes input')
end

if ~isempty(varargin)
    weightRatio = varargin{1};
else
    weightRatio = 1;
end

%% Update the accumulator

% What is the evidence input on these steps?
evalFrames = ceil(round(evalTimes*SimData.SimSettings.Fps, 8));

frames2(:, 1) = stimHist(1, 2, evalFrames);
frames1(:, 1) = stimHist(1, 1, evalFrames);

% Apply a weighting to the the sources of evidence if requested
if weightRatio == 1
    % Nothing to do
else
    weight1 = 2 / (weightRatio + 1);
    weight2 = (2*weightRatio) / (weightRatio + 1);
    
    frames1 = frames1 * weight1;
    frames2 = frames2 * weight2;
end

lambda = SimData.SimSettings.StimLambda;
if lambda == 1
    ev1 = frames1;
    ev2 = frames2;
else
    ev1 = frames1.^lambda;
    ev2 = frames2.^lambda;
end

% Apply drift rate variability
evQual = SimData.SimHist.EvidenceQual(iTrial, :);

if ~SimData.SimSettings.IndDriftSD    
    if length(evQual) ~= 1; error('Bug'); end
    ev1 = ev1 * evQual;
    ev2 = ev2 * evQual;
else
    if length(evQual) ~= 2; error('Bug'); end
    ev1 = ev1 * evQual(1);
    ev2 = ev2 * evQual(2);
end
    
evidence = ev2 - ev1;
sumEvidence = ev2 + ev1;
    
% Draw noise values
sigma_A = SimData.SimSettings.NoiseSD;
sigma_B = SimData.SimSettings.StimPropNoiseSD;
if sigma_B == 0
    totalNoiseSD = sigma_A;
else
    totalNoiseSD = sqrt((sigma_A.^2) + ((sigma_B.^2)*(sumEvidence/2))); 
end

% First calculate the input. Note we
% scale the accumultion using Fps so that a frame with 54 dots will contribute 
% 54 evidence on average
noise = (deltaT^0.5) * totalNoiseSD .* randn(length(evalTimes), 1);
input = (deltaT * SimData.SimSettings.Fps * evidence) + noise;
        
if ~isequal(size(input), [length(evalTimes), 1]); error('Bug'); end

% Then calculate the new state of the acummulators, assuming anticorrelation
accumulatedDiff = accumulatedDiffInitial + cumsum(input);

if size(accumulatedDiff, 2) ~= 1; error('Bug'); end
if any(imag(accumulatedDiff)~=0); error('Bug'); end




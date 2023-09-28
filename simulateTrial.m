function [SimData, stimHist] = simulateTrial(SimData, trialNum)
% Simulates trial number, trialNum, for a single participant, by 
% simulating the actual diffusion/race process

if length(SimData) ~= 1; error('Only processes data from one participant.'); end

% Set initial time and variables to track whether a decision bound has been 
% crossed
State.SimTime = 0;
State.AccumulatedDiff = 0;
State.Crossed1 = 0;
State.Crossed2 = 0;
stimHist = [];

% Consider the possibility that the participant makes a random Resp, and 
% additionally at a random time if we are in a free response block. Call 
% these random response time lapses. Evidence is still accumulated 
% normally in the run up to such a lapse.
if rand(1) <= SimData.SimSettings.RandRtLapseRate
    
    if rand(1) <= 0.5    
        resp = 1;
    else
        resp = 2;
    end
    
    if SimData.Raw.IsForcedResp(trialNum)
        initialAccumulationTime = SimData.Raw.PlannedDuration(trialNum);
    else
        initialAccumulationTime = rand(1) * 5;
    end
    
    [State, stimHist] = simForDefinedDuration(SimData, trialNum, ...
        State, stimHist, initialAccumulationTime);
    
    rt = State.SimTime + SimData.SimHist.TrialCommitDelay(trialNum);

% Now consider the posibility of a normal response    
else    
    [State, stimHist] = simToThreshOrStimEnd(SimData, trialNum, ...
        State, stimHist);

    [State, stimHist] = simulateForcedFinalStage(SimData, ...
        trialNum, State, stimHist);    
        
    [rt, resp] = determineRtAndResp(SimData, trialNum, State);
end

% Is this response valid given the block type (free/forced) we are in?
SimData = determineRtValidity(SimData, trialNum, rt, resp);

if isempty(stimHist); error('Bug'); end

[SimData, stimHist] = simulateToFinalAccumulatorState(SimData, ...
    trialNum, State, stimHist);

% Checks
if isempty(stimHist); error('Bug'); end
respFrame = ceil(SimData.Raw.RtPrec(trialNum) * SimData.SimSettings.Fps);
isFree = strcmp(SimData.SimSettings.BlockSettings( ...
            SimData.Raw.BlockType(trialNum)).Type, 'free');

if isFree && any(isnan(stimHist(:, :, respFrame)))
    error('Bug')
end

if (~isnan(SimData.Raw.Resp(trialNum))) ...
        && isnan(SimData.Raw.ActualDurationPrec(trialNum))
    error('Bug')
end

end


    


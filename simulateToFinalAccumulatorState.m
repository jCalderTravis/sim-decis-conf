function [SimData, stimHist] = simulateToFinalAccumulatorState(SimData, ...
    trialNum, State, stimHist)
% Simulate final state of the accumulators for purpose of calculating 
% confidence. Depending on the settings we either assume that the 
% accumulation continues until stimulus presentation ends, or we we 
% simulate an entirely new accumulation process

% In any case the simulation does not continue if there was no valid response
if isnan(SimData.Raw.Acc(trialNum))
    SimData.Raw.ActualDurationPrec(trialNum) = NaN;
    SimData.SimHist.FinalAccumulatorDiff(trialNum) = NaN;
else
    SimData.Raw.ActualDurationPrec(trialNum) ...
        = determineStimPresentationTime(SimData, trialNum);
    
    % We now continue accumulating until the end of stimulus presentation,
    % for the purpose of computing confidence.
    % If there is time pressure on confidence report we will only accumulate
    % evidence arriving very soon after a decision.
    decisionTime = SimData.Raw.RtPrec(trialNum) - ...
        SimData.SimHist.TrialCommitDelay(trialNum);
    
    confidenceDeadline = decisionTime + SimData.SimSettings.BlockSettings( ...
        SimData.Raw.BlockType(trialNum)).ConfAccumulationTime;
    
    % If we are simulating confidence as the result of a seperate accumulation,
    % re-run the accumulator from the very start
    if SimData.SimSettings.SeperateConf == 1
        State.SimTime = 0;
        State.AccumulatedDiff = 0;
    end
    
    % Are we weighting evidence for the chosen option more heavily?
    if SimData.SimSettings.PosConfWeight == 1
        weightRatio = 1;
    else
        % A weighting only makes sense if we have a seperate confidence
        % accumulation as evidence is weighted equally for the decision
        if ~(SimData.SimSettings.SeperateConf == 1)
            warning('Choice of settings doesn''t really make sense. See comment.')
        end
        
        % PosConfWeight specifies weighting of chosen to unchosen. Need to
        % convert this to a weighting of option 2 to option 1.
        if isnan(SimData.Raw.Resp(trialNum))
            weightRatio = NaN;
        elseif SimData.Raw.Resp(trialNum) == 2
            weightRatio = SimData.SimSettings.PosConfWeight;
        elseif SimData.Raw.Resp(trialNum) == 1
            weightRatio = 1/SimData.SimSettings.PosConfWeight;
        else
            error('Bug')
        end
    end
    
    % Simulate stimulus
    stimTime = SimData.Raw.ActualDurationPrec(trialNum);
    currentFrames = size(stimHist, 3);
    requiredFrames = ceil(stimTime*SimData.SimSettings.Fps);
    newFrames = requiredFrames - currentFrames;
    
    stimHist = simulateStimulus(SimData, trialNum, stimHist, newFrames);
    
    % If there is time pressure on confidence report we will only accumulate
    % evidence arriving very soon after a decision.
    confTime = min(confidenceDeadline, stimTime);
    currentTime = State.SimTime;
    stepsToEval = currentTime + SimData.SimSettings.DeltaT ...
        : SimData.SimSettings.DeltaT : ...
        confTime;
    
    if ~isempty(stepsToEval)
        accumulatedDiff = simulateTimeStep(SimData, stimHist, trialNum, ...
            State, stepsToEval, [], weightRatio);
    else
        % There is nothing to do!
        accumulatedDiff = State.AccumulatedDiff;
    end
    
    % Store the results
    if any(imag(accumulatedDiff(end))~=0); error('Bug'); end
    SimData.SimHist.FinalAccumulatorDiff(trialNum) = accumulatedDiff(end);
end
function [State, stimHist] = simulateForcedFinalStage(SimData, ...
    trialNum, State, stimHist)
% Has no effect for free response trials

% If we are in a forced block then the decision will be made when...
% (a) time runs out. If so, decide on the basis of which accumulator is 
% higher
% (b) a threshold has been crossed. At this point the participant will
% either...
%   (i) respond immediately (and early)
%   (ii) sucesfully withhold response and wait unit the end of the stimulus
%   to respond

if strcmp(SimData.SimSettings.BlockSettings( ...
        SimData.Raw.BlockType(trialNum)).Type, 'forced')
    
    assert(SimData.Raw.IsForcedResp(trialNum))
    
    % Case (a)
    if (State.Crossed1 == 0) && (State.Crossed2 == 0)
        
        if State.AccumulatedDiff < 0
            State.Crossed1 = 1;
        else
            State.Crossed2 = 1;
        end
        
    % Case (b)
    else
        % Case (b)(ii) only, a response is witheld until the end of the stimulus
        if rand(1) >= SimData.SimSettings.BlockSettings( ...
                SimData.Raw.BlockType(trialNum)).ForcedEarlyRespProb
            
            % We need to simulate a stimulus for the remainder of the trial,
            % but we don't need to accumulate evidnece
            currentFrames = length(stimHist);
            requiredFrames ...
                = ceil(SimData.Raw.PlannedDuration(trialNum) ...
                *SimData.SimSettings.Fps);
            newFrames = requiredFrames - currentFrames;
            stimHist = simulateStimulus(SimData, trialNum, stimHist, newFrames);
            
            State.SimTime = SimData.Raw.PlannedDuration(trialNum);
        end
    end
    
else
    assert(~SimData.Raw.IsForcedResp(trialNum))
end
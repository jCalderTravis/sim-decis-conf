function SimData = determineRtValidity(SimData, trialNum, rt, resp)
% Determines whtether the RT in the given trial was valid for the current 
% block type. If not, the appropriate changes are made to the results. If 
% the simulated RT and response were valid, then these results are stored.

% INPUT
% rt: Simulated response time
% resp: Simulated response

if length(SimData) ~= 1; error('Only processes data from one participant.'); end

% Set resp, RT and accuracy assuming trial is valid, and change later if 
% not
SimData.Raw.RtPrec(trialNum) = rt;
SimData.Raw.Resp(trialNum) = resp;
if ~isnan(resp)
    SimData.Raw.Acc(trialNum) = double(...
        resp == SimData.Raw.StimLoc(trialNum));
end
thisAcc = SimData.Raw.Acc(trialNum);
assert(ismember(thisAcc, [0, 1]) || isnan(thisAcc))

if strcmp(SimData.SimSettings.BlockSettings( ...
        SimData.Raw.BlockType(trialNum)).Type, 'free')
    
    % Free response conditon. Invalid responses are just those longer than
    % the planned presentation time.
    if rt > SimData.Raw.PlannedDuration(trialNum)
        
        SimData.Raw.RtPrec(trialNum) = NaN;
        SimData.Raw.Resp(trialNum) = NaN;
        SimData.Raw.Acc(trialNum) = NaN;
    end
    
elseif strcmp(SimData.SimSettings.BlockSettings( ...
        SimData.Raw.BlockType(trialNum)).Type, 'forced')
    
    % Forced response conditon. Invalid responses are just those shorter than
    % the planned presentation time, and those longer than it by more than
    % 1000 ms. However, the scoring is different for each of these cases.
    if rt > (SimData.Raw.PlannedDuration(trialNum) + 1)
        
        SimData.Raw.RtPrec(trialNum) = NaN;
        SimData.Raw.Resp(trialNum) = NaN;
        SimData.Raw.Acc(trialNum) = NaN;

    elseif rt < SimData.Raw.PlannedDuration(trialNum)
        
        % In this case, for conistency with our previous work we only mark
        % Acc as NaN.
        SimData.Raw.Acc(trialNum) = NaN;
    end
    
else
    error('Unknown block type')
end
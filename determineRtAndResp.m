function [rt, resp] = determineRtAndResp(SimData, trialNum, State)

% OUTPUT
% resp: scalar. Either 1, 2, or nan.

if State.Crossed1 == 1
    resp = 1;
elseif State.Crossed2 == 1
    resp = 2;
elseif State.Crossed1 && State.Crossed2
    error('Bug')
else
    resp = nan;
end

if State.Crossed1 || State.Crossed2
    rt = State.SimTime + SimData.SimHist.TrialCommitDelay(trialNum);
else
    rt = nan;
end

if (~isnan(resp)) && (rand(1) <= SimData.SimSettings.MappingLapseRate)
    if resp == 1
        resp = 2;
    elseif resp == 2
        resp = 1;
    else
        error('Bug')
    end
end

if (~isnan(resp)) && (rand(1) <= SimData.SimSettings.RespLapseRate)
    if rand(1) < 0.5
        resp = 1;
    else
        resp = 2;
    end
end
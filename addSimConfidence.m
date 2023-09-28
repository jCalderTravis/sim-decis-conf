function SimData = addSimConfidence(SimData)
% Compute trial-by-trial confidence, with the calculation used
% depending on the settings in SimData.SimSettings.ConfCalc

% INPUT
% SimData.SimSettings.ConfCalc: string. Type of confidence calculation. 

% HISTORY
% 27.09.2023 Checked 'pCorrect' computations matches derivations in 
%   methods paper

if length(SimData) ~= 1; error('Only processes data from one participant.'); end

% Check input
if sum((SimData.Raw.Resp ~= 1) & (SimData.Raw.Resp ~= 2) & ...
        ~isnan(SimData.Raw.Resp)) ~= 0
    error('Unexpected entries in SimData.Raw.Resp')
end

finalAccumDiffForResp = NaN(length(SimData.Raw.Block), 1);

% Confidence will be determined by dots difference in the **chosen** direction.
% Note, for the case of no response, there is no confidence rating. 
finalAccumulatorDiffFor2 = SimData.SimHist.FinalAccumulatorDiff;

finalAccumDiffForResp(SimData.Raw.Resp == 1) = ...
    -finalAccumulatorDiffFor2(SimData.Raw.Resp == 1);

finalAccumDiffForResp(SimData.Raw.Resp == 2) = ...
    finalAccumulatorDiffFor2(SimData.Raw.Resp == 2);

if sum(isnan(finalAccumDiffForResp)) ~= sum(isnan(SimData.Raw.Acc))    
    error('Code not functioning as expected')
end


%% Are changes of mind permitted

if ~SimData.SimSettings.PermitCoM
    % Set all changes of mind to "don't know" ie. zero evidence
    finalAccumDiffForResp(finalAccumDiffForResp < 0) = 0;
end


%% Convert confidence into the desired form of rating

% Use notation from derivations paper
var_E = 2*(SimData.SimSettings.Dots.Sd.^2);
var_acc = SimData.SimSettings.NoiseSD^2;
t_f = 1 / SimData.Fps;
nu_0 = SimData.Raw.Diff /t_f;
var_nu = (SimData.SimSettings.DriftSD.^2) * (nu_0.^2);
sSquared = var_acc + (var_E/t_f);
t_e = SimData.Raw.ActualDurationPrec;
x = finalAccumDiffForResp;

if strcmp(SimData.SimSettings.ConfCalc, 'pCorrect')
    SimData.Raw.Conf = 1 ./ (1 + exp(-(2*x.*nu_0)./(sSquared + (var_nu .* t_e))));
    
elseif strcmp(SimData.SimSettings.ConfCalc, 'NDsc')
    SimData.Raw.Conf = finalAccumDiffForResp;
    
elseif any(strcmp(SimData.SimSettings.ConfCalc, {'TrDs', 'FaDs', ...
                                'TrDs_nonAccumTime', 'FaDs_nonAccumTime'}))
        
    if strcmp(SimData.SimSettings.ConfCalc, 'TrDs') ...
            || strcmp(SimData.SimSettings.ConfCalc, 'TrDs_nonAccumTime')

        a = var_nu ./ (var_nu + sSquared);            

    elseif strcmp(SimData.SimSettings.ConfCalc, 'FaDs') ...
        || strcmp(SimData.SimSettings.ConfCalc, 'FaDs_nonAccumTime')

        noiseParam = exp(SimData.SimSettings.ObserverNoiseRatio);
        a = 1 ./ (1 + (1./noiseParam));
    end

    % We need to compute the observer estimate
    % of the time they spend accumulating evidence towards their confidence
    % report.
    if strcmp(SimData.SimSettings.ConfCalc, 'TrDs_nonAccumTime') ...
            || strcmp(SimData.SimSettings.ConfCalc, 'FaDs_nonAccumTime')
        % Same as 'TrDs' and 'FaDs' but the observer accounts for evidence they did not
        % accumulate during the pipeline. (Relevant for finite
        % confAccumulation time.)

        % Work out conf accumulation time on trial by trial basis
        confAccumulationTime = nan(size(SimData.Raw.BlockType));

        for iBlockType = unique(SimData.Raw.BlockType)'
            confAccumulationTime(SimData.Raw.BlockType == iBlockType) ...
                = SimData.SimSettings.BlockSettings(iBlockType).ConfAccumulationTime;
        end

        % How long a stream of evidnece was accumulated?
        decisionTime = SimData.Raw.RtPrec - SimData.SimHist.TrialCommitDelay;
        confAccumulationTime = decisionTime + confAccumulationTime;
        confAccumulationTime ...
            = min([confAccumulationTime, SimData.Raw.ActualDurationPrec], ...
            [], 2);

    elseif strcmp(SimData.SimSettings.ConfCalc, 'TrDs') ...
            || strcmp(SimData.SimSettings.ConfCalc, 'FaDs')
        confAccumulationTime = SimData.Raw.ActualDurationPrec;

    else
        error('Bug')
    end

    disc = (1 - a) + (a.*confAccumulationTime);
    SimData.Raw.Conf = finalAccumDiffForResp ./ disc;
else
    error('Incorrect use of inputs')
end


%% Add metacognitive noise

SimData.Raw.Conf = SimData.Raw.Conf + ...
    (randn(length(SimData.Raw.Conf), 1) * SimData.SimSettings.ConfNoiseSd);


%% Confidence lapses
% Do we have random confidence reports? Implimentation: randomly draw a
% confidence report from another trial.
lapseTrials = (rand(length(SimData.Raw.Conf), 1) < SimData.SimSettings.ConfLapseRate) ...
    & (~isnan(SimData.Raw.Conf));

% Produce the set from which to draw confidence values
originalConf = SimData.Raw.Conf;
includedTrials = ~isnan(originalConf);
confSet = originalConf(includedTrials);

% Draw confidence value on lapse trials
SimData.Raw.Conf(lapseTrials) = datasample(confSet, sum(lapseTrials));


%% Map the confidence values to idiosyncratic scale usage
% If the usage of the scale by a participant has been provided, we will
% work out the percentlile of each simulated confidence report, and then
% map it to the percentile in idiosyncratic data.
if isfield(SimData.SimSettings, 'ScaleUsage') ...
        && ~isempty(SimData.SimSettings.ScaleUsage)
   
    % Find the percentile of each simulated conf report
    simConf = SimData.Raw.Conf;
    if any(imag(simConf)~=0); error('Bug'); end
    if size(simConf, 2) ~= 1; error('Expecting column vector.'); end
    
    % Find the number of reports smaller than each report
    inc = ~isnan(simConf);
    simConfRank = nan(size(simConf));
    simConfRank(inc) = sum(simConf(inc) > (simConf(inc)'), 2);
    assert(isequal(isnan(simConf), isnan(simConfRank)))
    simConfPercentile = (simConfRank / (length(simConfRank)-1)) * 100;
    
    if any((simConfPercentile<0) | (simConfPercentile>100))
        error('Bug')
    end
    
    % Find the corresponding percentiles in the idiosyncratic scale usage
    SimData.Raw.Conf ...
        = prctile(SimData.SimSettings.ScaleUsage, simConfPercentile);
    
    if size(SimData.Raw.Conf, 2) ~= 1; error('Unexpected shape.'); end
end

if any(imag(SimData.Raw.Conf)~=0); error('Bug'); end


assert(isequal(isnan(SimData.Raw.Acc), isnan(SimData.Raw.Conf)))


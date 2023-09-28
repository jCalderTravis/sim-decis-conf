function runTests()
% Test that unscaled calibrated, scaled calibrated, and scaled
% miscalibrared confidence readouts are related in the expected manner

nTrials = 1000;
SimData.Fps = 20;
SimData.SimHist.FinalAccumulatorDiff = rand(nTrials, 1) * 100;
SimData.SimSettings.PermitCoM = true;
SimData.SimSettings.Dots.Sd = 20;
SimData.SimSettings.NoiseSD = 40;
SimData.SimSettings.ConfNoiseSd = 0;
SimData.SimSettings.ConfLapseRate = 0;
SimData.SimSettings.DriftSD = 0.6;
SimData.Raw.Resp = randi(2, nTrials, 1);
SimData.Raw.Acc = randi(2, nTrials, 1) -1;
SimData.Raw.Block = ones(nTrials, 1);
SimData.Raw.Diff = ones(nTrials, 1) * 10;
SimData.Raw.ActualDurationPrec = rand(nTrials, 1) * 6;

%% Unscaled calibrated
SimData1 = SimData;
SimData1.SimSettings.ConfCalc = 'pCorrect';
SimData1.SimSettings.ObserverNoiseRatio = nan;
SimData1 = addSimConfidence(SimData1);
pCorrect1 = SimData1.Raw.Conf;

%% Scaled calibrated
SimData2 = SimData;
SimData2.SimSettings.ConfCalc = 'TrDs';
SimData2.SimSettings.ObserverNoiseRatio = nan;
SimData2 = addSimConfidence(SimData2);

% Compute the scaling (K in the derivations paper)
var_E = 2*(SimData.SimSettings.Dots.Sd.^2);
var_acc = SimData.SimSettings.NoiseSD^2;
t_f = 1 / SimData.Fps;
sSquared = var_acc + (var_E/t_f);
nu_0 = SimData.Raw.Diff /t_f;
var_nu = (SimData.SimSettings.DriftSD.^2) * (nu_0.^2);
K = (sSquared + var_nu) ./ (2*nu_0);

% Compute prob correct from the scaled calibrated log-posterior ratio
pCorrect2 = 1 ./ (1 + exp(-SimData2.Raw.Conf ./ K));

% Expect to be almost exactly the same
figure; scatter(pCorrect1, pCorrect2)
refline(1, 0)

%% Scaled uncalibrated

% Calculate the "ObserverNoiseRatio" that a calibrated observer would use
gamma = var_nu ./ (sSquared + var_nu);
Gamma = -log((1./gamma) -1);

SimData3 = SimData;
SimData3.SimSettings.ConfCalc = 'FaDs';
SimData3.SimSettings.ObserverNoiseRatio = Gamma;
SimData3 = addSimConfidence(SimData3);

pCorrect3 = 1 ./ (1 + exp(-SimData3.Raw.Conf ./ K));

% Expect to be almost exactly the same
figure; scatter(pCorrect1, pCorrect3)
refline(1, 0)


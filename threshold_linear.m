function thresholdPosition = threshold_linear(simTime, blockType, ...
    intercepts, slopes)
% Specifiy the threshold function to be used in the simulations

% INPUT
% Intercepts and slopes are two [blockType x 1] vectors sepcifiying the threshold
% in the two blockTypes

thresholdPosition = intercepts(blockType) + (simTime*slopes(blockType));
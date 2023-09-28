function thresholdPosition = threshold_linear_withDeadline(simTime, ...
    blockType, intercepts, slopes, deadline)
% Specifiy the threshold function to be used in the simulations

% INPUT
% Intercepts and slopes are two [blockType x 1] vectors sepcifiying the 
%   threshold in the two blockTypes
% deadline: After the time specified in deadline, the threshold drops to 
%   a very low level

thresholdPosition = intercepts(blockType) + (simTime*slopes(blockType));

assert(isequal(size(thresholdPosition), size(simTime)))

thresholdPosition(simTime > deadline) = 0.000001;

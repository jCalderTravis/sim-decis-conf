function stimHist = simulateStimulus(SimData, trialNum, stimHist, nFrames)
% Simulate the dots in the two boxes. Every time the function is called an extra
% nFrames is added to stimHist.

% INPUT
% stimHist      [1 x 2 (boxes) x new num Frames] array.  

if length(SimData) ~= 1
    error('Only processes data from one participant.')
end

% For convenince...
Mean.Correct = SimData.Raw.Ref(trialNum) + (SimData.Raw.Diff(trialNum)/2);
Mean.Incorrect = SimData.Raw.Ref(trialNum) - (SimData.Raw.Diff(trialNum)/2);

% Simulate the dots in the two boxes.
% If number of dots in either box is outside the range of possible values, 
% rerun the simulation
BoxDots.Correct = nan(nFrames, 1);
BoxDots.Incorrect = nan(nFrames, 1);

for fields = fieldnames(BoxDots)'
    
    toDo = true(size(BoxDots.(fields{1})));
    while any(toDo)
        
        BoxDots.(fields{1})(toDo) ...
            = (round(randn(sum(toDo), 1)*SimData.SimSettings.Dots.Sd)) ...
            + Mean.(fields{1});
        
        toDo = ~((BoxDots.(fields{1}) <= SimData.SimSettings.Dots.Max) & ...
            (BoxDots.(fields{1}) >= SimData.SimSettings.Dots.Min));
    end
end

% Assign the correctBoxDots to the box selected as stimLocation
newStimHist = nan(1, 2, nFrames);

if SimData.Raw.StimLoc(trialNum) == 1
    newStimHist(1, 1, :) = BoxDots.Correct;
    newStimHist(1, 2, :) = BoxDots.Incorrect;
elseif SimData.Raw.StimLoc(trialNum) == 2
    newStimHist(1, 1, :) = BoxDots.Incorrect;
    newStimHist(1, 2, :) = BoxDots.Correct;
end

stimHist = cat(3, stimHist, newStimHist);
    
if isfield(SimData.SimSettings.BlockSettings, 'ReversePulse') && ...
        SimData.SimSettings.BlockSettings( ...
        SimData.Raw.BlockType(trialNum)).ReversePulse
    error('No longer supported')
end

    
    
    
    
    


function [hiMean, loMean] = defaultDotDist(experiment)

% INPUT
% exeriment: Which set of defaults to use? 'postResp', 'forcedExp', 
% 'bigDiff', or 'variableDifficulty'

if strcmp(experiment, 'postResp')
    hiMean = 212;
    loMean = 188;
    
elseif strcmp(experiment, 'forcedExp')
    diff = 90;
    ref = 0;
    
    while ~((ref > 500) && (ref < 1500))
        ref = round((randn*100) + 1000);
    end
  
    hiMean = ref + (diff/2);
    loMean = ref - (diff/2);
    
elseif strcmp(experiment, 'bigDiff')
    hiMean = 212 + 100;
    loMean = 188;
    
elseif strcmp(experiment, 'variableDifficulty')
    diff = [90, 360, 810];
    i = randi(3);
    diff = diff(i);
    
    ref = 0;
    while ~((ref > 500) && (ref < 1500))
        ref = round((randn*100) + 1000);
    end
  
    hiMean = ref + (diff/2);
    loMean = ref - (diff/2);
    
elseif strcmp(experiment, 'forcedExp_custom')
    diff = 90;
    ref = 0;
    
    while ~((ref > 400) && (ref < 2600))
        ref = round((randn*2000) + 1500);
    end
  
    hiMean = ref + (diff/2);
    loMean = ref - (diff/2);
    
elseif strcmp(experiment, 'forcedExp_custom_lowMean')
    diff = 90;
    ref = 500;
    
    hiMean = ref + (diff/2);
    loMean = ref - (diff/2);
    
else
    error('Bug')
end
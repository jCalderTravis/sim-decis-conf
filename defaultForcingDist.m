function maxTime = defaultForcingDist(varargin)

if isempty(varargin)    
    distMean = 16;
    distSd = 16;
    lowerLim = 4;
    upperLim = 80;
    
elseif nargin == 4
    distMean = varargin{1};
    distSd = varargin{2};
    lowerLim = varargin{3};
    upperLim = varargin{4};    
end

maxTime = (randn(1)*distSd) + distMean;

while maxTime < lowerLim || maxTime > upperLim    
    maxTime = (randn(1)*distSd) + distMean;
end

end
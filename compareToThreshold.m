function [crossed1, crossed2, crossingIndex] = compareToThreshold(...
    accumulator1, accumulator2, thresholdPosition)
% Compare the state of the accumulators to the threshold to see if a threshold 
% has been crossed.

if size(accumulator1, 2) ~= 1; error('Bug'); end
if size(accumulator2, 2) ~= 1; error('Bug'); end
if size(thresholdPosition, 2) ~= 1; error('Bug'); end
assert(isequal(size(thresholdPosition), size(accumulator1)))
assert(isequal(size(thresholdPosition), size(accumulator2)))

crossingsFor1 = find(accumulator1 >= thresholdPosition, 1);
crossingsFor2 = find(accumulator2 >= thresholdPosition, 1);

if isempty(crossingsFor1) && isempty(crossingsFor2)
    crossed1 = 0;
    crossed2 = 0;
    crossingIndex = NaN;
elseif isempty(crossingsFor1) && ~isempty(crossingsFor2)
    crossed1 = 0;
    crossed2 = 1;
    crossingIndex = crossingsFor2(1);
elseif ~isempty(crossingsFor1) && isempty(crossingsFor2)
    crossed1 = 1;
    crossed2 = 0;
    crossingIndex = crossingsFor1(1);
elseif ~isempty(crossingsFor1) && ~ isempty(crossingsFor2) ...
        && crossingsFor2(1) <= crossingsFor1(1)
    crossed1 = 0;
    crossed2 = 1;
    crossingIndex = crossingsFor2(1);
elseif ~isempty(crossingsFor1) && ~isempty(crossingsFor2) ...
        && crossingsFor2(1) > crossingsFor1(1)
    crossed1 = 1;
    crossed2 = 0;
    crossingIndex = crossingsFor1(1);
else
    error('Bug')
end
    
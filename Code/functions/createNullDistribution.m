
function [out, seed] = createNullDistribution(design, opts, seed)

%-- verify inputs
if ~exist('design', 'var') || isempty(design)
    error('Design matrix not provided');
end
if ~isfield(opts, 'numShuffle') || isempty(opts.numShuffle)
    opts.numShuffle = 500; % default is 500 randomized contrast orders 
end
%-- set random number generator
if ~exist("seed", 'var') || isempty(seed)
    seed    = rng('shuffle', 'twister'); % random seed based on current time
end
rng(seed);
    
%% Extract information from design matrix
numRuns     = numel(design);
out         = design;

for run = 1:numRuns

    % Extract contrast levels:
    DM          = design(run);
    contrasts   = DM.conds;
    
    % Shuffle contrast levels without replacement
    
    switch opts.task
        case 'JN2022Event' % event related design with top-up adaptation interleaved
            eventIndx   = 3:2:length(contrasts);
            
        case 'RapidEvent' % completely random contrast order after initial fixation and adaptation period
            eventIndx   = 3:1:length(contrasts);
            
    end
    
    randStim    = NaN(length(contrasts), opts.numShuffle);
    for sh  = 1:opts.numShuffle
        randStim(:,sh)         = contrasts;
        
        % randomize order of contrasts included in event index
        randStim(eventIndx,sh) = randsample(contrasts(eventIndx), ...
            numel(eventIndx), false);
    end
    
    out(run).conds = randStim;
end


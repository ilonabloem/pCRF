
function run_pCRF_scc(numCores, arrayID)

%% -- Set some general options
if ~exist('opts', 'var')
    opts    = [];
end
if ~isfield(opts, 'tasks') || isempty(opts.tasks)
    opts.tasks = {'JN2022Event', 'RapidEvent'};
end
subjNames       = {'001' '003' '004' '007' '013' '018' '019' '021'};

opts.compute    = true;
opts.doPlots    = false;
opts.savePlots  = false;
opts.createNull = false;
opts.num_cores  = numCores;
opts.subjNames  = subjNames(arrayID);
opts.useHRF     = 'fit'; %'spm';

fprintf('START \n\n')
fprintf('subject: %s \n', opts.subjNames{1})
fprintf('num cores: %i \n', numCores)
fprintf('array ID: %i \n', arrayID)

%% -- Run model -SPM HRF - no cross val
opts.doCross    = false;

fprintf('Running models w/ fit HRF for participant %s \n', opts.subjNames{1})
run_pCRF(opts)

%% -- Run model - HRF - with cross val
opts.doCross    = true;

fprintf('Running crossvalidated models w/ fit HRF for participant %s \n', opts.subjNames{1})
run_pCRF(opts)

%% -- Run model -SPM HRF - null dist no cross val
opts.doCross    = false;
opts.createNull = true;
opts.compute    = true;

fprintf('Running null models w/ spm HRF for participant %s \n', opts.subjNames{1})
run_pCRF(opts)


function run_pCRF(opts, projectRoot, seed)
%% Run model-based popCRF analysis
%
% function out = run_pCRF(opts, projectRoot, seed)
%
% This function runs the model-based popCRF analysis for one or more
% experiments and subjects. It sets up default analysis options,
% configures paths relative to the project root, and initializes the
% random number generator.
% 
% INPUTS
% ------
% opts        : (struct, optional)
%             Structure with analysis options and parameters. Any fields
%             that are missing or empty will be filled with defaults set in
%             initDefaults.m. If omitted or empty, all options are taken
%             from the defaults.
% 
%             Key fields (non-exhaustive):
%               .compute     - logical, recompute preprocessing (default: false)
%               .doCross     - logical, run cross-validation (default: true)
%               .doGrid      - logical, grid search for C50 seed (default: true)
%               .doPlots     - logical, generate diagnostic plots (default: false)
%               .savePlots   - logical, save plots to disk (default: true)
%               .createNull  - logical, build shuffled-contrast null model (default: false)
%               .subjNames   - cellstr, subject IDs to analyze
%               .tasks       - cellstr, tasks to analyze
%                              e.g. {'JN2022Event','RapidEvent'} (default: both)
%               .Contrasts   - vector of contrast levels
%               .paramNames  - cellstr, model parameter names
%                              (default: {'C50','N','Rmax','B'})
%               .C50seed, .C50grid, .Rmaxseed, .nseed, .offsetseed
%                            - initial values and grid for model fitting
%               .stimDur     - stimulus duration (s)
%               .num_cores   - number of CPU cores to use
% 
% projectRoot : (char or string, optional)
%             Path to the project root directory. If empty or omitted,
%             it is inferred via projectRootPath.m, which returns both
%             projectRoot and dataRoot.
% 
% seed        : (scalar or struct, optional)
%             Random seed used to initialize the random number
%             generator. If empty or omitted, a seed is drawn from the
%             current time using
%                 seed = rng('shuffle','twister');
%             and the RNG is initialized with that seed.
%
% EXAMPLE
% -------
%   % Run with all defaults (both tasks, default subjects/ROIs)
%   run_pCRF();
% 
%   % Run for one subjects and only the RapidEvent task
%   opts.subjNames = {'001'};
%   opts.tasks     = {'RapidEvent'};
%   run_pCRF(opts);
%
% IB - Jan 2026

%% Check if input arguments exist
if ~exist('opts', 'var')
    opts    = [];
end
if ~exist('projectRoot', 'var') || isempty(projectRoot)
    % Finds parent directory where code lives
    [projectRoot, dataRoot] = projectRootPath;
end
if ~exist('seed', 'var') || isempty(seed)
    seed        = rng('shuffle', 'twister'); % random seed based on current time
end

rng(seed); 

%% Setup directories
addpath(genpath(projectRoot))

%% Initialize parameters
opts            = initDefaults(opts);
opts.dataDir    = dataRoot;
opts.outDir     = fullfile(dataRoot, '..', 'modelResults');

%% Setup parallel pool or limit matlab resources
if isempty(gcp('nocreate')) && opts.num_cores > 1
    maxNumCompThreads(opts.num_cores);
%     parpool(opts.num_cores-1);
end

%% Update stim duration based on task
if numel(opts.tasks) > 1
    if contains(opts.tasks, 'RapidEvent')
        opts.stimOn     = 0.5;
    elseif contains(opts.tasks, 'JN2022Event')
        opts.stimOn     = 2;
    end
else
    opts.stimOn     = zeros(1,numel(opts.tasks));
    opts.stimOn(contains(opts.tasks, 'RapidEvent'))  = 0.5;
    opts.stimOn(contains(opts.tasks, 'JN2022Event')) = 2;
end

%% Loop across subjects
numSubjects         = numel(opts.subjNames);

for s = 1:numSubjects
    
    subject     = opts.subjNames{s};
    opts.subject = subject;
    
    for ii = 1:numel(opts.tasks)
        
        %-- setup paths and file names
        switch opts.doCross
            case true
                opts.savestr = sprintf('task-%s_cross',opts.tasks{ii});
                opts.outDir  = fullfile(projectRoot, 'modelResults', 'cross');
            case false
                opts.savestr = sprintf('task-%s_nocross',opts.tasks{ii});
                opts.outDir  = fullfile(projectRoot, 'modelResults', 'nocross');
                
        end
        switch opts.createNull                    
            case true
                opts.savestr = sprintf('%s_nullModel',opts.savestr);
                opts.outDir = fullfile(projectRoot, 'modelResults', 'null');
        end
        
        opts.stimDur    = opts.stimOn(ii);
        opts.task       = opts.tasks{ii};
        
        % Load timeseries to fit 
        fileName        = sprintf('S%s_ModelPrep_%sRuns.mat', subject, opts.tasks{ii});
        
        if exist(fullfile(opts.dataDir, 'JNeuro2022', fileName), 'file') > 0 %&& opts.compute == 0
            
            fprintf('Loading data file %s ... \n',  fileName)
            modelInput = load(fullfile(opts.dataDir, 'JNeuro2022', fileName));
            
            %-- if fitting a null model, replace the design info
            switch opts.createNull
                case true
                    
                    nullFileName = sprintf('sub-%s_task-%s_nullDesign.mat', subject, opts.tasks{ii});
                    
                    if exist(fullfile(opts.outDir, nullFileName), 'file') > 0 && opts.compute == 0
                        
                        load(fullfile(opts.outDir, nullFileName), 'Design')
                    else
                        
                        [Design, randNumGen] = createNullDistribution(modelInput.Design, opts, []);
                         
                        if ~exist(opts.outDir, 'dir'), mkdir(opts.outDir); end
                        save(fullfile(opts.outDir, nullFileName), 'Design', 'randNumGen')
                        
                    end
                    
                    % replace design with randomized order
                    modelInput.Design   = Design;
            end

            %-- collect prf info
            prf.ecc         = modelInput.prf_ecc;
            prf.ang         = modelInput.prf_ang;
            prf.rfsize      = modelInput.prf_rfsize;
            prf.r2          = modelInput.prf_r2;
            roiIndx         = modelInput.roi_indx;
            
            %-- setup hrf
            if isfield(modelInput, 'hrf') && strcmp(opts.useHRF, 'indv')
                
                opts.whichHRF   = 'indvHRF';
                opts.HRF        = struct('modelOutput', cell(numel(opts.ROInames),1));
                
                for r = 1:numel(opts.ROInames)
                    avgHRF          = mean(modelInput.hrf(modelInput.roi_indx==r,:),1); % ROI average
                    
                    % Obtain best double gamma fit
                    fixedParams     = cell(1,3);
                    fixedParams{1}  = 'initialize';
                    
                    vals            = fitDoubleGamma([], fixedParams);
                    
                    fixedParams{1}  = 'optimize';
                    fixedParams{2}  = -3:1:20;
                    fixedParams{3}  = avgHRF;
                    
                    estParams = ...
                        fmincon(@(x) fitDoubleGamma(x, fixedParams), vals.init,[],[],[],[],vals.lb,vals.ub,[],vals.opts);
                    
                    fixedParams{1}  = 'prediction';
                    HRFfit          = fitDoubleGamma(estParams, fixedParams);
                    opts.HRF(r).modelOutput = HRFfit;
                    opts.HRF(r).roiIndx = modelInput.roi_indx;
                    
                end
            else
                
                opts.whichHRF   = 'spmHRF';
                opts.HRF        = [];
            end
        else
            
            %%% Could not find JNEURO data
            fprintf('\nSkipping subject for now ...  ')
            continue
            
        end
        
        %-- Fit pCRF model
        resultsName     = sprintf('sub-%s_%s_%s_modelResults.mat', subject, opts.savestr, opts.whichHRF);
        
        if exist(fullfile(opts.outDir, resultsName), 'file') > 0 && opts.compute == 0
            
            fprintf('\nSkipping modelling results exists %s ... ',  resultsName)
            
        else
            
            fprintf('\nComputing modelling results %s ... ',  resultsName)
            
            % Run popCRF model
            modelResults    = analysis_pCRF_crossVal(modelInput.TS_Data, modelInput.Design, opts.HRF, opts);
                     
            % make sure folder exists
            if exist(opts.outDir, 'dir') == 0, mkdir(opts.outDir); end

            %-- Save data
            out         = modelResults.out;
            input       = modelResults.input;
            opts        = modelResults.opts;
            save(fullfile(opts.outDir, resultsName), 'out', 'input', 'opts', 'roiIndx', 'prf', '-v7.3')
            fprintf('\nData saved: at %s as %s \n', opts.outDir, resultsName);
            
        end
        

    end

end


%% Close pool (if a pool is currently open)
delete(gcp('nocreate'))



function results = analysis_pCRF_crossVal(data, design, HRF, opts)

%% Estimate population CRF
%
% function out = analysis_pCRF(data, design, whichHRF, p, num_cores)
%
% data: matrix containing voxels x time
% design: matrix
% HRF: input predefined HRF, otherwise a spm HRF will be used as default
%
% IB - Oct 2022

if ~exist('data', 'var') || isempty(data)
    error('Data not provided.');
end
if ~exist('design', 'var') || isempty(design)
    error('Design matrix not provided');
end
if ~isfield(opts, 'subject') || isempty(opts.subject)
    error('Subject ID not provided');
end
if ~isfield(opts, 'outDir') || isempty(opts.outDir)
    error('Output directory not provided');
end
if ~exist('opts', 'var') || isempty(opts)
    opts            = initDefaults;
end

if isempty(opts.doPlots)
    opts.doPlots    = false;
    opts.savePlots  = false;
else
    if isempty(opts.savePlots)
       opts.savePlots = true; 
    end
    if isempty(opts.figureDir)
        error('Figure directory not provided');
    end
end

%% Make sure same amount of runs in data and design, otherwise throw error
assert(isequal(numel(data),numel(design)), 'Data and design do not contain an equal amount of runs!!')

numRuns     = numel(data);

%% Determine whether stimulus presentation was faster than TR
ds_factor   = opts.TR/opts.stimDur;
if ds_factor <= 1
    stepSize    = opts.TR;  
    ds_factor   = 1;
else
    stepSize    = opts.TR/ds_factor; 
end

%% Setup HRF
switch opts.whichHRF
    case 'spmHRF'
        
        % same HRF for all voxels
        HRF(1).data     = spmhrf(0:stepSize:20);
        HRF(1).roiIndx  = ones(size(data(1).TSeries,1),1);
        
    case 'indvHRF'
        
        % define your own HRF
        model = HRF(1).modelOutput.Model;
        for r = 1:numel(HRF)
             tmpHRF     = model(HRF(r).modelOutput.estParams, (0:stepSize:20));
             HRF(r).data= tmpHRF/max(tmpHRF(:));
        end
end

if opts.doPlots
   
    figure('Color', [1 1 1], 'Position', [60 100 750 800]) 
    for r = 1:numel(HRF)
        hold on, 
        plot(0:stepSize:20, HRF(r).data)
    end
    legend(num2str((1:numel(HRF))'))
    xlabel('Time (s)')
    ylabel('BOLD response (%SC)')
    box off
    title('HRF used for modeling')
    
    if opts.savePlots        
        if ~exist(fullfile(opts.figureDir, 'HRF'), 'dir'), mkdir(fullfile(opts.figureDir, 'HRF')); end
        saveas(gcf, fullfile(opts.figureDir, 'HRF', sprintf('%s_%s_S%s', opts.whichHRF, opts.task, opts.subject)), 'png'); 
        close;
    end
    
end

%% Extract information from design matrix
I           = [];
TSeries     = [];
runNum      = [];
start       = design(1).durTime([1 end]); % Find intial and final blank periods

for run = 1:numRuns
    
    DM          = design(run);
    totalTR     = DM.absTime(end,1) + DM.durTime(end,1);
    DM.absTime  = cat(1, DM.absTime, totalTR);
    
    contrasts   = DM.conds;
    tmpI        = NaN(size(contrasts,2),totalTR*ds_factor);
        
    count       = 1;
    for tp = 1:size(contrasts,1)
        
        tmpI(:, count:count+(DM.durTime(tp)/stepSize)-1) = (contrasts(tp,:) .* ones(DM.durTime(tp)/stepSize,size(contrasts,2)))';
        count   = count + DM.durTime(tp)/stepSize;
    end
    
    % Concatenate runs
    if size(contrasts,2) == 1
        I           = cat(1, I, tmpI);
    else
        I           = cat(3, I, tmpI);
    end
    TSeries     = cat(3, TSeries, data(run).TSeries);
    runNum      = cat(1, runNum, run*ones(1,totalTR*ds_factor));
    
    if opts.doPlots
       
        if run == 1            
            figure('Color', [1 1 1], 'Position', [60 100 750 1200])                 
        end
        
        subplot(numRuns, 1, run)
        plot(0:stepSize:totalTR-stepSize, tmpI, '.-k')
        box off; xlim([0 totalTR])
        ylabel('Contrast level')
        xlabel('Time (TR)')  
        title(sprintf('Design run %02d', run))
        
        if run == numRuns && opts.savePlots        
            if ~exist(fullfile(opts.figureDir, 'Design'), 'dir'), mkdir(fullfile(opts.figureDir, 'Design')); end
            saveas(gcf, fullfile(opts.figureDir, 'Design', sprintf('Design_%s_S%s', opts.task, opts.subject)), 'png'); 
            close;
        end
    end
    
end

croppedTRs      = (totalTR - start(1)) * numRuns;

%% Define parameter seeds
switch opts.doGrid
    case true
        
        startParam      = NaN(numel(opts.C50grid), 4);
        startParam(:,1) = opts.C50grid;
        startParam(:,2:4) = ones(numel(opts.C50grid),3) .* [opts.nseed opts.Rmaxseed opts.offsetseed];
         
    case false
        startParam      = [opts.C50seed opts.nseed opts.Rmaxseed opts.offsetseed];
end

%% Leave one run out cross-validation
assert(~(opts.doCross > 0 & opts.createNull > 0), 'Cannot run cross validation on null distribution fits')
if opts.doCross > 0 
    
    % each leave-on-out and once to the full dataset
    numFold             = numRuns;
        
    out                 = struct('crossValtSeries', [], ...
                         'crossValprediction', [], ...
                         'crossR2', [], ...
                         'date', []);
    out.crossValtSeries  = NaN(size(TSeries,1), croppedTRs);  
    out.crossValprediction = NaN(size(TSeries,1), croppedTRs);  
    out.crossR2          = NaN(size(TSeries,1), 1); 
    
elseif opts.createNull > 0
    
    % use the full dataset
    numFold             = opts.numShuffle;
    
    out                 = struct('nullSSE', [], ...
                         'nullR2', [], ...
                         'nullParams', [], ...
                         'date', []);

    %-- Preallocate variables
    out.nullParams.All  = NaN(numFold, size(TSeries,1), size(startParam,2));
    out.nullSSE         = NaN(numFold, size(TSeries,1));
    out.nullR2          = NaN(numFold, size(TSeries,1));
else
    
     % use the full dataset
    numFold             = 1;
    
    out                 = struct('fulltSeries', [], ...
                         'fullprediction', [], ...
                         'R2', [], ...
                         'exitflag', [], ...
                         'SSE', [], ...
                         'Params', [], ...
                         'date', []);
    out.fulltSeries     = NaN(size(TSeries,1), croppedTRs);  
    out.fullprediction  = NaN(size(TSeries,1), croppedTRs);  
    
    %-- Preallocate variables
    out.Params.All      = NaN(size(TSeries,1), size(startParam,2));
    out.Params.C50      = NaN(size(TSeries,1), size(startParam,2));
    out.Params.n        = NaN(size(TSeries,1), size(startParam,2));
    out.Params.Rmax     = NaN(size(TSeries,1), size(startParam,2));
    out.Params.offset   = NaN(size(TSeries,1), size(startParam,2));
    out.exitflag        = NaN(size(TSeries,1), 1);
    out.SSE             = NaN(size(TSeries,1), 1);
    out.R2              = NaN(size(TSeries,1), 1);

end


for vox = 1:size(TSeries,1) 

    crossValtSeries     = [];
    crossValprediction  = [];
    startSeed           = NaN(numFold, size(startParam,2)); 

    %-- Fit the data
    for nfold = 1:numFold
          
        %-- Define test and train data
        switch opts.doCross
            case false
                
                % train and test set are identical
                trainSet        = 1:numRuns;
                testSet         = 1:numRuns;
                
            case true
                
                % leave one run out cross validation
                trainSet        = setdiff(1:numRuns, nfold);
                testSet         = nfold;
                
        end

        switch opts.createNull
            case true
                trainI          = squeeze(I(nfold,:,trainSet))';
                testI           = squeeze(I(nfold,:,trainSet))';
            case false
                trainI          = I(trainSet,:);
                testI           = I(testSet,:);
        end
        
        trainTSeries    = TSeries(:,:,trainSet);
        testTSeries     = TSeries(:,:,testSet);
  
        %-- Select ROI specific HRF
        tmpHRF          = HRF;
        whichROI        = tmpHRF(1).roiIndx(vox);
        voxHRF          = tmpHRF(whichROI).data(:);
        
        %-- Setup training data to estimate model params
        trainData       = cell(1,7);
        trainData{2}    = trainI';
        trainData{3}    = squeeze(trainTSeries(vox,:,:));
        trainData{4}    = voxHRF;
        trainData{5}    = 100;
        trainData{6}    = ds_factor;
        trainData{7}    = start;

        %-- Setup test data to get prediction
        testData        = trainData;
        testData{2}     = testI';
        testData{3}     = squeeze(testTSeries(vox,:,:));
        
        if ~isequal(size(testData{2},2), size(testData{3},2))
            testData{3}         = testData{3}';
        end
        
        %-- setup model
        trainData{1}            = 'initialize';
        startVals               = fit_pCRF(startParam(1,:), trainData);
        
        %-- grid search to determine c50 seed for optimization
        switch opts.doGrid 
            case true

                trainData{1}    = 'prediction';    
                gridCorr        = NaN(1, numel(opts.C50grid));
                for ii = 1:numel(opts.C50grid)
                    
                    gridResults     = fit_pCRF(startParam(ii,:), trainData);
                    
                    % compute correlation (independent from amplitude and baseline) 
                    gridCorr(ii)    = corr(gridResults.estTseries(:), gridResults.Tseries(:));
                    
                end
                
                [~, seedIdx]    = max(gridCorr);
                trainData{1}    = 'initialize';   
                startVals       = fit_pCRF(startParam(seedIdx,:), trainData);

        end

        trainData{1}            = 'optimize';    
        [estParams, SSE, exitflag] = ...
            fmincon(@(x) fit_pCRF(x, trainData), startVals.init, [],[],[],[], startVals.lb, startVals.ub, [], startVals.opts);

        %-- Get predictions for test data 
        testData{1}             = 'prediction';   
        testResults             = fit_pCRF(estParams, testData);
       
        switch opts.doCross
            case true
                
                %-- Concatenate test data across runs to compute crossval R2 across all runs 
                crossValtSeries             = cat(1, crossValtSeries, testResults.Tseries);
                crossValprediction          = cat(1, crossValprediction, testResults.estTseries);
                
                startSeed(nfold,:)          = startVals.init;
            
            case false
                
                switch opts.createNull
                    
                    case false
                        %-- Save estimated params if model was applied to full dataset
                        out.exitflag(vox, :)        = exitflag;
                        out.SSE(vox,:)              = SSE;
                        out.Params.All(vox, :)      = estParams;
                        out.Params.C50(vox, :)      = estParams(:,1);
                        out.Params.n(vox, :)        = estParams(:,2);
                        out.Params.Rmax(vox, :)     = estParams(:,3);
                        out.Params.offset(vox, :)   = estParams(:,4);
                        out.Params.labels   = {'C50', 'Slope', 'Rmax', 'Offset'}; 

                        out.fulltSeries(vox,:)      = testResults.Tseries;
                        out.fullprediction(vox,:)   = testResults.estTseries;

                        out.R2(vox)                 = 1 - (sum((out.fullprediction(vox,:) - out.fulltSeries(vox,:)).^2) ...
                                                        / sum((out.fulltSeries(vox,:) - mean(out.fulltSeries(vox,:))).^2));

                        startSeed(nfold,:)          = startVals.init;
                    
                    case true
                        
                        %-- Save params, SSE and R2 for the shuffled contrast fits 
                        out.nullParams.All(nfold,vox, :)  = estParams;
                        out.nullParams.labels       = {'C50', 'Slope', 'Rmax', 'Offset'};
                        
                        out.nullSSE(nfold,vox)      = SSE;
                        out.nullR2(nfold,vox)       = 1 - (sum((testResults.estTseries - testResults.Tseries).^2) ...
                                                        / sum((testResults.Tseries - mean(testResults.Tseries)).^2));

                        startSeed(nfold,:)          = startVals.init;
                end
        end

    end % end of cross-validation loop

    switch opts.doCross
        case true
            out.crossR2(vox)                = 1 - (sum((crossValprediction - crossValtSeries).^2) ...
                                                    / sum((crossValtSeries - mean(crossValtSeries)).^2)); 

            out.crossValtSeries(vox,:)      = crossValtSeries;
            out.crossValprediction(vox,:)   = crossValprediction;
    end

    out.startParams(:,vox,:) = startSeed;
    
end % end of voxel loop 

out.date            = date;

inputs              = struct;
inputs.I            = I;
inputs.TSeries      = TSeries;
inputs.HRF          = HRF;
inputs.B            = 100;
inputs.ds_factor    = ds_factor;
inputs.const        = [numRuns; start];

% collect all into one variable
results.out         = out;
results.input       = inputs;
results.opts        = opts;




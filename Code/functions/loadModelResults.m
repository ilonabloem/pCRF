function allResults = loadModelResults(opts)

if ~exist('opts', 'var')
    opts    = [];
end

%-- set up paths
[~, dataRoot]   = projectRootPath;
outDir          = fullfile(dataRoot, '..', 'modelResults');

%-- initialize variables
opts            = initDefaults(opts);

numSubjects     = numel(opts.subjNames);
numROIs         = numel(opts.ROInames);
taskNames       = opts.tasks; % "JN2022Event" or "RapidEvent"
numTasks        = numel(taskNames);

loadStr         = {'nocross', 'cross', 'null'};

%-- setup data struct
structSize      = cell(numel(taskNames),1);
allResults      = struct('allParams', structSize, ...
                         'avgParams', structSize, ...
                         'paramLabels', structSize, ...
                         'SSE', structSize, ...
                         'nullSSE', structSize, ...
                         'crossR2', structSize, ...
                         'avgcrossR2', structSize, ...
                         'nullR2', structSize, ...
                         'voxCorr', structSize, ...
                         'fisherCorr', structSize, ...
                         'roiIndx', structSize, ...
                         'jneuroParams', structSize, ...
                         'prfEcc', structSize, ...
                         'prfAng', structSize, ...
                         'prfRFsz', structSize, ...
                         'prfR2', structSize);

                                         
%% loop to load model based estimates

for ii = 1:numTasks
    
    saveName    = sprintf('sub-group_task-%s_modelResults.mat', taskNames{ii});
    
    if exist(fullfile(outDir, saveName), 'file') > 0 && opts.compute == 0

        % LOAD file
        data            = load(fullfile(outDir, saveName), 'taskResults');
        allResults(ii)  = data.taskResults;
        
    else
    
        fprintf('Loading modeling results task %s \n', taskNames{ii})
        
        %-- load original parameter estimates for comparison to model-based approach  
        if strcmp(taskNames{ii}, 'JN2022Event')
            
            loadName    = 'allFIR_fits_wAdapt_GROUP_CRF_09-Oct-2021.mat';
            loadDir     = fullfile(dataRoot, 'JNeuro2022');
            
            assert(exist(fullfile(loadDir, loadName), 'file') > 0, 'Original parameter estimates not found')
            data        = load(fullfile(loadDir, loadName)); 
            jneuroPrms  = data.ALL_estParams;
            allResults(ii).jneuroParams = jneuroPrms;
            
        end
        
        %-- preallocate variables
        cellSize                  = cell(numSubjects, numel(opts.ROInames)); % needs to be a cell - different voxel numbers
        allResults(ii).crossR2    = cellSize;
        allResults(ii).avgcrossR2 = NaN(numSubjects, numel(opts.ROInames));
        allResults(ii).allParams  = cellSize;
        allResults(ii).avgParams  = cellSize;
        allResults(ii).SSE        = cellSize;
        allResults(ii).nullR2     = cellSize;
        allResults(ii).nullSSE    = cellSize;
        allResults(ii).prfEcc     = cellSize;
        allResults(ii).prfAng     = cellSize;
        allResults(ii).prfRFsz    = cellSize;
        allResults(ii).prfR2      = cellSize;

        for jj = 1:numel(loadStr)
            
            %-- setup name and directory
            loadName    = sprintf('sub-*_task-%s_*_%sHRF_*', taskNames{ii}, opts.useHRF);
            loadDir     = fullfile(outDir, loadStr{jj});           
            loadList    = dir(fullfile(loadDir, loadName));
            
            %-- ensure all files are found
            assert(numel(loadList) == numSubjects, sprintf("Missing model results in %s", loadDir))
            
            %-- subject loop
            for s = 1:numSubjects
                
                %-- load
                fileName        = dir(fullfile(loadDir, sprintf('sub-%s_task-%s_*_%sHRF_*', opts.subjNames{s}, taskNames{ii}, opts.useHRF)));
                modelResults    = load(fullfile(loadDir, fileName.name));

                for roi = 1:numROIs
                
                    roiIndx                 = modelResults.roiIndx == roi;
                    
                    switch loadStr{jj}
                        case "nocross" % extract parameter estimates

                            allResults(ii).roiIndx{s,roi}    = roiIndx;
                            allResults(ii).allParams{s,roi}  = modelResults.out.Params.All(roiIndx,:);
                            allResults(ii).avgParams{s,roi}  = median(modelResults.out.Params.All(roiIndx,:));
                            allResults(ii).paramLabels       = modelResults.out.Params.labels;
                            allResults(ii).SSE{s,roi}        = modelResults.out.SSE(roiIndx);
                            allResults(ii).prfEcc{s,roi}     = modelResults.prf.ecc(roiIndx,:);
                            allResults(ii).prfAng{s,roi}     = modelResults.prf.ang(roiIndx,:);
                            allResults(ii).prfRFsz{s,roi}    = modelResults.prf.rfsize(roiIndx,:);
                            allResults(ii).prfR2{s,roi}      = modelResults.prf.r2(roiIndx,:);
                            
                            % compute voxel-wise correlation
                            if contains(taskNames{ii}, 'JN2022Event')

                                paramOrder  = {'Rmax', 'Slope', 'C50'}; % match jneuro param order
                                [~, idx]    = ismember(paramOrder, allResults(ii).paramLabels);
                                modelParams = allResults(ii).allParams{s,roi}(:,idx);
                                deconvParams = allResults(ii).jneuroParams(s, roi).est_params_allVoxels ./ [1 1 100];
                                for p = 1:numel(paramOrder) 

                                    % spearman correlation
                                    rho         = corr(modelParams(:,p), deconvParams(:,p), 'type', 'Spearman');
                                    % transform to fisher z 
                                    fish_rho    = 0.5 .* (log(1+rho) - log(1-rho));

                                    allResults(ii).voxCorr(s,p,roi)       = rho;
                                    allResults(ii).fisherCorr(s,p,roi)    = fish_rho;
                                end

                            end

                        case "cross" % extract cross validated r2

                            allResults(ii).crossR2{s,roi}    = modelResults.out.crossR2(roiIndx);
                            allResults(ii).avgcrossR2(s,roi) = median(modelResults.out.crossR2(roiIndx));

                        case "null" % extract noise floor model fits

                            allResults(ii).nullR2{s,roi}     = modelResults.out.nullR2(:,roiIndx);
                            allResults(ii).nullSSE{s,roi}    = modelResults.out.nullSSE(:,roiIndx);

                    end

                end % end of roi loop
                
            end % end of subject loop
            
        end % end of loadstr loop
        
        
        %-- save summary output
        taskResults     = allResults(ii);
        save(fullfile(outDir, saveName), 'taskResults')
        
    end

          
end

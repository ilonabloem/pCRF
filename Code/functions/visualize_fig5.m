
function visualize_fig5(opts, taskResults, doStats)

%-- check inputs
if  ~exist('opts', 'var') || isempty(opts)
    opts            = []; 
end
if  ~exist('taskResults', 'var') || isempty(taskResults)
    opts.tasks      = {'RapidEvent'};
    opts            = initDefaults(opts);
    taskResults     = loadModelResults(opts);
end
if  ~exist('doStats', 'var') || isempty(doStats)
    doStats         = true; % default to do the stats
end

%-- 
opts            = initDefaults(opts);
numSubjects     = numel(opts.subjNames);
numROIs         = numel(opts.ROInames);

figAvgParams    = figure('Color', [1 1 1], 'Position', [124  525 1039 337]);
set(figAvgParams,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[1400 700])

paramLabels     = {'C50', 'Rmax', 'Slope'};
avg_pCRFparams  = NaN(numSubjects, 3, numROIs);
improvementSSE  = NaN(numSubjects, numROIs);
pvals           = NaN(numROIs, 1);
CIs             = NaN(numROIs, 2);
tVals           = NaN(numROIs, 1);
df              = NaN(numROIs, 1);
meanImprov      = NaN(numROIs, 1);

%-- setup roi colors
roiColors   = {[0.3176    0.3961    0.6824]; %[0.2744    0.3735    0.9857];
               [0.1176    0.6745    0.8549]; %[0.0981    0.6774    0.8626];
               [0.3843    0.7490    0.4863]}; %[0.3291    0.8001    0.4884]};

indvDotsize     = 10;
errBarWidth     = 2;
numParams       = 3;

for roi = 1:numROIs
    
    for s = 1:numSubjects
        
        % get and reorder parameter estimates
        [~, idx]                = ismember(paramLabels, taskResults.paramLabels);
        pCRFParam               = taskResults.allParams{s,roi}(:,idx);
        avg_pCRFparams(s,:,roi) = median(pCRFParam, 'omitnan');

        %-- compute how much better model explains data compared to null
        % improvement per voxel and null sample
        SSE_model               = taskResults.SSE{s,roi}(:);          
        SSE_null                = median(taskResults.nullSSE{s,roi},1)';
        
        % normalize improvement by null: (null - model) / null
        improvement             = ((SSE_null - SSE_model) ./ SSE_null) * 100;  
        improvementSSE(s,roi)   = median(improvement); 
      
    end

    % One-sample t-test vs 0 (no improvement)
    [~, p, ci, stats] = ttest(improvementSSE(:,roi), 0);
    
    pvals(roi,1)      = p;
    CIs(roi,:)        = ci;
    tVals(roi,1)      = stats.tstat;
    df(roi,1)         = stats.df;
    meanImprov(roi,1) = mean(improvementSSE(:,roi),1);

    % C50
    subplot(1, numParams+1, 2)
    hold on,
    if roi == 3
        title('C50')
        xlim([0.5 3]);xticks([1 2 3]); xticklabels(opts.ROInames)
        set(gca, 'TickDir', 'out')
    end

    scatter(roi*ones(numSubjects,1), avg_pCRFparams(:,1,roi), indvDotsize*11, roiColors{roi}, 'filled','MarkerFaceAlpha', 0.3);
    errorbar(roi, mean(avg_pCRFparams(:,1,roi)), std(avg_pCRFparams(:,1,roi))/sqrt(numSubjects), ...
        'ko', 'CapSize', 0, 'LineWidth', errBarWidth,'MarkerFaceColor',roiColors{roi}, 'MarkerSize',(indvDotsize+5))
    errorbar(roi, mean(avg_pCRFparams(:,1,roi)), std(avg_pCRFparams(:,1,roi))/sqrt(numSubjects), ...
        'k', 'CapSize', 0, 'LineWidth', errBarWidth)

    % Rmax
    subplot(1, numParams+1, 3)
    hold on,
    if roi == 3
        title('Rmax')
        xlim([0.5 3]);xticks([1 2 3]); xticklabels(opts.ROInames)
        set(gca, 'TickDir', 'out')
        ylim([1 10])
    end

    scatter(roi*ones(numSubjects,1), avg_pCRFparams(:,2,roi), indvDotsize*11, roiColors{roi}, 'filled','MarkerFaceAlpha', 0.3);
    errorbar(roi, mean(avg_pCRFparams(:,2,roi)), std(avg_pCRFparams(:,2,roi))/sqrt(numSubjects), ...
        'ko', 'CapSize', 0, 'LineWidth', errBarWidth,'MarkerFaceColor',roiColors{roi}, 'MarkerSize',(indvDotsize+5))
    errorbar(roi, mean(avg_pCRFparams(:,2,roi)), std(avg_pCRFparams(:,2,roi))/sqrt(numSubjects), ...
        'k', 'CapSize', 0, 'LineWidth', errBarWidth)


    subplot(1, numParams+1, 4)
    hold on,
    if roi == 3
        title('Slope')
        xlim([0.5 3]);xticks([1 2 3]); xticklabels(opts.ROInames)
        set(gca, 'TickDir', 'out')
        ylim([1 10])
    end

    scatter(roi*ones(numSubjects,1), avg_pCRFparams(:,3,roi), indvDotsize*11, roiColors{roi}, 'filled','MarkerFaceAlpha', 0.3);
    errorbar(roi, mean(avg_pCRFparams(:,3,roi)), std(avg_pCRFparams(:,3,roi))/sqrt(numSubjects), ...
        'ko', 'CapSize', 0, 'LineWidth', errBarWidth,'MarkerFaceColor',roiColors{roi}, 'MarkerSize',(indvDotsize+5))
    errorbar(roi, mean(avg_pCRFparams(:,3,roi)), std(avg_pCRFparams(:,3,roi))/sqrt(numSubjects), ...
        'k', 'CapSize', 0, 'LineWidth', errBarWidth)

   
    % (Noise - Model) / (Noise)
    subplot(1, numParams+1, 1)
    hold on,
    if roi == 3
        title('Norm SSE')
        xlim([0.5 3]);xticks([1 2 3]); xticklabels(opts.ROInames)
        set(gca, 'TickDir', 'out')
    end

    scatter(roi*ones(numSubjects,1), improvementSSE(:,roi), indvDotsize*11, roiColors{roi}, 'filled','MarkerFaceAlpha', 0.3);
    errorbar(roi, mean(improvementSSE(:,roi)), std(improvementSSE(:,roi))/sqrt(numSubjects), ...
        'ko', 'CapSize', 0, 'LineWidth', errBarWidth,'MarkerFaceColor',roiColors{roi}, 'MarkerSize',(indvDotsize+5))
    errorbar(roi, mean(improvementSSE(:,roi)), std(improvementSSE(:,roi))/sqrt(numSubjects), ...
        'k', 'CapSize', 0, 'LineWidth', errBarWidth)

end

if opts.savePlots > 0
    if ~exist(fullfile(opts.figureDir, 'Figure5'), 'dir'), mkdir(fullfile(opts.figureDir, 'Figure5')); end
    print(figAvgParams, fullfile(opts.figureDir, 'Figure5', sprintf('Fig5_continuous_pCRF')), '-dpdf');
end

if doStats > 0
    %-- save results from ttest on improvement compared to shuffled null 
    ROInames            = opts.ROInames;
    modelImprovement    = table(ROInames(:), pvals, df, tVals, meanImprov, CIs(:,1), CIs(:,2), ...
                        'VariableNames', {'ROI','p','df','tstat', 'mean', 'lb_mean', 'ub_mean'});
    
    fprintf('ttest model-based SSE improvement compared to null\n ')
    disp(modelImprovement)
    if opts.savePlots > 0
        writetable(modelImprovement, fullfile(opts.figureDir, 'stats',sprintf('%s_modelImprovement.csv', 'RapidEvent')), ...
               'FileType', 'text', 'Delimiter', ',', ...
               'WriteRowNames', false);
    end
    
    %-- Report crossval R2
    [~,p,ci,stat]   = ttest(taskResults.avgcrossR2, 0);
    df              = stat.df;
    tstat           = stat.tstat;
    meanR2          = mean(taskResults.avgcrossR2,1);
    
    crossvalR2      = table(ROInames(:), p(:), df(:), tstat(:), meanR2(:), ci(1,:)', ci(2,:)', ...
                        'VariableNames', {'ROI','p','df','tstat', 'mean', 'lb_mean', 'ub_mean'});
    
    fprintf('ttest crossval R2 > 0 (model-based)\n ')
    disp(crossvalR2)
    if opts.savePlots > 0
        writetable(crossvalR2, fullfile(opts.figureDir, 'stats', sprintf('%s_crossValR2.csv', 'RapidEvent')), ...
               'FileType', 'text', 'Delimiter', ',', ...
               'WriteRowNames', false);
    end
end

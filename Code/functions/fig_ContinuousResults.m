
function fig_ContinuousResults(opts, allResults, doStats)

%-- check inputs
if  ~exist('opts', 'var') || isempty(opts)
    opts            = []; 
end
if  ~exist('allResults', 'var') || isempty(allResults)
    opts            = initDefaults(opts);
    allResults     = loadModelResults(opts);
end
if  ~exist('doStats', 'var') || isempty(doStats)
    doStats         = true; % default to do the stats
end

%-- 
opts            = initDefaults(opts);
numSubjects     = numel(opts.subjNames);
numROIs         = numel(opts.ROInames);

figAvgParams    = figure('Color', [1 1 1], 'Position', [124  525 450 530]);
set(figAvgParams,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[450 530])
figlayout       = tiledlayout(2,1);
R2layout        = tiledlayout(figlayout, 1, 3);
avgPrmlayout    = tiledlayout(figlayout, 1, 4);

paramLabels     = {'C50', 'Rmax', 'Slope'};
avg_pCRFparams  = NaN(numSubjects, 3, numROIs);
improvementSSE  = NaN(numSubjects, numROIs);
avgCrossR2_rapid = NaN(numSubjects, numROIs);
avgCrossR2_jneuro = NaN(numSubjects, numROIs);

pvals           = NaN(numROIs, 1);
CIs             = NaN(numROIs, 2);
tVals           = NaN(numROIs, 1);
df              = NaN(numROIs, 1);
meanImprov      = NaN(numROIs, 1);

%-- setup roi colors
roiColors       = {[0.3176    0.3961    0.6824]; %[0.2744    0.3735    0.9857];
                   [0.1176    0.6745    0.8549]; %[0.0981    0.6774    0.8626];
                   [0.3843    0.7490    0.4863]}; %[0.3291    0.8001    0.4884]};

indvDotsize     = 5;
errBarWidth     = 2;
numBins         = 40;
R2max           = [0.3, 0.2, 0.1];
taskResults     = allResults(2);

for roi = 1:numROIs
    
    nR2        = NaN(numBins, numBins, numSubjects);

    for s = 1:numSubjects

        % 2d histogram
        pts                     = linspace(0,R2max(roi),numBins+1);
        nR2(:,:,s)              = histcounts2(allResults(2).crossR2{s,roi}, allResults(1).crossR2{s,roi}, ...
                                        pts, pts, 'Normalization', 'probability'); 

        voxSelect               = allResults(1).crossR2{s,roi} >= (R2max(roi)/6) & taskResults.crossR2{s,roi} >= (R2max(roi)/6);

        % get and reorder parameter estimates
        [~, idx]                = ismember(paramLabels, taskResults.paramLabels);
        pCRFParam               = taskResults.allParams{s,roi}(voxSelect,idx);
        avg_pCRFparams(s,:,roi) = median(pCRFParam, 'omitnan');

        %-- compute how much better model explains data compared to null
        % improvement per voxel and null sample
        SSE_model               = taskResults.SSE{s,roi}(voxSelect);          
        SSE_null                = median(taskResults.nullSSE{s,roi}(:,voxSelect),1)';
        
        % normalize improvement by null: (null - model) / null
        improvement             = ((SSE_null - SSE_model) ./ SSE_null) * 100;  
        improvementSSE(s,roi)   = median(improvement); 
      
        % avg crossR2 after vox selection
        avgCrossR2_rapid(s,roi) = median(taskResults.crossR2{s,roi}(voxSelect));
        avgCrossR2_jneuro(s,roi)= median(allResults(1).crossR2{s,roi}(voxSelect));
    end

    R2layout.Layout.Tile = 1;
    ax  = nexttile(R2layout);    
    imagesc(pts, pts, mean(nR2,3));      
    set(gca, 'XLim', [pts(1)-pts(2) pts(end)+pts(2)], 'XTick', pts([1 numBins/2+1 numBins+1]), 'XTickLabel', pts([1 numBins/2+1 numBins+1]), ...
        'YLim', [pts(1)-pts(2) pts(end)+pts(2)], 'YTick', pts([1 numBins/2+1 numBins+1]), 'YTickLabel', pts([1 numBins/2+1 numBins+1]), ...
        'YDir', 'normal');
    colormap(ax, "bone")
    hold on, 
    plot(gca, [R2max(roi)/6 R2max(roi)/6], [0 R2max(roi)], 'w:', 'LineWidth', 1.5)
    plot(gca, [0 R2max(roi)], [R2max(roi)/6 R2max(roi)/6], 'w:', 'LineWidth', 1.5)

    caxis(ax,[0 0.005])
    axis square; box off
    if roi == 1
        ylabel('Rapid Estimates', 'FontSize', 10)
        xlabel('Event-related Estimates', 'FontSize', 10)
        title(R2layout, 'voxelwise crossval R2', 'FontSize', 14)
        set(ax, "TickDir", "out")
    end


    % One-sample t-test vs 0 (no improvement)
    [~, p, ci, stats] = ttest(improvementSSE(:,roi), 0);
    
    pvals(roi,1)      = p;
    CIs(roi,:)        = ci;
    tVals(roi,1)      = stats.tstat;
    df(roi,1)         = stats.df;
    meanImprov(roi,1) = mean(improvementSSE(:,roi),1);

    % (Noise - Model) / (Noise)
    if roi == 1
        axSSE = nexttile(avgPrmlayout); 
        title(axSSE, 'Norm SSE')
        xlim(axSSE, [0.5 3]);xticks(axSSE, [1 2 3]); xticklabels(axSSE, opts.ROInames)
        set(axSSE, 'TickDir', 'out')
        ylim([0 20])
        hold on,
    end
    scatter(axSSE, roi*ones(numSubjects,1), improvementSSE(:,roi), indvDotsize*11, roiColors{roi}, 'filled','MarkerFaceAlpha', 0.3);
    errorbar(axSSE, roi, mean(improvementSSE(:,roi)), std(improvementSSE(:,roi))/sqrt(numSubjects), ...
        'ko', 'CapSize', 0, 'LineWidth', errBarWidth,'MarkerFaceColor',roiColors{roi}, 'MarkerSize',(indvDotsize+5))
    errorbar(axSSE, roi, mean(improvementSSE(:,roi)), std(improvementSSE(:,roi))/sqrt(numSubjects), ...
        'k', 'CapSize', 0, 'LineWidth', errBarWidth)

    % C50
    avgPrmlayout.Layout.Tile = 2;
    if roi == 1
        axC50 = nexttile(avgPrmlayout); 
        title(axC50, 'C50')
        xlim(axC50, [0.5 3]);xticks(axC50, [1 2 3]); xticklabels(axC50, opts.ROInames)
        set(axC50, 'TickDir', 'out')
        hold on,
        ylim([0 1])
        title(avgPrmlayout, 'median parameter estimates', 'FontSize', 14)
    end
    scatter(axC50, roi*ones(numSubjects,1), avg_pCRFparams(:,1,roi), indvDotsize*11, roiColors{roi}, 'filled','MarkerFaceAlpha', 0.3);
    errorbar(axC50, roi, mean(avg_pCRFparams(:,1,roi)), std(avg_pCRFparams(:,1,roi))/sqrt(numSubjects), ...
        'ko', 'CapSize', 0, 'LineWidth', errBarWidth,'MarkerFaceColor',roiColors{roi}, 'MarkerSize',(indvDotsize+5))
    errorbar(axC50, roi, mean(avg_pCRFparams(:,1,roi)), std(avg_pCRFparams(:,1,roi))/sqrt(numSubjects), ...
        'k', 'CapSize', 0, 'LineWidth', errBarWidth)

    % Rmax
    if roi == 1
        axRmax = nexttile(avgPrmlayout);   
        title('Rmax')
        xlim([0.5 3]);xticks([1 2 3]); xticklabels(opts.ROInames)
        set(axRmax, 'TickDir', 'out')
        ylim([0 8])
        hold on,
    end
    scatter(axRmax, roi*ones(numSubjects,1), avg_pCRFparams(:,2,roi), indvDotsize*11, roiColors{roi}, 'filled','MarkerFaceAlpha', 0.3);
    errorbar(axRmax, roi, mean(avg_pCRFparams(:,2,roi)), std(avg_pCRFparams(:,2,roi))/sqrt(numSubjects), ...
        'ko', 'CapSize', 0, 'LineWidth', errBarWidth,'MarkerFaceColor',roiColors{roi}, 'MarkerSize',(indvDotsize+5))
    errorbar(axRmax, roi, mean(avg_pCRFparams(:,2,roi)), std(avg_pCRFparams(:,2,roi))/sqrt(numSubjects), ...
        'k', 'CapSize', 0, 'LineWidth', errBarWidth)

    % slope
    if roi == 1
        axSlope = nexttile(avgPrmlayout);  
        title('Slope')
        xlim([0.5 3]);xticks([1 2 3]); xticklabels(opts.ROInames)
        set(axSlope, 'TickDir', 'out')
        ylim([1 10])
        hold on,
    end
    scatter(axSlope, roi*ones(numSubjects,1), avg_pCRFparams(:,3,roi), indvDotsize*11, roiColors{roi}, 'filled','MarkerFaceAlpha', 0.3);
    errorbar(axSlope, roi, mean(avg_pCRFparams(:,3,roi)), std(avg_pCRFparams(:,3,roi))/sqrt(numSubjects), ...
        'ko', 'CapSize', 0, 'LineWidth', errBarWidth,'MarkerFaceColor',roiColors{roi}, 'MarkerSize',(indvDotsize+5))
    errorbar(axSlope, roi, mean(avg_pCRFparams(:,3,roi)), std(avg_pCRFparams(:,3,roi))/sqrt(numSubjects), ...
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
        if ~exist(fullfile(opts.figureDir, 'stats'), 'dir') > 0, mkdir(fullfile(opts.figureDir, 'stats')), end
        writetable(modelImprovement, fullfile(opts.figureDir, 'stats',sprintf('%s_modelImprovement.csv', 'RapidEvent')), ...
               'FileType', 'text', 'Delimiter', ',', ...
               'WriteRowNames', false);
    end
    
    %-- Report crossval R2 rapid design
    [~,p,ci,stat]   = ttest(avgCrossR2_rapid, 0);
    df              = stat.df;
    tstat           = stat.tstat;
    meanR2          = mean(avgCrossR2_rapid,1);
    
    crossvalR2      = table(ROInames(:), p(:), df(:), tstat(:), meanR2(:), ci(1,:)', ci(2,:)', ...
                        'VariableNames', {'ROI','p','df','tstat', 'mean', 'lb_mean', 'ub_mean'});
    
    fprintf('ttest crossval R2 > 0 (model-based continuous dataset)\n ')
    disp(crossvalR2)
    if opts.savePlots > 0
        writetable(crossvalR2, fullfile(opts.figureDir, 'stats', sprintf('%s_crossValR2.csv', 'RapidEvent')), ...
               'FileType', 'text', 'Delimiter', ';', ...
               'WriteRowNames', false);
    end

    %-- Report crossval JNeuro
    [~,p,ci,stat]   = ttest(avgCrossR2_jneuro, 0);
    df              = stat.df;
    tstat           = round(stat.tstat, 4);
    meanR2          = mean(avgCrossR2_jneuro,1);
    ROInames        = opts.ROInames;
    
    crossvalR2      = table(ROInames(:), p(:), df(:), tstat(:), meanR2(:), ci(1,:)', ci(2,:)', ...
                        'VariableNames', {'ROI','p','df','tstat', 'mean', 'lb_mean', 'ub_mean'});
    
    fprintf('ttest crossval R2 > 0 (model-based event-related dataset) \n ')
    disp(crossvalR2)
    if opts.savePlots > 0
        writetable(crossvalR2, fullfile(opts.figureDir, 'stats', sprintf('%s_crossValR2.csv', 'JN2022Event')), ...
               'FileType', 'text', 'Delimiter', ';', ...
               'WriteRowNames', false);
    end
end

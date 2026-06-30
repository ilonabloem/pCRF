function suppfig_voxelSelection(opts, allResults)

%-- check inputs
if ~exist('opts', 'var') || isempty(opts)
    opts            = []; 
    opts            = initDefaults(opts);

end
if ~exist('allResults', 'var') || isempty(allResults)
    opts            = initDefaults(opts);
    allResults      = loadModelResults(opts);
end

%-- contrast response parameters 
paramLabels     = {'Rmax', 'Slope', 'C50'};
numSubjects     = numel(opts.subjNames);

%-- setup roi colors
roiColors       = opts.roiColors;

% Scatter plots of parameter estimates
fig             = figure('color', [1 1 1], 'Position', [0 0 780 760]);
set(fig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[780 760])
figlayout       = tiledlayout(2,1);
exp1layout      = tiledlayout(figlayout, 1, 3);
exp1layout.Layout.Tile = 1;
ax1_C50         = nexttile(exp1layout, 1);
ax1_rmax        = nexttile(exp1layout, 2);
ax1_slope       = nexttile(exp1layout, 3);
exp2layout      = tiledlayout(figlayout, 1, 3);
exp2layout.Layout.Tile = 2;
ax2_C50         = nexttile(exp2layout, 1);
ax2_rmax        = nexttile(exp2layout, 2);
ax2_slope       = nexttile(exp2layout, 3);

xvalues         = (ones(4,3) .* [2 4 6]) + (ones(3,4) .* [-0.6 -0.2 0.2 0.6])';
vox_cutoff      = [0.4 0.3 0.2 0.1];
avg_eventparams = NaN(numel(vox_cutoff), numSubjects, numel(paramLabels), numel(opts.ROInames));
avg_contparams  = NaN(numel(vox_cutoff), numSubjects, numel(paramLabels), numel(opts.ROInames));

mrkr_alpha      = 0.3;
indvDotsize     = 20;
errBarWidth     = 2;

for roi = 1:3

    for sub = 1:numSubjects
        
        % parameters from both experiments
        [~, idx]    = ismember(paramLabels, allResults(1).paramLabels);
        eventParam  = allResults(1).allParams{sub,roi}(:,idx);
        contParam   = allResults(2).allParams{sub,roi}(:,idx);
        
        % compute average based on different % cutoffs
        voxThres    = cat(2, true(size(allResults(1).voxThres{sub,roi},1),1), ...
                            allResults(1).voxThres{sub,roi});

        for ii = 1:numel(vox_cutoff)

            avg_eventparams(ii,sub,:,roi) = median(eventParam(voxThres(:,ii),:));
            avg_contparams(ii,sub,:,roi) = median(contParam(voxThres(:,ii),:));

        end

    end

end

% visualize          
hold(ax1_C50, 'on')
hold(ax1_rmax, 'on')
hold(ax1_slope, 'on')
hold(ax2_C50, 'on')
hold(ax2_rmax, 'on')
hold(ax2_slope, 'on')

for ii = 1:numel(vox_cutoff)

    for roi = 1:numel(opts.ROInames)
        
        % exp 1 results
        scatter(ax1_C50, ones(numSubjects,1) * xvalues(ii,roi), avg_eventparams(ii,:,3,roi), 'o', 'MarkerFaceColor', cell2mat(roiColors(roi)) ,'MarkerEdgeColor',cell2mat(roiColors(roi)) ,'SizeData',indvDotsize*2, 'MarkerFaceAlpha',mrkr_alpha, 'MarkerEdgeAlpha',mrkr_alpha, 'HandleVisibility','off');
        scatter(ax1_C50, xvalues(ii,roi), mean(avg_eventparams(ii,:,3,roi)),'o','filled','SizeData',(indvDotsize*6),'MarkerEdgeColor', 'k','MarkerFaceColor', cell2mat(roiColors(roi)));
        errorbar(ax1_C50, xvalues(ii,roi), mean(avg_eventparams(ii,:,3,roi)),std(avg_eventparams(ii,:,3,roi))/sqrt(numSubjects),'k.','CapSize',0, 'lineWidth', errBarWidth, 'handlevisibility', 'off')
    
        scatter(ax1_rmax, ones(numSubjects,1) * xvalues(ii,roi), avg_eventparams(ii,:,1,roi), 'o', 'MarkerFaceColor', cell2mat(roiColors(roi)) ,'MarkerEdgeColor',cell2mat(roiColors(roi)) ,'SizeData',indvDotsize*2, 'MarkerFaceAlpha',mrkr_alpha, 'MarkerEdgeAlpha',mrkr_alpha, 'HandleVisibility','off');
        scatter(ax1_rmax, xvalues(ii,roi), mean(avg_eventparams(ii,:,1,roi)),'o','filled','SizeData',(indvDotsize*6),'MarkerEdgeColor', 'k','MarkerFaceColor', cell2mat(roiColors(roi)));
        errorbar(ax1_rmax, xvalues(ii,roi), mean(avg_eventparams(ii,:,1,roi)),std(avg_eventparams(ii,:,1,roi))/sqrt(numSubjects),'k.','CapSize',0, 'lineWidth', errBarWidth, 'handlevisibility', 'off')
    
        scatter(ax1_slope, ones(numSubjects,1) * xvalues(ii,roi), avg_eventparams(ii,:,2,roi), 'o', 'MarkerFaceColor', cell2mat(roiColors(roi)) ,'MarkerEdgeColor',cell2mat(roiColors(roi)) ,'SizeData',indvDotsize*2, 'MarkerFaceAlpha',mrkr_alpha, 'MarkerEdgeAlpha',mrkr_alpha, 'HandleVisibility','off');
        scatter(ax1_slope, xvalues(ii,roi), mean(avg_eventparams(ii,:,2,roi)),'o','filled','SizeData',(indvDotsize*6),'MarkerEdgeColor', 'k','MarkerFaceColor', cell2mat(roiColors(roi)));
        errorbar(ax1_slope, xvalues(ii,roi), mean(avg_eventparams(ii,:,2,roi)),std(avg_eventparams(ii,:,2,roi))/sqrt(numSubjects),'k.','CapSize',0, 'lineWidth', errBarWidth, 'handlevisibility', 'off')
    
        % exp 2 - continuous results
        scatter(ax2_C50, ones(numSubjects,1) * xvalues(ii,roi), avg_contparams(ii,:,3,roi), 'o', 'MarkerFaceColor', cell2mat(roiColors(roi)) ,'MarkerEdgeColor',cell2mat(roiColors(roi)) ,'SizeData',indvDotsize*2, 'MarkerFaceAlpha',mrkr_alpha, 'MarkerEdgeAlpha',mrkr_alpha, 'HandleVisibility','off');
        scatter(ax2_C50, xvalues(ii,roi), mean(avg_contparams(ii,:,3,roi)),'o','filled','SizeData',(indvDotsize*6),'MarkerEdgeColor', 'k','MarkerFaceColor', cell2mat(roiColors(roi)));
        errorbar(ax2_C50, xvalues(ii,roi), mean(avg_contparams(ii,:,3,roi)),std(avg_contparams(ii,:,3,roi))/sqrt(numSubjects),'k.','CapSize',0, 'lineWidth', errBarWidth, 'handlevisibility', 'off')
    
        scatter(ax2_rmax, ones(numSubjects,1) * xvalues(ii,roi), avg_contparams(ii,:,1,roi), 'o', 'MarkerFaceColor', cell2mat(roiColors(roi)) ,'MarkerEdgeColor',cell2mat(roiColors(roi)) ,'SizeData',indvDotsize*2, 'MarkerFaceAlpha',mrkr_alpha, 'MarkerEdgeAlpha',mrkr_alpha, 'HandleVisibility','off');
        scatter(ax2_rmax, xvalues(ii,roi), mean(avg_contparams(ii,:,1,roi)),'o','filled','SizeData',(indvDotsize*6),'MarkerEdgeColor', 'k','MarkerFaceColor', cell2mat(roiColors(roi)));
        errorbar(ax2_rmax, xvalues(ii,roi), mean(avg_contparams(ii,:,1,roi)),std(avg_contparams(ii,:,1,roi))/sqrt(numSubjects),'k.','CapSize',0, 'lineWidth', errBarWidth, 'handlevisibility', 'off')
    
        scatter(ax2_slope, ones(numSubjects,1) * xvalues(ii,roi), avg_contparams(ii,:,2,roi), 'o', 'MarkerFaceColor', cell2mat(roiColors(roi)) ,'MarkerEdgeColor',cell2mat(roiColors(roi)) ,'SizeData',indvDotsize*2, 'MarkerFaceAlpha',mrkr_alpha, 'MarkerEdgeAlpha',mrkr_alpha, 'HandleVisibility','off');
        scatter(ax2_slope, xvalues(ii,roi), mean(avg_contparams(ii,:,2,roi)),'o','filled','SizeData',(indvDotsize*6),'MarkerEdgeColor', 'k','MarkerFaceColor', cell2mat(roiColors(roi)));
        errorbar(ax2_slope, xvalues(ii,roi), mean(avg_contparams(ii,:,2,roi)),std(avg_contparams(ii,:,2,roi))/sqrt(numSubjects),'k.','CapSize',0, 'lineWidth', errBarWidth, 'handlevisibility', 'off')
    
    end
end

set(ax1_C50, 'xtick', xvalues(:), 'XTickLabel', repmat(vox_cutoff, [1 3]), 'tickdir', 'out', 'YLim', [0 1])
set(ax1_rmax, 'xtick', xvalues(:), 'XTickLabel', repmat(vox_cutoff, [1 3]), 'tickdir', 'out', 'YLim', [0 10])
set(ax1_slope, 'xtick', xvalues(:), 'XTickLabel', repmat(vox_cutoff, [1 3]), 'tickdir', 'out', 'YLim', [0 10])
set(ax2_C50, 'xtick', xvalues(:), 'XTickLabel', repmat(vox_cutoff, [1 3]), 'tickdir', 'out', 'YLim', [0 1])
set(ax2_rmax, 'xtick', xvalues(:), 'XTickLabel', repmat(vox_cutoff, [1 3]), 'tickdir', 'out', 'YLim', [0 10])
set(ax2_slope, 'xtick', xvalues(:), 'XTickLabel', repmat(vox_cutoff, [1 3]), 'tickdir', 'out', 'YLim', [0 10])

xlabel(exp1layout, 'Voxel selection threshold')
xlabel(exp2layout, 'Voxel selection threshold')

title(ax1_C50, 'C50')
title(ax1_rmax, 'rMax')
title(ax1_slope, 'slope')

title(exp1layout, 'Experiment 1 - event related dataset')
title(exp2layout, 'Experiment 2 - continuous dataset')


if opts.savePlots > 0
    if ~exist(fullfile(opts.figureDir, 'SuppFigures'), 'dir'), mkdir(fullfile(opts.figureDir, 'SuppFigures')); end
    print(fig, fullfile(opts.figureDir, 'SuppFigures', sprintf('suppFig_voxelSelection')), '-dpdf', '-vector');
end
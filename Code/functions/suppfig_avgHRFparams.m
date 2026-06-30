function suppfig_avgHRFparams(opts, allResults)

%-- check inputs
if ~exist('opts', 'var') || isempty(opts)
    opts            = []; 
    opts            = initDefaults(opts);

end
if ~exist('allResults', 'var') || isempty(allResults)
    opts            = initDefaults(opts);
    allResults      = loadModelResults(opts);
end

%-- HRF parameters 
paramLabels     = {'gamma', 'weight'};
numSubjects     = numel(opts.subjNames);

%-- setup roi colors
roiColors       = opts.roiColors;

% Scatter plots of parameter estimates
fig             = figure('color', [1 1 1], 'Position', [0 0 780 760]);
set(fig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[780 760])
figlayout       = tiledlayout(2,1);
gammalayout      = tiledlayout(figlayout, 1, 2);
gammalayout.Layout.Tile = 1;
ax1_event       = nexttile(gammalayout, 1);
ax1_cont        = nexttile(gammalayout, 2);
weightlayout      = tiledlayout(figlayout, 1, 2);
weightlayout.Layout.Tile = 2;
ax2_event       = nexttile(weightlayout, 1);
ax2_cont        = nexttile(weightlayout, 2);

xvalues         = 1:3;
avg_eventparams = NaN(numSubjects, numel(paramLabels), numel(opts.ROInames));
avg_contparams  = NaN(numSubjects, numel(paramLabels), numel(opts.ROInames));

mrkr_alpha      = 0.3;
indvDotsize     = 20;
errBarWidth     = 2;

for roi = 1:3

    for sub = 1:numSubjects
        
        % parameters from both experiments
        idx         = 5:6; % gamma and undershoot weight
        eventParam  = allResults(1).allParams{sub,roi}(:,idx);
        contParam   = allResults(2).allParams{sub,roi}(:,idx);
        
        avg_eventparams(sub,:,roi) = median(eventParam,1);
        avg_contparams(sub,:,roi) = median(contParam,1);

    end

end

% visualize          
hold(ax1_event, 'on')
hold(ax1_cont, 'on')
hold(ax2_event, 'on')
hold(ax2_cont, 'on')

for roi = 1:numel(opts.ROInames)
    
    % exp 1 results
    scatter(ax1_event, ones(numSubjects,1) * xvalues(roi), avg_eventparams(:,1,roi), 'o', 'MarkerFaceColor', cell2mat(roiColors(roi)) ,'MarkerEdgeColor',cell2mat(roiColors(roi)) ,'SizeData',indvDotsize*2, 'MarkerFaceAlpha',mrkr_alpha, 'MarkerEdgeAlpha',mrkr_alpha, 'HandleVisibility','off');
    scatter(ax1_event, xvalues(roi), mean(avg_eventparams(:,1,roi)),'o','filled','SizeData',(indvDotsize*6),'MarkerEdgeColor', 'k','MarkerFaceColor', cell2mat(roiColors(roi)));
    errorbar(ax1_event, xvalues(roi), mean(avg_eventparams(:,1,roi)),std(avg_eventparams(:,1,roi))/sqrt(numSubjects),'k.','CapSize',0, 'lineWidth', errBarWidth, 'handlevisibility', 'off')

    scatter(ax2_event, ones(numSubjects,1) * xvalues(roi), avg_eventparams(:,2,roi), 'o', 'MarkerFaceColor', cell2mat(roiColors(roi)) ,'MarkerEdgeColor',cell2mat(roiColors(roi)) ,'SizeData',indvDotsize*2, 'MarkerFaceAlpha',mrkr_alpha, 'MarkerEdgeAlpha',mrkr_alpha, 'HandleVisibility','off');
    scatter(ax2_event, xvalues(roi), mean(avg_eventparams(:,2,roi)),'o','filled','SizeData',(indvDotsize*6),'MarkerEdgeColor', 'k','MarkerFaceColor', cell2mat(roiColors(roi)));
    errorbar(ax2_event, xvalues(roi), mean(avg_eventparams(:,2,roi)),std(avg_eventparams(:,2,roi))/sqrt(numSubjects),'k.','CapSize',0, 'lineWidth', errBarWidth, 'handlevisibility', 'off')

    % exp 2 - continuous results
    scatter(ax1_cont, ones(numSubjects,1) * xvalues(roi), avg_contparams(:,1,roi), 'o', 'MarkerFaceColor', cell2mat(roiColors(roi)) ,'MarkerEdgeColor',cell2mat(roiColors(roi)) ,'SizeData',indvDotsize*2, 'MarkerFaceAlpha',mrkr_alpha, 'MarkerEdgeAlpha',mrkr_alpha, 'HandleVisibility','off');
    scatter(ax1_cont, xvalues(roi), mean(avg_contparams(:,1,roi)),'o','filled','SizeData',(indvDotsize*6),'MarkerEdgeColor', 'k','MarkerFaceColor', cell2mat(roiColors(roi)));
    errorbar(ax1_cont, xvalues(roi), mean(avg_contparams(:,1,roi)),std(avg_contparams(:,1,roi))/sqrt(numSubjects),'k.','CapSize',0, 'lineWidth', errBarWidth, 'handlevisibility', 'off')

    scatter(ax2_cont, ones(numSubjects,1) * xvalues(roi), avg_contparams(:,2,roi), 'o', 'MarkerFaceColor', cell2mat(roiColors(roi)) ,'MarkerEdgeColor',cell2mat(roiColors(roi)) ,'SizeData',indvDotsize*2, 'MarkerFaceAlpha',mrkr_alpha, 'MarkerEdgeAlpha',mrkr_alpha, 'HandleVisibility','off');
    scatter(ax2_cont, xvalues(roi), mean(avg_contparams(:,2,roi)),'o','filled','SizeData',(indvDotsize*6),'MarkerEdgeColor', 'k','MarkerFaceColor', cell2mat(roiColors(roi)));
    errorbar(ax2_cont, xvalues(roi), mean(avg_contparams(:,2,roi)),std(avg_contparams(:,2,roi))/sqrt(numSubjects),'k.','CapSize',0, 'lineWidth', errBarWidth, 'handlevisibility', 'off')

        
end


set(ax1_event, 'xtick', xvalues(:), 'XTickLabel', {'V1', 'V2', 'V3'}, 'tickdir', 'out', 'YLim', [3 8], 'XLim', [0 4])
set(ax2_event, 'xtick', xvalues(:), 'XTickLabel', {'V1', 'V2', 'V3'}, 'tickdir', 'out', 'YLim', [0.2 1], 'XLim', [0 4])
set(ax1_cont, 'xtick', xvalues(:), 'XTickLabel', {'V1', 'V2', 'V3'}, 'tickdir', 'out', 'YLim', [3 8], 'XLim', [0 4])
set(ax2_cont, 'xtick', xvalues(:), 'XTickLabel', {'V1', 'V2', 'V3'}, 'tickdir', 'out', 'YLim', [0.2 1], 'XLim', [0 4])


title(ax1_event, 'Experiment 1 - event related dataset')
title(ax1_cont, 'Experiment 2 - continuous dataset')

title(gammalayout, 'Gamma')
title(weightlayout, 'Weight undershoot')


if opts.savePlots > 0
    if ~exist(fullfile(opts.figureDir, 'SuppFigures'), 'dir'), mkdir(fullfile(opts.figureDir, 'SuppFigures')); end
    print(fig, fullfile(opts.figureDir, 'SuppFigures', sprintf('suppFig_HRFparams')), '-dpdf', '-vector');
end
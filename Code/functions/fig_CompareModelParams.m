function fig_CompareModelParams(opts, taskResults)

%-- check inputs
if  ~exist('opts', 'var') || isempty(opts)
    opts            = []; 
    opts            = initDefaults(opts);

end
if  ~exist('taskResults', 'var') || isempty(taskResults)
    opts.tasks      = {'JN2022Event'};
    opts            = initDefaults(opts);
    taskResults     = loadModelResults(opts);
end

%--
numSubjects     = numel(opts.subjNames);

paramLabels     = {'Rmax', 'Slope', 'C50'};

%-- setup roi colors
roiColors   = opts.roiColors;
roiColorMap = makeROIColormap(roiColors);

% Scatter plots of parameter estimates
fig         = figure('color', [1 1 1], 'Position', [0 0 780 760]);
set(fig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[780 760])
figlayout   = tiledlayout(3,1);
c50layout   = tiledlayout(figlayout, 1, 4);
rmaxlayout  = tiledlayout(figlayout, 1, 4);
slopelayout = tiledlayout(figlayout, 1, 4);
numBins     = 40;
ptsC50      = linspace(0,1,numBins+1);
ptsRmax     = linspace(0,10,numBins+1);
ptsSlope    = linspace(0,10,numBins+1);

for roi = 1:3

    % compute 2d histogram for each participant                    
    nC50        = NaN(numBins, numBins, numSubjects);
    nRmax       = NaN(numBins, numBins, numSubjects);
    nSlope      = NaN(numBins, numBins, numSubjects);
    
    for sub = 1:numSubjects
        
        % Reorder parameters to match 2 models
        [~, idx]    = ismember(paramLabels, taskResults.paramLabels);
        pCRFParam   = taskResults.allParams{sub,roi}(:,idx);
        deconvParam = taskResults.jneuroParams(sub,roi).est_params_allVoxels ./ [1 1 100];

        % C50
        indx            = strcmp(paramLabels, 'C50');
        nC50(:,:,sub)   = histcounts2(deconvParam(:,indx), pCRFParam(:,indx), ...
                                     ptsC50, ptsC50, 'Normalization', 'probability'); 

        % Rmax
        indx            = contains(paramLabels, 'Rmax');
        nRmax(:,:,sub)  = histcounts2(deconvParam(:,indx), pCRFParam(:,indx), ...
                                    ptsRmax, ptsRmax, 'Normalization', 'probability'); 

        % Slope
        indx            = strcmp(paramLabels, 'Slope');
        nSlope(:,:,sub) = histcounts2(deconvParam(:,indx), pCRFParam(:,indx), ...
                                    ptsSlope, ptsSlope, 'Normalization', 'probability'); 
    end
    
    % C50
    c50layout.Layout.Tile = 1;
    ax = nexttile(c50layout);    
    imagesc(ptsC50, ptsC50, mean(nC50,3));      
    set(gca, 'XLim', ptsC50([1 end]), 'XTick', [0 .5 1], 'XTickLabel', [0 50 100], ...
        'YLim', ptsC50([1 end]), 'YTick', [0 .5 1], 'YTickLabel', [0 50 100], ...
        'YDir', 'normal');
    colormap(ax, roiColorMap{roi})
    caxis(ax,[0 0.01])
    axis square; box off
    if roi == 1
        ylabel('Deconvolution Estimates', 'FontSize', 10)
        xlabel('Model-based Estimates', 'FontSize', 10)
        title(c50layout, 'Semi-saturation (C50)', 'FontSize', 14)
    end
    
    % rMax
    rmaxlayout.Layout.Tile = 2;
    ax  = nexttile(rmaxlayout);
    imagesc(ptsRmax, ptsRmax, mean(nRmax,3));
    set(gca, 'XLim', ptsRmax([1 end]), 'XTick', ptsRmax([1 21 41]), ...
        'YLim', ptsRmax([1 end]), 'YTick', ptsRmax([1 21 41]), ...
        'YDir', 'normal');
    colormap(ax, roiColorMap{roi})
    caxis(ax, [0 0.01]); box off
    axis square

    if roi == 1
        ylabel('Deconvolution Estimates', 'FontSize', 10)
        xlabel('Model-based Estimates', 'FontSize', 10)
        title(rmaxlayout, 'Response saturation (Rmax)', 'FontSize', 14)
    end

    % slope
    slopelayout.Layout.Tile = 3;
    ax  = nexttile(slopelayout);
    imagesc(ptsSlope, ptsSlope, mean(nSlope,3));
    set(gca, 'XLim', ptsSlope([1 end]), 'XTick', ptsSlope([1 21 41]), ...
        'YLim', ptsSlope([1 end]), 'YTick', ptsSlope([1 21 41]), ...
        'YDir', 'normal');
    colormap(ax, roiColorMap{roi})
    caxis(ax, [0 0.01])
    axis square; box off
    
    if roi == 1
        ylabel('Deconvolution Estimates', 'FontSize', 10)
        xlabel('Model-based Estimates', 'FontSize', 10)
        title(slopelayout, 'Transducer (n)', 'FontSize', 14)
    end

end

%-- Correlation 
% C50
c50layout.Layout.Tile = 1;
ax1 = nexttile(c50layout);

% rMax
rmaxlayout.Layout.Tile = 2;
ax2 = nexttile(rmaxlayout);

% slope
slopelayout.Layout.Tile = 3;
ax3 = nexttile(slopelayout);

mrkr_alpha      = 0.3;
indvDotsize     = 20;
errBarWidth     = 2;
for roi = 1:numel(opts.ROInames)
    
    fishz_corr  = taskResults.fisherCorr(:,:,roi);
    corr        = tanh(fishz_corr);
    avg_corr    = tanh(mean(fishz_corr,1));
    std_corr    = tanh(std(fishz_corr));
       
    % c50
    hold(ax1, 'on'),
    % plot scatter subjs (low opacity, match ROI color)
    scatter(ax1, roi*ones(1,numSubjects), corr(:,3), 'o', ...
        'MarkerFaceColor', cell2mat(roiColors(roi)) ,'MarkerEdgeColor',cell2mat(roiColors(roi)), ...
        'SizeData',indvDotsize*2, 'MarkerFaceAlpha',mrkr_alpha, 'MarkerEdgeAlpha',mrkr_alpha, 'HandleVisibility','off');

    % plot scatter ROI means (high opacity, with error bars, ROI color)
    scatter(ax1, roi, avg_corr(:,3),'o','filled','SizeData',(indvDotsize*6),'MarkerEdgeColor', 'k','MarkerFaceColor', cell2mat(roiColors(roi)));
    errorbar(ax1, roi, avg_corr(:,3), std_corr(:,3)/sqrt(numSubjects),'k.','CapSize',0, 'lineWidth', errBarWidth, 'handlevisibility', 'off')

    if roi == 3
        %legend(ax1, ['V1';'V2';'V3'], 'Location', 'NorthWest', 'box', 'off', 'fontsize', 10)
        ylabel(ax1, 'corr','FontSize',10)
        set(ax1, 'XLim', [0 4], 'XTick', 1:3, 'XTickLabel', opts.ROInames, ...
            'YLim', [-0.2 1])
%         set(ax1, 'XLim', [0 1], 'XTick',0:.5:1, 'XtickLabels', [0 50 100], ...
%             'YLim', [0 1], 'YTick', 0:.5:1, 'YtickLabels', [0 50 100]);
    end

    % Rmax
    hold(ax2, 'on'),
    % plot scatter subjs (low opacity, match ROI color)
    scatter(ax2, roi*ones(1,numSubjects), corr(:,1), 'o', ...
        'MarkerFaceColor', cell2mat(roiColors(roi)) ,'MarkerEdgeColor',cell2mat(roiColors(roi)), ...
        'SizeData',indvDotsize*2, 'MarkerFaceAlpha',mrkr_alpha, 'MarkerEdgeAlpha',mrkr_alpha, 'HandleVisibility','off');

    % plot scatter ROI means (high opacity, with error bars, ROI color)
    scatter(ax2, roi, avg_corr(:,1),'o','filled','SizeData',(indvDotsize*6),'MarkerEdgeColor', 'k','MarkerFaceColor', cell2mat(roiColors(roi)));
    errorbar(ax2, roi, avg_corr(:,1), std_corr(:,1)/sqrt(numSubjects),'k.','CapSize',0, 'lineWidth', errBarWidth, 'handlevisibility', 'off')

    if roi == 3
%         legend(ax2, ['V1';'V2';'V3'], 'Location', 'NorthWest', 'box', 'off', 'fontsize', 10)
        ylabel(ax2, 'corr','FontSize',10)
        set(ax2, 'XLim', [0 4], 'XTick', 1:3, 'XTickLabel', opts.ROInames, ...
            'YLim', [-0.2 1])
        %set(ax2, 'XLim', [0 10], 'XTick',0:5:10, 'YLim', [0 10], 'YTick', 0:5:10);
    end

    % Slope
    hold(ax3, 'on'),
    % plot scatter subjs (low opacity, match ROI color)
    scatter(ax3, roi*ones(1,numSubjects), corr(:,2), 'o', ...
        'MarkerFaceColor', cell2mat(roiColors(roi)) ,'MarkerEdgeColor',cell2mat(roiColors(roi)), ...
        'SizeData',indvDotsize*2, 'MarkerFaceAlpha',mrkr_alpha, 'MarkerEdgeAlpha',mrkr_alpha, 'HandleVisibility','off');

    % plot scatter ROI means (high opacity, with error bars, ROI color)
    scatter(ax3, roi, avg_corr(:,2),'o','filled','SizeData',(indvDotsize*6),'MarkerEdgeColor', 'k','MarkerFaceColor', cell2mat(roiColors(roi)));
    errorbar(ax3, roi, avg_corr(:,2), std_corr(:,2)/sqrt(numSubjects),'k.','CapSize',0, 'lineWidth', errBarWidth, 'handlevisibility', 'off')

    if roi == 3 
%         legend(ax3, ['V1';'V2';'V3'], 'Location', 'NorthWest', 'box', 'off', 'fontsize', 10)
        ylabel(ax3, 'corr','FontSize',10)
        set(ax3, 'XLim', [0 4], 'XTick', 1:3, 'XTickLabel', opts.ROInames, ...
            'YLim', [-0.2 1])
        %set(ax3, 'XLim', [0 10], 'XTick',0:5:10, 'YLim', [0 10], 'YTick', 0:5:10);
    end

end

if opts.savePlots > 0
    if ~exist(fullfile(opts.figureDir, 'Figure4'), 'dir'), mkdir(fullfile(opts.figureDir, 'Figure4')); end
    print(fig, fullfile(opts.figureDir, 'Figure4', sprintf('Fig4_ModelComparison_CRFparam')), '-dpdf');
end

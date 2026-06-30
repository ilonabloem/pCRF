function out = fig_semisaturationVSeccen(opts, allResults)

%-- check inputs
if  ~exist('opts', 'var') || isempty(opts)
    opts            = []; 
    opts            = initDefaults(opts);

end
if  ~exist('allResults', 'var') || isempty(allResults)
    opts            = initDefaults(opts);
    allResults      = loadModelResults(opts);
end

%--
numSubjects     = numel(opts.subjNames);

%-- Visualize parameters as a function of eccentricity
paramLabels     = {'Rmax', 'Slope', 'C50'};

%-- setup roi colors
roiColors   = opts.roiColors;
roiColorMap = makeROIColormap(roiColors);

% Scatter plots of parameter estimates
fig        = figure('color', [1 1 1], 'Position', [0 0 780 760]);
set(fig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[780 760])
figlayout   = tiledlayout(2,1);
eccenlayout = tiledlayout(figlayout, 1, 3);
paramlayout = tiledlayout(figlayout, 1, 3);
numBins     = 40;
ptsC50      = linspace(0,1,numBins+1);
ptsEccen    = linspace(0,10,numBins+1);

avg_pCRFparams  = NaN(numSubjects, 3, numel(opts.ROInames));
avg_deconvparams= NaN(numSubjects, 3, numel(opts.ROInames));

for roi = 1:3

    % compute 2d histogram for each participant                    
    nEvent      = NaN(numBins, numBins, numSubjects);
    nCont       = NaN(numBins, numBins, numSubjects);
    
    for sub = 1:numSubjects
        
        % Reorder parameters to match 2 models
        [~, idx]    = ismember(paramLabels, allResults(1).paramLabels);
        pCRFParam   = allResults(1).allParams{sub,roi}(:,idx);
        deconvParam = allResults(1).jneuroParams(sub,roi).est_params_allVoxels ./ [1 1 100];

        indx        = strcmp(paramLabels, 'C50');
        deconvC50   = deconvParam(:,indx);
        modelC50     = pCRFParam(:,indx);
        eccen       = allResults(1).prfEcc{sub, roi};

        % jneuro eventrelated C50 vs eccen
        nEvent(:,:,sub)   = histcounts2(deconvC50(:), eccen, ...
                                     ptsC50, ptsEccen, 'Normalization', 'probability'); 

        % continuous c50 vs eccen
        nCont(:,:,sub)  = histcounts2(modelC50(:), eccen, ...
                                    ptsC50, ptsEccen, 'Normalization', 'probability'); 
                                
        % save average parameter estimates       
        avg_pCRFparams(sub,:,roi)     = median(pCRFParam, 'omitnan');
        avg_deconvparams(sub,:,roi)   = median(deconvParam, 'omitnan');
 
    end
    
    % event-related c50
    eccenlayout.Layout.Tile = 2;
    ax = nexttile(eccenlayout);    
    imagesc(ptsEccen, ptsC50, mean(nEvent,3));      
    set(gca, 'XLim', ptsEccen([1 end]), 'XTick', [0 5 10], 'XTickLabel', [0 5 10], ...
        'YLim', ptsC50([1 end]), 'YTick', [0 .5 1], 'YTickLabel', [0 50 100], ...
        'YDir', 'normal');
    colormap(ax, roiColorMap{roi})
    caxis(ax,[0 0.005])
    axis square; box off
    if roi == 1
        xlabel('Eccentricity', 'FontSize', 10)
        ylabel('C50 model-based estimates', 'FontSize', 10)
        title(eccenlayout, 'Event-related dataset', 'FontSize', 14)
    end
    
    % continuous c50
%     contlayout.Layout.Tile = 2;
%     ax  = nexttile(contlayout);
%     imagesc(ptsEccen, ptsC50, mean(nCont,3));
%     set(gca, 'XLim', ptsEccen([1 end]), 'XTick', ptsEccen([1 21 41]), ...
%         'YLim', ptsC50([1 end]), 'YTick', ptsC50([1 21 41])*100, ...
%         'YDir', 'normal');
%     colormap(ax, roiColorMap{roi})
%     caxis(ax, [0 0.005]); box off
%     axis square
% 
%     if roi == 1
%         xlabel('Eccentricity', 'FontSize', 10)
%         ylabel('C50 Model-based Estimates', 'FontSize', 10)
%         title(contlayout, 'Continuous dataset', 'FontSize', 14)
%     end

end

%-- avg param comparison
% C50
paramlayout.Layout.Tile = 1;
ax1 = nexttile(paramlayout);

% rMax
ax2 = nexttile(paramlayout);

% slope
ax3 = nexttile(paramlayout);

mrkr_alpha      = 0.3;
indvDotsize     = 20;
errBarWidth     = 2;
for roi = 1:numel(opts.ROInames)

    % c50
    hold(ax1, 'on'),
    % plot scatter subjs (low opacity, match ROI color)
    scatter(ax1, avg_pCRFparams(:,3,roi), avg_deconvparams(:,3,roi), 'o', 'MarkerFaceColor', cell2mat(roiColors(roi)) ,'MarkerEdgeColor',cell2mat(roiColors(roi)) ,'SizeData',indvDotsize*2, 'MarkerFaceAlpha',mrkr_alpha, 'MarkerEdgeAlpha',mrkr_alpha, 'HandleVisibility','off');
    if roi == 3
        % trend line 1,1
        plot(ax1, linspace(0,1,10),linspace(0,1,10), 'k--','HandleVisibility','off')
        for rroi=1:3
            % plot scatter ROI means (high opacity, with error bars, ROI color)
            scatter(ax1, mean(avg_pCRFparams(:,3,rroi)), mean(avg_deconvparams(:,3,rroi)),'o','filled','SizeData',(indvDotsize*6),'MarkerEdgeColor', 'k','MarkerFaceColor', cell2mat(roiColors(rroi)));
            errorbar(ax1, mean(avg_pCRFparams(:,3,rroi)), mean(avg_deconvparams(:,3,rroi)),std(avg_pCRFparams(:,3,rroi))/sqrt(numSubjects),'k.','horizontal','CapSize',0, 'lineWidth', errBarWidth, 'handlevisibility', 'off')
            errorbar(ax1, mean(avg_pCRFparams(:,3,rroi)), mean(avg_deconvparams(:,3,rroi)),std(avg_deconvparams(:,3,rroi))/sqrt(numSubjects),'k.','vertical','CapSize',0, 'lineWidth', errBarWidth, 'handlevisibility', 'off')
        end

        legend(ax1, ['V1';'V2';'V3'], 'Location', 'NorthWest', 'box', 'off', 'fontsize', 16)
        xlabel(ax1, 'Model-based C50','FontSize',10), 
        ylabel(ax1, 'Deconvolution C50','FontSize',10)
        set(ax1, 'XLim', [0 1], 'XTick',0:.5:1, 'XtickLabels', [0 50 100], ...
            'YLim', [0 1], 'YTick', 0:.5:1, 'YtickLabels', [0 50 100]);
        axis(ax1, 'square');
    end

    % Rmax
    hold(ax2, 'on'),
    % plot scatter subjs (low opacity, match ROI color)
    scatter(ax2, avg_pCRFparams(:,1,roi), avg_deconvparams(:,1,roi), 'o', 'MarkerFaceColor', cell2mat(roiColors(roi)) ,'MarkerEdgeColor',cell2mat(roiColors(roi)) ,'SizeData',indvDotsize*2, 'MarkerFaceAlpha',mrkr_alpha, 'MarkerEdgeAlpha',mrkr_alpha, 'HandleVisibility','off');
    if roi == 3
        % trend line 1,1
        plot(ax2, [0 10],[0 10], 'k--','HandleVisibility','off')
        for rroi=1:3
            % plot scatter ROI means (high opacity, with error bars, ROI color)
            scatter(ax2, mean(avg_pCRFparams(:,1,rroi)), mean(avg_deconvparams(:,1,rroi)),'o','filled','SizeData',(indvDotsize*6),'MarkerEdgeColor', 'k','MarkerFaceColor', cell2mat(roiColors(rroi)));
            errorbar(ax2, mean(avg_pCRFparams(:,1,rroi)), mean(avg_deconvparams(:,1,rroi)),std(avg_pCRFparams(:,1,rroi))/sqrt(numSubjects),'k.','horizontal','CapSize',0, 'lineWidth', errBarWidth, 'handlevisibility', 'off')
            errorbar(ax2, mean(avg_pCRFparams(:,1,rroi)), mean(avg_deconvparams(:,1,rroi)),std(avg_deconvparams(:,1,rroi))/sqrt(numSubjects),'k.','vertical','CapSize',0, 'lineWidth', errBarWidth, 'handlevisibility', 'off')
        end

        legend(ax2, ['V1';'V2';'V3'], 'Location', 'NorthWest', 'box', 'off', 'fontsize', 16)
        xlabel(ax2, 'Model-based Rmax','FontSize',10), 
        ylabel(ax2, 'Deconvolution Rmax','FontSize',10)
        set(ax2, 'XLim', [0 10], 'XTick',0:5:10, 'YLim', [0 10], 'YTick', 0:5:10);
        axis(ax2, 'square');
    end

    % Slope
    hold(ax3, 'on'),
    % plot scatter subjs (low opacity, match ROI color)
    scatter(ax3, avg_pCRFparams(:,2,roi), avg_deconvparams(:,2,roi), 'o', 'MarkerFaceColor', cell2mat(roiColors(roi)) ,'MarkerEdgeColor',cell2mat(roiColors(roi)) ,'SizeData',indvDotsize*2, 'MarkerFaceAlpha',mrkr_alpha, 'MarkerEdgeAlpha',mrkr_alpha, 'HandleVisibility','off');
    if roi == 3
        % trend line 1,1
        plot(ax3, [0 10],[0 10], 'k--','HandleVisibility','off')
        for rroi=1:3
            % plot scatter ROI means (high opacity, with error bars, ROI color)
            scatter(ax3, mean(avg_pCRFparams(:,2,rroi)), mean(avg_deconvparams(:,2,rroi)),'o','filled','SizeData',(indvDotsize*6),'MarkerEdgeColor', 'k','MarkerFaceColor', cell2mat(roiColors(rroi)));
            errorbar(ax3, mean(avg_pCRFparams(:,2,rroi)), mean(avg_deconvparams(:,2,rroi)),std(avg_pCRFparams(:,2,rroi))/sqrt(numSubjects),'k.','horizontal','CapSize',0, 'lineWidth', errBarWidth, 'handlevisibility', 'off')
            errorbar(ax3, mean(avg_pCRFparams(:,2,rroi)), mean(avg_deconvparams(:,2,rroi)),std(avg_deconvparams(:,2,rroi))/sqrt(numSubjects),'k.','vertical','CapSize',0, 'lineWidth', errBarWidth, 'handlevisibility', 'off')
        end

        legend(ax3, ['V1';'V2';'V3'], 'Location', 'NorthWest', 'box', 'off', 'fontsize', 16)
        xlabel(ax3, 'Model-based n','FontSize',10), 
        ylabel(ax3, 'Deconvolution n','FontSize',10)
        set(ax3, 'XLim', [0 10], 'XTick',0:5:10, 'YLim', [0 10], 'YTick', 0:5:10);
        axis(ax3, 'square');
    end

end

if opts.savePlots > 0
    if ~exist(fullfile(opts.figureDir, 'Figure4'), 'dir'), mkdir(fullfile(opts.figureDir, 'Figure4')); end
    print(fig4, fullfile(opts.figureDir, 'Figure4', sprintf('Fig4_ModelComparison_CRFparam')), '-dpdf');
end


out.modelbasedParams    = avg_pCRFparams;
out.deconvParams        = avg_deconvparams;
out.paramLabels         = paramLabels;

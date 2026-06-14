function fig_shapeComparison(opts, taskResults)

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
numSubjects = numel(opts.subjNames);

paramLabels = {'Rmax', 'Slope', 'C50'};
roiColors   = opts.roiColors;

exmplSubj   = '004';

% Scatter plots of parameter estimates
fig         = figure('color', [1 1 1], 'Position', [0 0 780 380]);
set(fig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[780 380])
figlayout   = tiledlayout(1,2);
R2layout    = tiledlayout(figlayout, 1, 1);
R2layout.Layout.Tile = 1;
ax          = nexttile(R2layout,1);

roilayout   = tiledlayout(figlayout, 2, 3);
roilayout.Layout.Tile = 2;

med_R2shape = NaN(numSubjects, 3);

% setup model: 
NRFunc      = @(a1, c) (a1(1)).*((c.^a1(2))./((c.^a1(2)) + (a1(3).^a1(2))) );
xvalues     = 0.16 * [1/6 1/4 1/3 1/2 1 2 3 4 6];

%xvalues         = 10.^linspace(log10(0.02),log10(1),100);
mrkr_alpha  = 0.3;
indvDotsize = 20;
errBarWidth = 2;

for roi = 1:3

    for sub = 1:numSubjects
        
        % Reorder parameters to match 2 models
        [~, idx]    = ismember(paramLabels, taskResults.paramLabels);
        pCRFParam   = taskResults.allParams{sub,roi}(:,idx);
        deconvParam = taskResults.jneuroParams(sub,roi).est_params_allVoxels ./ [1 1 100];

        % compare CRF curves 
        RMSE_shape  = NaN(size(pCRFParam,1),1);
        R2_shape    = NaN(size(pCRFParam,1),1);
        SS_res      = NaN(size(pCRFParam,1),1);
        SS_tot      = NaN(size(pCRFParam,1),1);
        deconCRF    = NaN(size(pCRFParam,1), numel(xvalues));
        fitCRF      = NaN(size(pCRFParam,1), numel(xvalues));

        for ii = 1:size(pCRFParam,1)
            deconCRF(ii,:)  = NRFunc(deconvParam(ii,:), xvalues);
            fitCRF(ii,:)    = NRFunc(pCRFParam(ii,:), xvalues);

            SS_res(ii)      = sum((deconCRF(ii,:) - fitCRF(ii,:)).^2);
            SS_tot(ii)      = sum((deconCRF(ii,:) - mean(deconCRF(ii,:))).^2);
            tol_SS          = 1e-6;  % 
            
            if SS_tot(ii) > tol_SS
                R2_shape(ii) = 1 - SS_res(ii)/SS_tot(ii);
            end
            
            RMSE        = sqrt(mean((deconCRF(ii,:) - fitCRF(ii,:)).^2));
            rangeCRF    = max(deconCRF(ii,:))-min(deconCRF(ii,:));
            if rangeCRF > 0
                RMSE_shape(ii) = RMSE / rangeCRF;
            end
            
        end
        
        selectR2                = R2_shape;
        selectR2(R2_shape < -5) = NaN;
        numOutlierVox(sub,roi)  = sum(isnan(selectR2));
        ratioOutlier(sub,roi)   = numOutlierVox(sub,roi) / size(pCRFParam,1);
        med_R2shape(sub,roi)    = median(selectR2, 'omitnan');      
        
        %-- keep example sub CRF shapes
        if strcmp(opts.subjNames{sub}, exmplSubj)
            
            exmpdeconCRFs   = deconCRF; 
            exmpfitCRF      = fitCRF;
            normRes         = (deconCRF - fitCRF) ./ deconCRF(:,end); % last value is always largest
            % remove extreme values
            outlier         = sum(normRes,2) < -5; 
            normRes(outlier,:) = NaN;
            exmpdeconCRFs(outlier,:) = NaN;
            exmpfitCRF(outlier,:) = NaN;

            exmplR2s        = R2_shape;
        end

    end    

    %-- visualize R2 across ROIs
    hold(ax, 'on'),
    % plot scatter subjs (low opacity, match ROI color)
    scatter(ax, roi*ones(1,numSubjects), med_R2shape(:,roi), 'o', ...
        'MarkerFaceColor', cell2mat(roiColors(roi)) ,'MarkerEdgeColor',cell2mat(roiColors(roi)), ...
        'SizeData',indvDotsize*2, 'MarkerFaceAlpha',mrkr_alpha, 'MarkerEdgeAlpha',mrkr_alpha, 'HandleVisibility','off');

    % plot scatter ROI means (high opacity, with error bars, ROI color)
    scatter(ax, roi, mean(med_R2shape(:,roi)),'o','filled','SizeData',(indvDotsize*6),'MarkerEdgeColor', 'k','MarkerFaceColor', cell2mat(roiColors(roi)));
    errorbar(ax, roi, mean(med_R2shape(:,roi)), std(med_R2shape(:,roi))/sqrt(numSubjects),'k.','CapSize',0, 'lineWidth', errBarWidth, 'handlevisibility', 'off')

    if roi == 3
        ylabel(ax, 'R2','FontSize',10)
        set(ax, 'XLim', [0 4], 'XTick', 1:3, 'XTickLabel', opts.ROInames, 'TickDir', 'out')
    end

    %-- visualize representative participants CRF curves
    ax1         = nexttile(roilayout,roi);

    % create colormap based on R2
    R2_clipped  = max(0, min(1, exmplR2s)); 
    w           = R2_clipped .^4; 
    
    % Interpolate colors based on R2
    alpha_min   = 0; 
    alpha_max   = 0.9;  
    alphaVals   = alpha_min + (alpha_max - alpha_min) .* w;
    
    % scale opacity with R2
    deconColors = cat(2, [0.5 0.5 0.5] .* ones(size(R2_clipped,1),3), alphaVals);
    fitColors   = cat(2, opts.roiColors{roi} .* ones(size(R2_clipped,1),3), alphaVals);

    hold(ax1, 'on'),
    h1 = semilogx(ax1, xvalues*100, exmpdeconCRFs);
    set(h1, {'Color'}, num2cell((deconColors), 2));
    
    h2 = semilogx(ax1, xvalues*100, exmpfitCRF);
    set(h2, {'Color'}, num2cell((fitColors), 2));

    set(ax1, 'XScale', 'log', 'xtick', [10 100], 'XTickLabel', [10 100], 'TickDir', 'out')
    if roi == 1
        ylims = [0 12]; 
    end
    ylim(ylims)
    minorTicks = [2:1:9 20:10:90];
    ax1.XMinorTick = 'on';
    ax1.XAxis.MinorTickValues = minorTicks;
    ax1.TickLength = [0.02 0.05];
    title({opts.ROInames{roi}; ...
        sprintf('avg R2 = %.2f', med_R2shape(strcmp(opts.subjNames, exmplSubj),roi))});
    ylabel('Response')
    xlabel('Contrast')

    %-- visualize normalized residuals
    ax2         = nexttile(roilayout,roi+numel(opts.ROInames));
    h = semilogx(ax2, xvalues*100, normRes);
    set(ax2, 'XScale', 'log', 'xtick', [10 100], 'XTickLabel', [10 100], 'TickDir', 'out')
    ax2.XMinorTick = 'on';
    ax2.XAxis.MinorTickValues = minorTicks;
    ax2.TickLength = [0.02 0.05];
    set(h, {'Color'}, num2cell((fitColors), 2));
    ylabel('Normalized Residuals')
    xlabel('Contrast')
    ylim([-0.8 0.8]); box off;
end

title(R2layout, 'CRF shape comparison')
title(roilayout, 'Representative participant')

if opts.savePlots > 0
    if ~exist(fullfile(opts.figureDir, 'Figure5'), 'dir'), mkdir(fullfile(opts.figureDir, 'Figure5')); end
    print(fig, fullfile(opts.figureDir, 'Figure5', sprintf('Fig5_CRFshapeComparison')), '-dpdf');
end



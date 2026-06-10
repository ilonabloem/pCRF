function out = fig_shapeComparison(opts, taskResults)

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
roiColorMap = makeROIColormap(roiColors);

exmplSubj   = '004';
whichROI    = 'V1';
voxID       = 201;

% Scatter plots of parameter estimates
fig         = figure('color', [1 1 1], 'Position', [0 0 780 760]);
set(fig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[780 760])
figlayout   = tiledlayout(1,2);
ax1 = nexttile(figlayout,1);
ax2 = nexttile(figlayout,2);
med_R2shape = NaN(numSubjects, 3);

% setup model: 
NRFunc          = @(a1, c) (a1(1)).*((c.^a1(2))./((c.^a1(2)) + (a1(3).^a1(2))) );
xvalues         = 0.16 * [1/6 1/4 1/3 1/2 1 2 3 4 6];
%xvalues         = 10.^linspace(log10(0.02),log10(1),100);
mrkr_alpha      = 0.3;
indvDotsize     = 20;
errBarWidth     = 2;
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
        for ii = 1:size(pCRFParam,1)
            deconCRF    = NRFunc(deconvParam(ii,:), xvalues);
            fitCRF      = NRFunc(pCRFParam(ii,:), xvalues);

            SS_res(ii)      = sum((deconCRF - fitCRF).^2);
            SS_tot(ii)      = sum((deconCRF - mean(deconCRF)).^2);
            tol_SS          = 1e-6;  % 
            
            if SS_tot(ii) > tol_SS
                R2_shape(ii) = 1 - SS_res(ii)/SS_tot(ii);
            end
            
            RMSE        = sqrt(mean((deconCRF - fitCRF).^2));
            rangeCRF    = max(deconCRF)-min(deconCRF);
            if rangeCRF > 0
                RMSE_shape(ii) = RMSE / rangeCRF;
            end
            
            if strcmp(opts.subjNames{sub}, exmplSubj) && ...
               strcmp(opts.ROInames{roi}, whichROI) && ...
               ii == voxID          
                
                exmplCRFs   = [deconCRF; fitCRF];
                exmplR2     = R2_shape(ii);
            end
            
        end
        
        selectR2 = R2_shape;
        selectR2(R2_shape < -5) = NaN;
        numOutlierVox(sub,roi) = sum(isnan(selectR2));
        ratioOutlier(sub,roi) = numOutlierVox(sub,roi) / size(pCRFParam,1);
        med_R2shape(sub,roi)     = median(selectR2, 'omitnan');      
        
    end
    
    
    hold(ax2, 'on'),
    % plot scatter subjs (low opacity, match ROI color)
    scatter(ax2, roi*ones(1,numSubjects), med_R2shape(:,roi), 'o', ...
        'MarkerFaceColor', cell2mat(roiColors(roi)) ,'MarkerEdgeColor',cell2mat(roiColors(roi)), ...
        'SizeData',indvDotsize*2, 'MarkerFaceAlpha',mrkr_alpha, 'MarkerEdgeAlpha',mrkr_alpha, 'HandleVisibility','off');

    % plot scatter ROI means (high opacity, with error bars, ROI color)
    scatter(ax2, roi, mean(med_R2shape(:,roi)),'o','filled','SizeData',(indvDotsize*6),'MarkerEdgeColor', 'k','MarkerFaceColor', cell2mat(roiColors(roi)));
    errorbar(ax2, roi, mean(med_R2shape(:,roi)), std(med_R2shape(:,roi))/sqrt(numSubjects),'k.','CapSize',0, 'lineWidth', errBarWidth, 'handlevisibility', 'off')

    if roi == 3
        %legend(ax1, ['V1';'V2';'V3'], 'Location', 'NorthWest', 'box', 'off', 'fontsize', 10)
        ylabel(ax2, 'R2','FontSize',10)
        set(ax2, 'XLim', [0 4], 'XTick', 1:3, 'XTickLabel', opts.ROInames)
    end

    
end

% visualize example voxel
hold(ax1, 'on'),
semilogx(ax1, xvalues*100, exmplCRFs(1,:)) 
semilogx(ax1, xvalues*100, exmplCRFs(2,:))
set(ax1, 'XScale', 'log', 'xtick', [10 100], 'XTickLabel', [10 100], 'TickDir', 'out')
minorTicks = [2:1:9 20:10:90];
ax1.XMinorTick = 'on';
ax1.XAxis.MinorTickValues = minorTicks;
ax1.TickLength = [0.02 0.05];
title(ax1, sprintf('example voxel: R2=%.2f', exmplR2))

if opts.savePlots > 0
    if ~exist(fullfile(opts.figureDir, 'Figure5'), 'dir'), mkdir(fullfile(opts.figureDir, 'Figure5')); end
    print(fig, fullfile(opts.figureDir, 'Figure5', sprintf('Fig5_CRFshapeComparison')), '-dpdf');
end

%-- out
out.modelbasedParams    = avg_pCRFparams;
out.deconvParams        = avg_deconvparams;
out.paramLabels         = paramLabels;



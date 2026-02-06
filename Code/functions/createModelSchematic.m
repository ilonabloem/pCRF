%% Figure 2 deconvolution vs model-based approach to estimate the CRF


%-- set up paths
[projectRoot, ...
    dataRoot]   = projectRootPath;
outDir          = fullfile(dataRoot, '..', 'modelResults');
figureDir       = fullfile(projectRoot, 'Figures');
if ~exist(fullfile(figureDir, 'modelSchematic'), 'dir'), mkdir(fullfile(figureDir, 'modelSchematic')), end

%-- initialize variables
opts.doPlots    = true;
opts.savePlots  = true;
opts.compute    = false;
opts            = initDefaults(opts);

exmplSubject    = find(ismember(opts.subjNames, '004'));
whichROI        = find(ismember(opts.ROInames, 'V1'));
taskNames       = "JN2022Event";

%-- setup CRF model
contrasts       = [2.7, 4, 5.3, 8, 16, 32, 48, 64, 96];
NRFunc          = @(a1, c) (a1(1)).*((c.^a1(2))./((c.^a1(2)) + (a1(3).^a1(2))) );
bounds          = @(x) cat(2, floor(min(x(:))-.5), ceil(max(x(:))+.5));

%-- load FIR time series 
loadName        = 'allFIR_fits_wAdapt_GROUP_CRF_09-Oct-2021.mat';
loadDir         = fullfile(dataRoot, 'JNeuro2022');

assert(exist(fullfile(loadDir, loadName), 'file') > 0, 'FIR time series file not found')
data            = load(fullfile(loadDir, loadName)); 
jneuroPrms      = data.ALL_estParams;

%-- load model based time series 
loadStr         = 'nocross';
loadName        = sprintf('sub-%s_task-%s_*_%sHRF_*', opts.subjNames{exmplSubject}, taskNames, opts.useHRF);
loadDir         = fullfile(outDir, loadStr);           
loadList        = dir(fullfile(loadDir, loadName));
assert(exist(fullfile(loadDir, loadList.name), 'file') > 0, 'model based time series file not found')

modelResults    = load(fullfile(loadDir, loadList.name));

%-- load model based crossval R2
loadStr         = 'cross';
loadName        = sprintf('sub-%s_task-%s_*_%sHRF_*', opts.subjNames{exmplSubject}, taskNames, opts.useHRF);
loadDir         = fullfile(outDir, loadStr);           
loadList        = dir(fullfile(loadDir, loadName));
assert(exist(fullfile(loadDir, loadList.name), 'file') > 0, 'model based crossval file not found')

crossResults    = load(fullfile(loadDir, loadList.name));

%-- find example voxel 
% voxIDs          = find(crossResults.out.crossR2(crossResults.roiIndx == whichROI) > ...
%                     prctile(crossResults.out.crossR2(crossResults.roiIndx == whichROI), 95));
voxIDs          = 201;

%% visualize
for exp = 1:numel(voxIDs)
    
    figHandle = figure('color', [1 1 1], 'pos', [10 300 700 850]);
    set(figHandle, ...
        'Units', 'Pixels', 'PaperPositionMode','Auto', ...
        'PaperUnits','points','PaperSize',[700 850]);
    condColors = parula(9);
    colororder(condColors)
    
    voxID           = voxIDs(exp);

    %-- FIR timeseries for each contrast
    FIRresp         = squeeze(data.FIR(exmplSubject,whichROI).allFIR(:,voxID,:));
    ylims           = bounds(FIRresp);
    CRFvox          = data.FIR(exmplSubject,whichROI).allCRF(:,voxID); 
    paramVox        = data.ALL_estParams(exmplSubject,whichROI).est_params_allVoxels(voxID,:);
    fitCRF          = NRFunc(paramVox, linspace(2,100,100));

    subplot(3,2,3)
    plot((0:23)-3 , FIRresp, 'LineWidth', 2)
    hold on, 
    % add stim onset and averaging window indicators
    plot([0 0], ylims, 'k-.', [3 3], ylims, 'k-', [9 9], ylims, 'k-')
    xlabel('Time (TR)'); ylabel('BOLD response')
    box off
    xlim([-3 20]); ylim(ylims); set(gca, 'TickDir', 'out', 'YTick', linspace(ylims(1), ylims(2), 7))
    title('Deconvolution approach', 'FontSize', 16)

    subplot(3,2,5)
    scatter(log10(contrasts), data.FIR(exmplSubject,whichROI).allCRF(:,voxID), 50, condColors, 'filled')
    hold on, 
    plot(log10(linspace(2,100,100)), fitCRF, 'r', 'LineWidth', 2)
    plot(log10([16 16]), [-2 ylims(end)], 'k:')
    xlabel('Contrast (%)'); ylabel('BOLD response')
    set(gca, 'xtick', log10(contrasts), 'XTickLabel', contrasts, 'XTickLabelRotation', 45)
    box off; axis square
    title(sprintf('%.2f R2 CRF fit', data.FIR(exmplSubject,whichROI).R2_allVoxels(voxID)))

    %-- model based timeseries with fit
    numRuns         = size(modelResults.input.I,1);
    runTRs          = size(modelResults.out.fulltSeries,2)/numRuns;
    tsIndx          = (25:225) + runTRs*(numRuns-2); % only show a section of the run 
    tsResp          = modelResults.out.fulltSeries(voxID, tsIndx);
    tsPred          = modelResults.out.fullprediction(voxID,tsIndx);
    ylims           = bounds(cat(2, tsResp, tsPred));
    modelParam      = modelResults.out.Params.All(voxID,[3 2 1]) .* [1 1 100];
    fitModel        = NRFunc(modelParam, linspace(2,100,100));

    subplot(3,2,1)
    plot(tsResp, 'k', 'LineWidth', 2)
    xlabel('Time (TR)'); ylabel('BOLD response')
    box off
    xlim([0 numel(tsIndx)]); ylim(ylims); set(gca, 'TickDir', 'out', 'YTick', linspace(ylims(1), ylims(2), 7))
    title('Measure time series', 'FontSize', 16)

    subplot(3,2,4)
    plot(tsResp, 'k', 'LineWidth', 2)
    hold on, 
    plot(tsPred, 'r', 'LineWidth', 2)
    xlabel('Time (TR)'); ylabel('BOLD response')
    box off
    title('Model-based approach', 'FontSize', 16)
    xlim([0 numel(tsIndx)]); ylim(ylims); set(gca, 'TickDir', 'out', 'YTick', linspace(ylims(1), ylims(2), 7))

    
    subplot(3,2,6)
    hold on, 
    plot(log10(linspace(2,100,100)), fitModel, 'r', 'LineWidth', 2)
    plot(log10([16 16]), [-2 ylims(end)], 'k:')
    xlabel('Contrast (%)'); ylabel('BOLD response')
    set(gca, 'xtick', log10(contrasts), 'XTickLabel', contrasts, 'XTickLabelRotation', 45)
    box off; axis square
    title(sprintf('%.2f crossR2 time series fit', crossResults.out.crossR2(voxID)))
    
    sgtitle(sprintf('sub %s - ROI %s - vox #%i', opts.subjNames{exmplSubject}, opts.ROInames{whichROI}, voxID))
    print(figHandle, fullfile(figureDir, 'Figure2', sprintf('Fig2_s%s_vox-%i_modelSchematic', opts.subjNames{exmplSubject}, voxID)), '-dpdf')

end
%% Script that produces the main figures:
% Model-based estimation of the population contrast response function in human visual cortex
% Louis N. Vinke, Sam Ling & Ilona M. Bloem

% set options
opts            = [];
opts.savePlots  = true;
opts.compute    = false;
opts.tasks      = [{'JN2022Event'} {'RapidEvent'}];
opts.useHRF     = 'fit';
opts            = initDefaults(opts);

% load modeling results
allResults      = loadModelResults(opts);

% Figure 2 - comparison deconvolution vs model-based
createModelSchematic

% Figure 3 - model schematic
visualizeNakaRushtonParameters(opts)

% Figure 4 - CRF parameter comparison between model-based and deconvolution approaches
fig_CompareModelParams(opts, allResults(1));

% Do group-level stats for modeling comparisons on same dataset, 
% provides ttests on avg parameters and fisher z correlations
doStats         = true;
if doStats > 0
    avgParams.modelbasedParams  = allResults(1).modelbasedParams;
    avgParams.deconvParams      = allResults(1).deconvParams;
    avgParams.paramLabels       = {'Rmax', 'Slope', 'C50'}; % order of avg params 
    fisherCorr                  = allResults(1).fisherCorr;
    computeStats_modelComparison(opts, avgParams, fisherCorr)
end

% Figure 5 - full CRF shapes are comparible between models
fig_shapeComparison(opts, allResults(1))

% Figure 6 - CRF parameters for continuous contrast presentation experimental design
doStats         = true;
fig_ContinuousResults(opts, allResults, doStats);

% Figure 7 - voxel-wise patterns, C50 increases as function of eccentricity
fig_voxelwisePatterns(opts, allResults, doStats)

% supplementary figure illustrating voxel selection thresholds
suppfig_voxelSelection(opts, allResults)

% supplementary figure illustrating HRF params
suppfig_avgHRFparams(opts, allResults)
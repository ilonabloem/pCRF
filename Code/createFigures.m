%% Script that produces the main figures:
% Model-based estimation of the population contrast response function in human visual cortex
% Louis N. Vinke, Sam Ling & Ilona M. Bloem

% set options
opts            = [];
opts.savePlots  = true;
opts.compute    = false;
opts.tasks      = [{'JN2022Event'} {'RapidEvent'}];
opts            = initDefaults(opts);

% load modeling results
allResults      = loadModelResults(opts);

% Figure 2 - comparison deconvolution vs model-based
createModelSchematic

% Figure 4 - CRF parameter comparison between model-based and deconvolution approaches
doStats         = true;
visualize_fig4(opts, allResults(1), doStats);

% Figure 5 - CRF parameters for continuous contrast presentation experimental design
doStats         = true;
visualize_fig5(opts, allResults(2), doStats);
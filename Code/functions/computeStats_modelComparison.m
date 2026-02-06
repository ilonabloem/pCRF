function computeStats_modelComparison(opts, avgParams, fisherCorr, crossR2)

if  ~exist('avgParams', 'var') || isempty(avgParams)
    error('Need to provide avgParams struct (output from visualize_fig4.m)')
end
if  ~exist('fisherCorr', 'var') || isempty(fisherCorr)
    error('Need to provide fisherCorr variable (output from loadModelResults.m)')
end
if  ~exist('opts', 'var') || isempty(opts)
    opts            = initDefaults(opts);
end
if  ~exist('opts.figureDir', 'var') || isempty(opts.figureDir)
    projectRoot     = projectRootPath;
    opts.figureDir  = fullfile(projectRoot, 'Figures');
end

%-- setup variables
paramLabels     = avgParams.paramLabels;
nRows           = numel(paramLabels) * numel(opts.ROInames);
whichTest       = strings(nRows, 1);
corr_pvals      = NaN(nRows, 1);
corr_df         = NaN(nRows, 1);
corr_tstat      = NaN(nRows, 1);
corr_mean       = NaN(nRows, 1); 
corr_CI         = NaN(nRows, 2);

param_pvals     = NaN(nRows, 1);
param_df        = NaN(nRows, 1);
param_tstat     = NaN(nRows, 1);


c = 0;
for param = 1:numel(paramLabels) % {rmax, slope, c50}
    for roi = 1:numel(opts.ROInames)
       
        c               = c +1;
        
        label           = sprintf('%s_%s', paramLabels{param}, opts.ROInames{roi});
        whichTest(c)    = label;

        %-- single ttest for fisher z corrected correlation between model vs deconv
        % if sig evidence for linear relationship between two models
        z               = fisherCorr(:,param,roi);
        [~,p,ci,stat]   = ttest(z, 0); % test against 0
        corr_pvals(c)   = p;
        corr_df(c,1)    = stat.df;
        corr_tstat(c,1) = stat.tstat;

        % transform to r for reporting
        corr_mean(c)    = tanh(mean(z)); 
        corr_CI(c,:)    = tanh(ci);    

        %-- also directly test whether median param estimates are the same
        [~,p,~,stat] = ttest(avgParams.modelbasedParams(:,param,roi), avgParams.deconvParams(:,param,roi));
        
        param_pvals(c)  = p;
        param_df(c)     = stat.df;
        param_tstat(c)  = stat.tstat;

    end
end

% results from voxel-wise fisher-z correlation
corr_modelVSdeconv = table(whichTest, corr_pvals, corr_df, corr_tstat, corr_mean, corr_CI(:,1), corr_CI(:,2), ...
                    'VariableNames', {'whichTest','fishz_p','fishz_df','fishz_tstat', 'mean_rho', 'lb_rho', 'ub_rho'});

fprintf('voxel-wise fisher-z correlation (deconv vs model-based)\n ')
disp(corr_modelVSdeconv)
if opts.savePlots > 0
    writetable(corr_modelVSdeconv, fullfile(opts.figureDir, 'stats', sprintf('%s_corr_modelVSdeconv.csv', 'JN2022Event')), ...
           'FileType', 'text', 'Delimiter', ',', ...
           'WriteRowNames', false);
end

% results from paired ttest on median param estimates 
param_modelVSdeconv = table(whichTest, param_pvals, param_df, param_tstat, ...
                        'VariableNames', {'whichTest', 'p', 'df', 'tstat'});
fprintf('paired t-test median param estimates (deconv vs model-based)\n')
disp(param_modelVSdeconv)
if opts.savePlots > 0
    writetable(param_modelVSdeconv, fullfile(opts.figureDir, 'stats', sprintf('%s_param_modelVSdeconv.csv', 'JN2022Event')), ...
           'FileType', 'text', 'Delimiter', ',', ...
           'WriteRowNames', false);
end

%-- Report crossval R2
[~,p,ci,stat]   = ttest(crossR2, 0);
df              = stat.df;
tstat           = stat.tstat;
meanR2          = mean(crossR2,1);
ROInames        = opts.ROInames;

crossvalR2      = table(ROInames(:), p(:), df(:), tstat(:), meanR2(:), ci(1,:)', ci(2,:)', ...
                    'VariableNames', {'ROI','p','df','tstat', 'mean', 'lb_mean', 'ub_mean'});

fprintf('ttest crossval R2 > 0 (model-based) \n ')
disp(crossvalR2)
if opts.savePlots > 0
    writetable(crossvalR2, fullfile(opts.figureDir, 'stats', sprintf('%s_crossValR2.csv', 'JN2022Event')), ...
           'FileType', 'text', 'Delimiter', ',', ...
           'WriteRowNames', false);
end
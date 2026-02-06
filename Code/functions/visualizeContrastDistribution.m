
%% set up paths
[projectRoot, dataRoot] = projectRootPath;
figureDir       = fullfile(projectRoot, 'Figures');
folder          = 'contrastDistribution';

%% define options
opts            = [];
opts.tasks      = {'RapidEvent'};
opts            = initDefaults(opts);
opts.dataDir    = dataRoot;
numSubjects     = numel(opts.subjNames);
subjNames       = opts.subjNames';

%% Continous event contrast distribution:
minCon          = 0.04;
maxCon          = 1;
adaptContrast   = 0.16;
Contrasts       = [0 linspace(minCon, maxCon,49)];
GaussianDist    = 0.8 * exp(-(linspace(minCon, maxCon, 49) - adaptContrast).^2/(2*(0.06^2)));
ContrastDist    = [0.02 GaussianDist + 0.02 * ones(size(GaussianDist))];
ContrastDist    = ContrastDist./sum(ContrastDist);

%% visualize 
figure('Color', [1 1 1], 'Position', [50 50 400 500])
plot(Contrasts, ContrastDist, 'k', 'LineWidth', 2)
box off;
ylabel('Probability'); xlabel('Contrast (%)')
set(gca, 'TickDir', 'out', 'XColor', 'k', 'YColor', 'k')

if ~exist(fullfile(figureDir, folder), 'dir') > 0, mkdir(fullfile(figureDir, folder)); end
print(gcf, fullfile(figureDir, folder, sprintf('task-%s_contrastDistribution', opts.tasks{1})), '-dpdf');

%% subject loop
meanContrast    = cell(numSubjects, 1);
medianContrast  = cell(numSubjects, 1);

for sub = 1:numSubjects
    
    subject         = opts.subjNames{sub};
    opts.subject    = subject;

    % Load design info
    fileName        = sprintf('S%s_ModelPrep_%sRuns.mat', subject, opts.tasks{1});
    modelInput      = load(fullfile(opts.dataDir, 'JNeuro2022', fileName));
    numRuns(sub)    = numel(modelInput.Design);

    % loop over runs
    for run = 1:numel(modelInput.Design)
        
        % Extract contrast levels:
        DM          = modelInput.Design(run);
        contrasts   = DM.conds;
        % completely random contrast order after initial fixation and adaptation period
        eventIndx   = 3:1:length(contrasts)-1; 
        
        subContrasts = cat(1, subContrasts, contrasts(eventIndx));

        meanContrast{sub}(run)  = mean(contrasts(eventIndx));
        medianContrast{sub}(run)= median(contrasts(eventIndx));

    end

end


subjMedians = cellfun(@mean, medianContrast);
subjMeans   = cellfun(@mean, meanContrast);

avgContrast = table(subjNames, subjMedians, subjMeans);
disp(avgContrast)


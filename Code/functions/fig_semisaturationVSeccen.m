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
paramLabels     = {'C50'};

%-- setup roi colors
roiColors   = {[0.3176    0.3961    0.6824]; %[0.2744    0.3735    0.9857];
               [0.1176    0.6745    0.8549]; %[0.0981    0.6774    0.8626];
               [0.3843    0.7490    0.4863]}; %[0.3291    0.8001    0.4884]};

roiColorMap = cell(1,numel(roiColors));
for roi = 1:numel(roiColors)

    % Build a vector of saturation values (e.g. from low to high)
    n           = 256;   

    % Combine into colormap 
    roiColorMap{roi} = [linspace(0, roiColors{roi}(1), n)', ...
                        linspace(0, roiColors{roi}(2), n)',...
                        linspace(0, roiColors{roi}(3), n)'];
end


% Scatter plots of parameter estimates
fig        = figure('color', [1 1 1], 'Position', [0 0 780 760]);
set(fig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[780 760])
figlayout   = tiledlayout(2,1);
eventlayout = tiledlayout(figlayout, 1, 3);
contlayout  = tiledlayout(figlayout, 1, 3);
numBins     = 40;
ptsC50      = linspace(0,1,numBins+1);
ptsEccen    = linspace(0,10,numBins+1);

for roi = 1:3

    % compute 2d histogram for each participant                    
    nEvent      = NaN(numBins, numBins, numSubjects);
    nCont       = NaN(numBins, numBins, numSubjects);
    
    for sub = 1:numSubjects
        
        % Reorder parameters to match 2 models
        [~, idx]    = ismember(paramLabels, allResults(1).paramLabels);
        
        eventParam = allResults(1).allParams{sub,roi}(:,idx);
        contParam   = allResults(2).allParams{sub,roi}(:,idx);
        eccen       = allResults(1).prfEcc{sub, roi};

        % jneuro eventrelated C50 vs eccen
        nEvent(:,:,sub)   = histcounts2(eventParam(:), eccen, ...
                                     ptsC50, ptsEccen, 'Normalization', 'probability'); 

        % continuous c50 vs eccen
        nCont(:,:,sub)  = histcounts2(contParam(:), eccen, ...
                                    ptsC50, ptsEccen, 'Normalization', 'probability'); 
 
    end
    
    % event-related c50
    eventlayout.Layout.Tile = 1;
    ax = nexttile(eventlayout);    
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
        title(eventlayout, 'Event-related dataset', 'FontSize', 14)
    end
    
    % continuous c50
    contlayout.Layout.Tile = 2;
    ax  = nexttile(contlayout);
    imagesc(ptsEccen, ptsC50, mean(nCont,3));
    set(gca, 'XLim', ptsEccen([1 end]), 'XTick', ptsEccen([1 21 41]), ...
        'YLim', ptsC50([1 end]), 'YTick', ptsC50([1 21 41])*100, ...
        'YDir', 'normal');
    colormap(ax, roiColorMap{roi})
    caxis(ax, [0 0.005]); box off
    axis square

    if roi == 1
        xlabel('Eccentricity', 'FontSize', 10)
        ylabel('C50 Model-based Estimates', 'FontSize', 10)
        title(contlayout, 'Continuous dataset', 'FontSize', 14)
    end

end



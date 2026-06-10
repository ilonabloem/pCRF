function fig_eccenVSnormSSE(opts, allResults)

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

%-- setup roi colors
roiColors   = opts.roiColors;
roiColorMap = makeROIColormap(roiColors);

% Scatter plots of parameter estimates
fig        = figure('color', [1 1 1], 'Position', [0 0 780 760]);
set(fig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[780 760])
figlayout   = tiledlayout(2,1);
eventlayout = tiledlayout(figlayout, 1, 3);
contlayout  = tiledlayout(figlayout, 1, 3);
numBins     = 40;
ptsEccen    = linspace(0,10,numBins+1);
ptsImpr     = linspace(0,30,numBins+1);

for roi = 1:3

    % compute 2d histogram for each participant                    
    nEvent      = NaN(numBins, numBins, numSubjects);
    nCont       = NaN(numBins, numBins, numSubjects);
    
    for sub = 1:numSubjects
        
        %-- compute how much better model explains data compared to null
        % improvement per voxel and null sample
        SSE_event               = allResults(1).SSE{sub,roi};          
        SSE_nullevent           = median(allResults(1).nullSSE{sub,roi},1)';
        SSE_cont                = allResults(2).SSE{sub,roi};          
        SSE_nullcont            = median(allResults(2).nullSSE{sub,roi},1)';

        % normalize improvement by null: (null - model) / null
        eventImprv             = ((SSE_nullevent - SSE_event) ./ SSE_nullevent) * 100;  
        contImprv              = ((SSE_nullcont - SSE_cont) ./ SSE_nullcont) * 100;
        
        
        eccen                   = allResults(1).prfEcc{sub,roi};

        % jneuro eventrelated C50 vs eccen
        nEvent(:,:,sub)   = histcounts2(eventImprv(:), eccen(:), ...
                                     ptsImpr, ptsEccen, 'Normalization', 'probability'); 

        % continuous c50 vs eccen
        nCont(:,:,sub)  = histcounts2(contImprv(:), eccen(:), ...
                                    ptsImpr, ptsEccen, 'Normalization', 'probability'); 
 
    end
    
    % event-related 
    eventlayout.Layout.Tile = 1;
    ax = nexttile(eventlayout);    
    imagesc(ptsEccen, ptsImpr, mean(nEvent,3));      
    set(gca, 'XLim', ptsEccen([1 end]), 'XTick', ptsEccen([1 21 41]), ...
        'YLim', ptsImpr([1 end]), 'YTick', ptsImpr([1 21 41])*100, ...
        'YDir', 'normal');
    colormap(ax, roiColorMap{roi})
    caxis(ax,[0 0.005])
    axis square; box off
    if roi == 1
        xlabel('Eccentricity', 'FontSize', 10)
        ylabel('normSSE', 'FontSize', 10)
        title(eventlayout, 'Event-related dataset', 'FontSize', 14)
    end
    
    % continuous 
    contlayout.Layout.Tile = 2;
    ax  = nexttile(contlayout);
    imagesc(ptsEccen, ptsImpr, mean(nCont,3));
    set(gca, 'XLim', ptsEccen([1 end]), 'XTick', ptsEccen([1 21 41]), ...
        'YLim', ptsImpr([1 end]), 'YTick', ptsImpr([1 21 41])*100, ...
        'YDir', 'normal');
    colormap(ax, roiColorMap{roi})
    caxis(ax, [0 0.005]); box off
    axis square

    if roi == 1
        xlabel('Eccentricity', 'FontSize', 10)
        ylabel('normSSE', 'FontSize', 10)
        title(contlayout, 'Continuous dataset', 'FontSize', 14)
    end

end



function out = makeROIColormap(roiColors)

out = cell(1,numel(roiColors));

for roi = 1:numel(roiColors)

    % Build a vector of saturation values (e.g. from low to high)
    n           = 256;   

    % Combine into colormap 
    out{roi}    = [linspace(0, roiColors{roi}(1), n)', ...
                        linspace(0, roiColors{roi}(2), n)',...
                        linspace(0, roiColors{roi}(3), n)'];
end
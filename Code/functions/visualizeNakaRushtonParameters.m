function visualizeNakaRushtonParameters(opts)

if ~exist('opts', 'var')
    opts    = [];
    %-- set up paths
    projectRootPath;
    %-- initialize variables
    opts            = initDefaults(opts);
end

C       = 10.^linspace(log10(2), log10(100), 100);
C50     = 10;
rMax    = 1;
n       = 2; 
NRFunc  = @(a, c) (a(1)).*((c.^a(2))./((c.^a(2)) + (a(3).^a(2))) );

figure('Color', [1 1 1], 'Position', [50 50 450 500])
set(gcf, 'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[450 500])

ax = nexttile;
% standard CRF
semilogx(C, NRFunc([rMax, n, C50], C), 'Color', [1 0 0], 'linewidth', 2);
hold all, 

%rmax change
semilogx(C, NRFunc([rMax-0.4, n, C50], C), '--', 'Color', [1 0.5 0.5], 'linewidth', 2)

%c50 change
semilogx(C, NRFunc([rMax, n, C50+30], C), '-.', 'Color', [0.8 0 0], 'linewidth', 2)

%slope change
semilogx(C, NRFunc([rMax, n+4, C50], C), ':', 'Color', [0.5 0 0], 'linewidth', 2)

box off
set(gca, 'xtick', [10 100], 'XTickLabel', [10 100], 'TickDir', 'out')
minorTicks = [2:1:9 20:10:90];
ax.XMinorTick = 'on';
ax.XAxis.MinorTickValues = minorTicks;
ax.TickLength = [0.02 0.05];
xlabel('Contrast')
ylabel('Response')

if ~exist(fullfile(opts.figureDir, 'Figure3'), 'dir'), mkdir(fullfile(opts.figureDir, 'Figure3')); end
print(gcf, fullfile(opts.figureDir, 'Figure3', sprintf('Fig3_CRF')), '-dpdf');




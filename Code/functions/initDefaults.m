function s = initDefaults(s)

% Sets default values for fields in struct 's'. Defaults are
% specified as key-value pairs in rows of the cell array 'defaults'. Fields
% already present in 's' are left as they are, also when their value 
% is empty. Fields that are mentioned in 'defaults' but not set in 's' are
% set to the values in 'defaults'.

if nargin < 1, s = []; end
if isempty(s), s = struct; end

defaults = { %Default settings for popCRF
            'projectRoot', projectRootPath;
            'figureDir', fullfile(projectRootPath, 'Figures');
            'compute', false;            % set to true or false - will redo preprocessing of the data
            'doCross', true;            % set to true or false - run without or without crossvalidation
            'doGrid', true;             % set to true or false - run without or without grid search for C50 seed
            'doPlots', false;            % set to true or false
            'savePlots', true;
            'createNull', false;        % set to true or false - create a shuffled contrast order to compute a noise floor
            'subjNames', {'001' '003' '004' '007' '013' '018' '019' '021'}; % cellarray
            'HRF', [];
            'tasks', {'JN2022Event', 'RapidEvent'};            % string to be added to filename for saved out data
            'ROInames', {'V1' 'V2' 'V3'};
            'Contrasts', logspace(log10(0.04), log10(1), 50);
            'numEccen', 5;
            'EccenBins', logspace(log10(0.6),log10(17/2), 5+1);
            'paramNames', {'C50' 'N' 'Rmax' 'B'};
            'C50seed', 0.5;
            'C50grid', linspace(0.01,0.81, 11);
            'Rmaxseed', 2;
            'nseed', 2.5;
            'offsetseed', -1;
            'conBounds', [0.04 1];
            'pRFeccBounds', [0.6 8.5];
            'pRFR2bound', 10;
            'pRFrfbound', 0.1;
            'initFix', 30;
            'finalFix', 16;
            'stimDur', 2;
            'TR', 1;
            'downSample_f', 1/0.5;
            'totalTR', 298;
            'BOLDlag', 5;
            'useHRF', 'spm';
            'numShuffle', 100;
            'num_cores', 1;
            };

for f_idx = 1:size(defaults,1)
    if ~isfield(s, defaults{f_idx, 1}) || isempty(s.(defaults{f_idx, 1}))
        s.(defaults{f_idx, 1}) = defaults{f_idx, 2};
    end    
end

end
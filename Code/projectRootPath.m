function [rootPath, dataRootPath] = projectRootPath(useCluster)
% Return the path to the root popCRF directory
%
% This function must reside in the code directory of the project
% directory structure.  It is used to determine the location of various
% sub-directories.
% Example:
%   projectRootPath(true)

if ~exist('useCluster', 'var') || isempty(useCluster)
    useCluster = false;
end

%-- Find the folder that contains this function
filePath    = fileparts(which('projectRootPath'));

%-- Add code directory to path
addpath(genpath(filePath));

%-- Save parent folder as rootPath
rootPath    = fileparts(filePath);

%-- setup data root path
switch useCluster
	
    case true
        
        dataRootPath     = fullfile('/projectnb', 'vision', 'popCRF', 'Data', 'modelBased');
        
    case false
        
        userName        = getenv('USER'); % find username. OSX: getenv('USER'), windows: getenv('USERNAME')
        
        switch userName
            
            case 'ibloem' % cluster home directory
                
                dataRootPath     = fullfile('~', 'Git', 'popCRF', 'Data');

            case 'ilonabloem' % local directory

                dataRootPath     = fullfile('~', 'Documents', 'popCRF', 'Data');

            case 'lnv2'
                
                dataRootPath    = fullfile('/Users','lnv2','Documents','BU','popCRF_data','Data');

            otherwise % for all other users data and code should both be in the rootPath 
                
                fprintf(['Assuming standard project layout:\n' ...
                            '  code directory: %s\n' ...
                            '  data directory: %s\n'], ...
                            fullfile(filePath), fullfile(rootPath, 'Data'));
                dataRootPath     = fullfile(rootPath, 'Data');
        
        
        end
end
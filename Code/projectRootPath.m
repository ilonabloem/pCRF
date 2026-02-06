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
userName        = getenv('USER'); % find username. OSX: getenv('USER'), windows: getenv('USERNAME')

switch userName
	
	case 'ibloem' % cluster home directory
		
		dataRootPath     = fullfile('~', 'Git', 'pCRF', 'Data');

	otherwise % for all other users data and code should both be in the rootPath 
		
		fprintf(['Assuming standard project layout:\n' ...
					'  code directory: %s\n' ...
					'  data directory: %s\n'], ...
					fullfile(filePath), fullfile(rootPath, 'Data'));
		dataRootPath     = fullfile(rootPath, 'Data');
end

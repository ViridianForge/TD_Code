function setupPath()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%SETUPPATH - ensures that all paths are set for the use of any scripts
%related to Victor and Jennifer's Longitudinal Study.
%
%Thanks PrintWorkingDirectory for letting me clean this up even more, and
%preventing Jennifer and Victor from having to alter code here.
%
%Author:  Wayne Manselle - February 2013
%October 2013 Change -- Adding lines to clean up Matlab work space for each
%script run.
%May 2014 Change -- Changing lines to reflect moving the code to the final
%arrangement and file structure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all
close all

%Make sure we have all the necessary libraries and functions on our path
%for the running of the processor.
addpath([pwd '\Libs\']);
addpath([pwd '\EMGLibs\']);
addpath([pwd '\KinLibs\']);
addpath([pwd '\GUILibs\']);

%Prepare the workspace.
clear all
close all
end


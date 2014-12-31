function [ fileList, levelText, topDir, curSubj ] = CollectKinematicFiles( fileLoc )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%COLLECTKINEMATICFILES Collects data files to process for a single subject.
%   This is a breakout function to isolate the logic of selecting a single
%   subject's folder and returning all the data files needed to process
%   their data.
%
%   Author:  Wayne Manselle -- March 2014
%
%   Change Log -- June 17 2014 -- Adding logic for function to be used to
%                                 mass process files.
%
%   INPUTS: fileLoc -- An optional provided directory location in which to
%                      search for kinematic files.
%
%   OUTPUTS:  fileList -- The full list of subject data files to be
%                         processed.
%             levelText -- The names of the levels detected for processing.
%             topDir -- The top level directory of the subject data.
%             curSubj -- The current subject identifier
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Lists of levels we are going to process
levels={'\Pelvic\','\Thoracic\'};

%Collection of files to send back to the main program.
%Row 1 -- Pelvic Level
%Row 2 -- Thoracic Level
%Possible Row 3 -- Axillae Level
%Column 1 -- OpenSHAPA Hand Output
%Column 2 -- OpenSHAPA Output
%Column 3 -- Raw Kinematic File
fileList=cell(length(levels),3);

%Set the level text values used in the main data processor here.
levelText = {};
curSubj = [];

%Collect base directory
if (nargin > 0)
    topDir = fileLoc;
else
    topDir = uigetdir('C:\','Select the Subject Directory you wish to process.');
end

if(topDir==0)
    disp('File selection cancelled.  Now Exiting...')
    return;
end

dirLocs = strfind(topDir, '\');
curDir = topDir(dirLocs(end):end);

disp('Determining Location of all Relevant Files for Subject.')
%Start collection information from the directories.
openSHAPADir = [topDir '\OpenSHAPA'];

%If Subject is in the CP group, add the Axiallae level
if(strfind(curDir,'CP'))
    levels = horzcat(levels,'\Axillae\');
end

%Check both levels for openSHAPA files
for level=1:length(levels)
    openSHAPAContents = dir([openSHAPADir levels{level} '\*.csv']);
    if(~isempty(openSHAPAContents))
        disp(['OpenSHAPA pertaining to ' levels{level} ' found.'])
        levelText = horzcat(levelText, levels(level));
        osHandFileList = dir([openSHAPADir levels{level} 'HandOutput*.csv']);
        oSOutputFile = dir([openSHAPADir levels{level} 'Output*.csv']);
        
        %Begin by testing to see if General Kinematic Format files are
        %available for the subject.
        kinFile = dir([topDir levels{level} 'KIN\*.gkf']);
        
        %If there are no GKF files available for the subject, fall back to
        %looking for Oklahoma-Formatted files.
        if(isempty(kinFile))
            kinFile = dir([topDir levels{level} 'KIN\*.txt']);
        end
        
        %Test to be sure data is actually there.
        if(~isempty(kinFile))
            disp(['Kinematic Data pertaining to ' levels{level} ' found.'])
            if(isempty(curSubj))
                curSubj = kinFile(1).name;
                curSubj = curSubj(end-9:end-6);
            end
            fileList{level,1} = [openSHAPADir levels{level} osHandFileList(1).name];
            fileList{level,2} = [openSHAPADir levels{level} oSOutputFile(1).name];
            %The kinFile(3) is necessary due to the wildcard catching the
            %subdirectories in addition to our file.
            fileList{level,3} = [topDir levels{level} 'KIN\' kinFile(1).name];
        else
            disp(['No Kinematic files pertaining to ' levels{level} ' were found.'])
        end
    else
        disp(['No OpenSHAPA files pertaining to ' levels{level} ' were found.'])
    end
end
%Clear out any row that's missing files?
fileList(all(cellfun('isempty',fileList),2),:)=[];
end
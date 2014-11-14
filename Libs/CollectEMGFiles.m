function [ fileList, levelText, topDir, curSubj ] = CollectEMGFiles( fileLoc )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%COLLECTKINEMATICFILES Collects data files to process for a single subject.
%   This is a breakout function to isolate the logic of selecting a single
%   subject's folder and returning all the data files needed to process
%   their data.
%
%   Author:  Wayne Manselle -- March 2014
%CHANGELOG -- 03.25.2014 -- Initial Creation, begin work from old
%                           ProcessSubjectData.m
%             07.01.2014 -- Addition of fileLoc variable to facilitate
%             multiple directory processing
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
%Row 3 -- Axillae Level -- If level present
%Column 1 -- OpenSHAPA Hand Output
%Column 2 -- OpenSHAPA Output
%Column 3 -- Left Reach Timing File
%Column 4 -- Right Reach Timing File
%Column 5 -- EMG File
%Column 6 -- Gains File
fileList=cell(length(levels),6);

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

disp('Determining Location of all Relevant Files for Subject.')
%Start collection information from the directories.
openSHAPADir = [topDir '\OpenSHAPA'];

%If Subject is in the CP group, add the Axiallae level
if(strfind(topDir,'CP'))
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
        lReachFileList = dir([topDir '\Output\Kinematics\' levels{level} 'Left_Reach_corrReachOnsetsMS.csv']);
        rReachFileList = dir([topDir '\Output\Kinematics\' levels{level} 'Right_Reach_corrReachOnsetsMS.csv']);
        emgFile = dir([topDir levels{level} 'EMG\*_*.csv']);
        gainFile = dir([topDir levels{level} 'EMG\Gains.csv']);
        %Test to be sure data is actually there.
        if(~isempty(emgFile) && ~isempty(gainFile))
            disp(['EMG Data pertaining to ' levels{level} ' found.'])
            if(isempty(curSubj))
                curSubj = emgFile(1).name;
                curSubj = curSubj(end-9:end-6);
            end
            fileList{level,1} = [openSHAPADir levels{level} osHandFileList(1).name];
            fileList{level,2} = [openSHAPADir levels{level} oSOutputFile(1).name];
            if(~isempty(lReachFileList))
                fileList{level,3} = [topDir '\Output\Kinematics\' levels{level} lReachFileList(1).name];
            end
            if(~isempty(rReachFileList))
                fileList{level,4} = [topDir '\Output\Kinematics\' levels{level} rReachFileList(1).name];
            end
            fileList{level,5} = [topDir levels{level} 'EMG\' emgFile(1).name];
            fileList{level,6} = [topDir levels{level} 'EMG\' gainFile(1).name];
        else
            if(isEmpty(emgFile))
                disp(['No EMG files pertaining to ' levels{level} ' were found.'])
            end
            if(isEmpty(gainFile))
                disp(['No Gains files pertaining to ' levels{level} ' were found.'])
            end
        end
    else
        disp(['No OpenSHAPA files pertaining to ' levels{level} ' were found.'])
    end
end
%Clear out any row that's missing files?
fileList(all(cellfun('isempty',fileList),2),:)=[];
end
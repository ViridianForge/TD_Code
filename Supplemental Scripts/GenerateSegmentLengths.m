%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%GENERATESEGMENTLENGTHS.M
%
%This Script examines the Mark data present for subjects that have had
%their kinematic data processed and generates a CSV file containing
%requested segment lengths based on that data in an X,Y,Z vector format.
%
%The Segments Currently Generate by this Script are:
%   Length of Left Arm
%   Length of Right Arm
%   Head Length (measured from C7 to top of head)
%   Length of Mobile Trunk Segment
%
%Author -- Wayne Manselle
%Date -- December 2014
%CHANGELOG -- 12.16.2014 -- Initial Creation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Step 0 -- Set up paths and variables
setupPath();

%Seed the Output Storage line with the headers
outputStorage = {'SubjectID','SupportLevel','RightArmLength',...
    'LeftArmLength','HeadLength','MobileTrunkLength'};

%Select all folders of subject data to process kinematic stats for --
%returns 0 on a cancelled selection
foldersToProcess = uipickfiles();

%Step 1 -- Begin iterating over all selected subjects

%Process those subjects
if(iscell(foldersToProcess))
    
    for procFolder=1:size(foldersToProcess,2)
        %Step 2 -- Check to determine which levels exist
        [fileList, levelText, topDir, curSubj] = CollectKinematicFiles(foldersToProcess{procFolder});
        
        %Step 3 -- Iterate over all levels available for subject
        for level=1:size(levelText,2)
            %Step 4 -- Check to see if Mark file exists for level
            %Do Oklahoma logic
            [kinTrialData, rotTrialData, markData, rpiData, bosData,...
                maxHdHt, maxTkHt, rpi_TrunkData, fDataLineOverTime] = ...
                procOklahomaFile(fileList{level,3});
            
            %Step 5 -- Convert the mark data's units from inches to meters.
            markData(:,1:12) = markData(:,1:12).*(2.54/100);
            
            %Step 6 -- Generate new line of data to work with
            newOutputLine = cell(1,size(outputStorage,2));
            newOutputLine(1) = {curSubj};
            newOutputLine(2) = levelText(level);
            
            %Step 7 -- Compare Relevant Mark Data to generate the vector lengths
            %Right Arm -- Euclidian Distance of Mark 1(Sensor 4 - Sensor 3)
            newOutputLine(3) = {sqrt((markData(1,10)-markData(1,7))^2 + (markData(1,11)-markData(1,8))^2 + (markData(1,12)-markData(1,9))^2)};
            %Left Arm  -- Euclidian Distance of Mark 2(sensor 4 - Sensor 3)
            newOutputLine(4) = {sqrt((markData(2,10)-markData(2,7))^2 + (markData(2,11)-markData(2,8))^2 + (markData(2,12)-markData(2,9))^2)};
            %Head -- Euclidian Distance of Mark 4(Sensor 4 - Sensor 2)
            newOutputLine(5) = {sqrt((markData(4,10)-markData(4,4))^2 + (markData(4,11)-markData(4,5))^2 + (markData(4,12)-markData(4,6))^2)};
            %Mobile Trunk -- Euclidian Distance of Mark 6(Sensor 2 - Sensor 3)
            newOutputLine(6) = {sqrt((markData(6,4)-markData(6,7))^2 + (markData(6,5)-markData(6,8))^2 + (markData(6,6)-markData(6,9))^2)};
            
            %Step 8 -- Append the new level data to the output matrix
            outputStorage = vertcat(outputStorage, newOutputLine);     
        end
    end
end

%Step 9 -- Save out final database
[outfile, outpath] = uiputfile('*.csv','Select where to save Output.');
cell2csv([outpath outfile],outputStorage);
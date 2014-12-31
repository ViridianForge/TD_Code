%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CONVERTADULTKINAMETICS.M
%
%This script is intended to examine the prime mover kinematics and open
%SHAPA from the adult study data, and convert it for kinematic processing
%by the TD/CP era code.
%
%Ideally this script should also rename any adult files needing renaming,
%reorganize them correctly, and prepare the whole package for insertion
%into the TD/CP data processing line.
%
%Author -- Wayne Manselle
%Date -- October 2014
%Changelog -- 10.07.2014 -- Initial Creation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%Stage 0 -- Library and Constant Setup%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%See setupPath.m to ensure all paths are correctly set.
setupPath();

%Select all folders of subject data to process kinematic stats for --
%returns 0 on a cancelled selection
foldersToProcess = uipickfiles();

%Choose a top level directory to create the new data structures in.
newRoot = uigetdir('C:\','Choose the Root Directory for Converted Adult Data.');

%Mark Headers
markHeader={'M1_X','M1_Y','M1_Z','M2_X','M2_Y','M2_Z','M3_X','M3_Y',...
    'M3_Z','M4_X','M4_Y','M4_Z','M1_R1C1','M1_R1C2','M1_R1C3','M1_R2C1',...
    'M1_R2C2','M1_R2C3','M1_R3C1','M1_R3C2','M1_R3C3','M2_R1C1','M2_R1C2',...
    'M2_R1C3','M2_R2C1','M2_R2C2','M2_R2C3','M2_R3C1','M2_R3C2','M2_R3C3',...
    'M3_R1C1','M3_R1C2','M3_R1C3','M3_R2C1','M3_R2C2','M3_R2C3','M3_R3C1',...
    'M3_R3C2','M3_R3C3','M4_R1C1','M4_R1C2','M4_R1C3','M4_R2C1','M4_R2C2',...
    'M4_R2C3','M4_R3C1','M4_R3C2','M4_R3C3'};

%BOS Row and Column Headers
bosRHeader={'MLComp';'APComp';'CBOS';'SternCent'};
bosCHeader={'','LeftX','LeftY','LeftZ','RightX','RightY','RightZ','CenterX','CenterY','CenterZ'};

%Headers for the corrected time outputs, both MS and DP
corrTimeHeader = {'KinTrialNum','PreEventOn','EventOn','EventOff','EventNum'};

%Iterate over the subjects picked
if(iscell(foldersToProcess))
    for procFolder=1:size(foldersToProcess,2)
        
        %Stage 0 -- Create new structure to place results of conversion
        %into.
        [fileList, levelText, topDir, curSubj] = ...
            CollectKinematicFiles(foldersToProcess{procFolder});
        
        if(~exist([newRoot '\' curSubj],'dir'))
            mkdir([newRoot '\' curSubj])
        end
        
        newSubjRoot = [newRoot '\' curSubj];
        
        %Begin by copying over the raw data files that will be necessary
        %to work from.
        copyfile([foldersToProcess{procFolder} '\OpenSHAPA'],[newSubjRoot '\OpenSHAPA']);
        copyfile([foldersToProcess{procFolder} '\Pelvic'],[newSubjRoot '\Pelvic'])
        copyfile([foldersToProcess{procFolder} '\Thoracic'],[newSubjRoot '\Thoracic'])
        
        %Populate new subject root with new folder structures.
        buildOutputDirectories(newSubjRoot, levelText);
        
        %Calculate BOS, Mark, and Max Height Data, save to new locations.
        
        %Pelvic Level
        [pKinTrialData,pRotTrialData, pMarkData,pRpiData,pBosData, pMaxHdHt,...
            pMaxTkHt] = FranEraBirdConverter(fileList{1,3});
        
        %Save the mark data and the relative rotation matrices for Victor's
        %use.
        pMarkDataOutput = cat(1,markHeader,num2cell(pMarkData));
        cell2csv([newSubjRoot '\Output\Kinematics\Pelvic\MarkData.csv'], pMarkDataOutput);
        
        %Save the Base of Support data for later use.
        %Add column and row headers for BOS
        pBosOut = horzcat(bosRHeader,num2cell(pBosData));
        pBosOut = vertcat(bosCHeader,pBosOut);
        cell2csv([newSubjRoot '\Output\Kinematics\Pelvic\BOSData.csv'],pBosOut);
        
        %Save the Max Hd and C7 heights for later use.
        %Add column headers to Max Heights
        pMaxHtOut = vertcat({'MaxHdHt','MaxTkHt'},{pMaxHdHt,pMaxTkHt});
        cell2csv([newSubjRoot '\Output\Kinematics\Pelvic\MaxHeights.csv'],pMaxHtOut);   
        
        %Thoracic Level
        [tKinTrialData,tRotTrialData, tMarkData,tRpiData,tBosData, tMaxHdHt,...
            tMaxTkHt] = FranEraBirdConverter(fileList{1,3});
                %Save the mark data and the relative rotation matrices for Victor's
        %use.
        tMarkDataOutput = cat(1,markHeader,num2cell(tMarkData));
        cell2csv([newSubjRoot '\Output\Kinematics\Thoracic\MarkData.csv'], tMarkDataOutput);
        
        %Save the Base of Support data for later use.
        %Add column and row headers for BOS
        tBosOut = horzcat(bosRHeader,num2cell(tBosData));
        tBosOut = vertcat(bosCHeader,tBosOut);
        cell2csv([newSubjRoot '\Output\Kinematics\Thoracic\BOSData.csv'],tBosOut);
        
        %Save the Max Hd and C7 heights for later use.
        %Add column headers to Max Heights
        tMaxHtOut = vertcat({'MaxHdHt','MaxTkHt'},{tMaxHdHt,tMaxTkHt});
        cell2csv([newSubjRoot '\Output\Kinematics\Thoracic\MaxHeights.csv'],tMaxHtOut);   
        
        %Full Kinematic Trials, easy enough
        copyfile([foldersToProcess{procFolder} '\Output\KinTrials\Pelvic'],[newSubjRoot '\Output\Kinematics\Pelvic\FullTrials']);
        copyfile([foldersToProcess{procFolder} '\Output\KinTrials\Thoracic'],[newSubjRoot '\Output\Kinematics\Thoracic\FullTrials']);
        
        %We can copy the reach related PM file over, but we'll need to
        %rename them once we know a little bit more about the reaches.
        copyfile([foldersToProcess{procFolder} '\Output\ReachData\Pelvic\PMKinOutput\*.csv'],[newSubjRoot '\Output\Kinematics\Pelvic\ReachTrials\']);
        copyfile([foldersToProcess{procFolder} '\Output\ReachData\Thoracic\PMKinOutput\*.csv'],[newSubjRoot '\Output\Kinematics\Thoracic\ReachTrials\']);
        
        %Stage 1 -- Build the table of times needed to retarget the data
        %Targets to load
        
        pmKinData = readtext2([foldersToProcess{procFolder} '\PrimeMoverIndexedKinematicOutput.csv'],',','','');
        
        %Isolate the indices of each level's reaches.  Adults only have
        %pelvic and thoracic levels of support, so this code is sufficient.
        pelvicRows = find(strcmp(pmKinData(:,2),'Pelvic\'));
        thoracicRows = find(strcmp(pmKinData(:,2),'Thoracic\'));
        
        %Using those indices, grab the reach trials listed for each
        %movement time.  We need to isolate just their reaching numbers for
        %later logical indexing.
        pelvicReachTrials = pmKinData(pelvicRows,3);
        thoracicReachTrials = pmKinData(thoracicRows,3);
        
        pelvicReachNums = zeros(size(pelvicReachTrials));
        thoracicReachNums = zeros(size(thoracicReachTrials));
        
        %This test will check the handedness of the dominant reaching hand
        %for the subject.
        handedness=0;
        if(strfind(pelvicReachTrials{1},'Left'))
            handedness=1;
        else
            handedness=2;
        end
        
        %These loops are used to grab the last two characters from the
        %strings representing the reaching trials and replace them with
        %their numeric equiavelents.  These will be used later on to match
        %movement times up with the end of trial data from openSHAPA.
        for reach=1:size(pelvicReachTrials,1)
            curTrial = pelvicReachTrials{reach};
            pelvicReachNums(reach) = str2num(curTrial(end-1:end));
        end
        
        for reach=1:size(thoracicReachTrials,1)
            curTrial = thoracicReachTrials{reach};
            thoracicReachNums(reach) = str2num(curTrial(end-1:end));
        end
        
        pelvicMoveTimes = cell2mat(pmKinData(pelvicRows,4));
        thoracicMoveTimes = cell2mat(pmKinData(thoracicRows,4));
        
        %Get OpenSHAPA Data
        openSHAPAFile = [foldersToProcess{procFolder} '\OpenShapa\'];
        
        pelvicReachData = fileList{1,1};
        pelvicTrialData = fileList{1,2};
        
        thoracicReachData = fileList{2,1};
        thoracicTrialData = fileList{2,2};
        
        [pRReachData,pLReachData] = ...
            InterpretOSHAPA(pelvicReachData, pelvicTrialData, curSubj);
        
        [tRReachData,tLReachData] = ...
            InterpretOSHAPA(thoracicReachData, thoracicTrialData, curSubj);
        
        %Now construct our new time tables, using the movement times, the
        %reach offsets, and the reach trial numbers.
        
        if(handedness==1)
            [x vPLIndexes] = ismember(pelvicReachNums,cell2mat(pLReachData(:,1)));
            [x vTLIndexes] = ismember(thoracicReachNums,cell2mat(tLReachData(:,1)));
            vPLReaches = pLReachData(vPLIndexes,:);
            vTLReaches = tLReachData(vTLIndexes,:);
            pLOffsets = cell2mat(vPLReaches(:,3));
            tLOffsets = cell2mat(vTLReaches(:,3));
            pLCodes = vPLReaches(:,5);
            tLCodes = vTLReaches(:,5);
            pelvicReachesNewTable = horzcat(pelvicReachNums, floor(pLOffsets-(pelvicMoveTimes*1000)), pLOffsets);
            thoracicReachesNewTable = horzcat(thoracicReachNums, floor(tLOffsets-(thoracicMoveTimes*1000)), tLOffsets);
            timeOutName = 'Left_Reach_corrReachOnsets';
            folderTarget = 'Left_Reach\';
            %OpenSHAPA for later verifications
            pelvicOS = pLReachData;
            thoracicOS = tLReachData;
            %Rename all the Kinematic Files
            for reach=1:size(pelvicReachesNewTable,1)
                %Rename the Corresponding Files to:
                %kinTrial_reachnum_eventcode_reachnum
                if(~isnan(pelvicReachesNewTable(reach,2)))
                    newFileName = ['kinTrial_' num2str(pelvicReachesNewTable(reach,1)) '_' pLCodes{reach} '_' num2str(pelvicReachesNewTable(reach,1)) '.csv'];
                    %Convert the trial number into a 2 digit version, if
                    %necessary.
                    if(pelvicReachesNewTable(reach,1) < 10)
                        trialNum = ['0' num2str(pelvicReachesNewTable(reach,1))];
                    else
                        trialNum = num2str(pelvicReachesNewTable(reach,1));
                    end
                    oldFileName = ['PMKinReach_' trialNum '.csv'];
                    movefile([newSubjRoot '\Output\Kinematics\Pelvic\ReachTrials\' oldFileName], [newSubjRoot '\Output\Kinematics\Pelvic\ReachTrials\' folderTarget newFileName]);
                end
            end
            
            for reach=1:size(thoracicReachesNewTable,1)
                %Rename the Corresponding Files to:
                %kinTrial_reachnum_eventcode_reachnum
                if(~isnan(thoracicReachesNewTable(reach,2)))
                    newFileName = ['kinTrial_' num2str(thoracicReachesNewTable(reach,1)) '_' tLCodes{reach} '_' num2str(thoracicReachesNewTable(reach,1)) '.csv'];
                    %Convert the trial number into a 2 digit version, if
                    %necessary.
                    if(thoracicReachesNewTable(reach,1) < 10)
                        trialNum = ['0' num2str(thoracicReachesNewTable(reach,1))];
                    else
                        trialNum = num2str(thoracicReachesNewTable(reach,1));
                    end
                    oldFileName = ['PMKinReach_' trialNum '.csv'];
                    movefile([newSubjRoot '\Output\Kinematics\Thoracic\ReachTrials\' oldFileName], [newSubjRoot '\Output\Kinematics\Thoracic\ReachTrials\' folderTarget newFileName]);
                end
            end
        else
            [x vPRIndexes] = ismember(pelvicReachNums,cell2mat(pRReachData(:,1)));
            [x vTRIndexes] = ismember(thoracicReachNums,cell2mat(tRReachData(:,1)));
            vPRReaches = pRReachData(vPRIndexes,:);
            vTRReaches = tRReachData(vTRIndexes,:);
            pROffsets = cell2mat(vPRReaches(:,3));
            tROffsets = cell2mat(vTRReaches(:,3));
            pRCodes = vPRReaches(:,5);
            tRCodes = vTRReaches(:,5);
            pelvicReachesNewTable = horzcat(pelvicReachNums, floor(pROffsets-(pelvicMoveTimes*1000)), pROffsets);
            thoracicReachesNewTable = horzcat(thoracicReachNums, floor(tROffsets-(thoracicMoveTimes*1000)), tROffsets);
            timeOutName = 'Right_Reach_corrReachOnsets';
            folderTarget = 'Right_Reach\';
            %OpenSHAPA for later verifications
            pelvicOS = pRReachData;
            thoracicOS = tRReachData;
            %Rename all the Kinematic Files
            for reach=1:size(pelvicReachesNewTable,1)
                %Rename the Corresponding Files to:
                %kinTrial_reachnum_eventcode_reachnum
                if(~isnan(pelvicReachesNewTable(reach,2)))
                    newFileName = ['kinTrial_' num2str(pelvicReachesNewTable(reach,1)) '_' pRCodes{reach} '_' num2str(pelvicReachesNewTable(reach,1)) '.csv'];
                    %Convert the trial number into a 2 digit version, if
                    %necessary.
                    if(pelvicReachesNewTable(reach,1) < 10)
                        trialNum = ['0' num2str(pelvicReachesNewTable(reach,1))];
                    else
                        trialNum = num2str(pelvicReachesNewTable(reach,1));
                    end
                    oldFileName = ['PMKinReach_' trialNum '.csv'];
                    movefile([newSubjRoot '\Output\Kinematics\Pelvic\ReachTrials\' oldFileName], [newSubjRoot '\Output\Kinematics\Pelvic\ReachTrials\' folderTarget newFileName]);
                end
            end
            
            for reach=1:size(thoracicReachesNewTable,1)
                %Rename the Corresponding Files to:
                %kinTrial_reachnum_eventcode_reachnum               
                if(~isnan(thoracicReachesNewTable(reach,2)))
                    newFileName = ['kinTrial_' num2str(thoracicReachesNewTable(reach,1)) '_' tRCodes{reach} '_' num2str(thoracicReachesNewTable(reach,1)) '.csv'];
                    %Convert the trial number into a 2 digit version, if
                    %necessary.
                    if(thoracicReachesNewTable(reach,1) < 10)
                        trialNum = ['0' num2str(thoracicReachesNewTable(reach,1))];
                    else
                        trialNum = num2str(thoracicReachesNewTable(reach,1));
                    end
                    oldFileName = ['PMKinReach_' trialNum '.csv'];
                    movefile([newSubjRoot '\Output\Kinematics\Thoracic\ReachTrials\' oldFileName], [newSubjRoot '\Output\Kinematics\Thoracic\ReachTrials\' folderTarget newFileName]);
                end
            end
        end
        
        %Build target time files
        %Pelvic Level
        pCorrTimeFileDP = zeros(size(pelvicOS,1),5);
        pCorrTimeFileMS = zeros(size(pelvicOS,1),5);
        for reach=1:size(pelvicReachesNewTable,1)
            if(~isnan(pelvicReachesNewTable(reach,2)))
                placement = pelvicReachesNewTable(reach,1);
                %Time in Data Points
                pCorrTimeFileDP(placement,1) =  pelvicReachesNewTable(reach,1);
                pCorrTimeFileDP(placement,2) =  round((pelvicReachesNewTable(reach,2)/1000)*84);
                pCorrTimeFileDP(placement,3) =  round((pelvicReachesNewTable(reach,2)/1000)*84);
                pCorrTimeFileDP(placement,4) =  round((pelvicReachesNewTable(reach,3)/1000)*84);
                pCorrTimeFileDP(placement,5) =  pelvicReachesNewTable(reach,1);
                %Time in Milliseconds
                pCorrTimeFileMS(placement,1) =  pelvicReachesNewTable(reach,1);
                pCorrTimeFileMS(placement,2) =  pelvicReachesNewTable(reach,2);
                pCorrTimeFileMS(placement,3) =  pelvicReachesNewTable(reach,2);
                pCorrTimeFileMS(placement,4) =  pelvicReachesNewTable(reach,3);
                pCorrTimeFileMS(placement,5) =  pelvicReachesNewTable(reach,1);
            end
        end
        
        %Thoracic Level
        tCorrTimeFileDP = zeros(size(thoracicOS,1),5);
        tCorrTimeFileMS = zeros(size(thoracicOS,1),5);
        for reach=1:size(thoracicReachesNewTable,1)
            if(~isnan(thoracicReachesNewTable(reach,2)))
                placement = thoracicReachesNewTable(reach,1);
                %Time in Data Points
                tCorrTimeFileDP(placement,1) =  thoracicReachesNewTable(reach,1);
                tCorrTimeFileDP(placement,2) =  round((thoracicReachesNewTable(reach,2)/1000)*84);
                tCorrTimeFileDP(placement,3) =  round((thoracicReachesNewTable(reach,2)/1000)*84);
                tCorrTimeFileDP(placement,4) =  round((thoracicReachesNewTable(reach,3)/1000)*84);
                tCorrTimeFileDP(placement,5) =  thoracicReachesNewTable(reach,1);
                %Time in Milliseconds
                tCorrTimeFileMS(placement,1) =  thoracicReachesNewTable(reach,1);
                tCorrTimeFileMS(placement,2) =  thoracicReachesNewTable(reach,2);
                tCorrTimeFileMS(placement,3) =  thoracicReachesNewTable(reach,2);
                tCorrTimeFileMS(placement,4) =  thoracicReachesNewTable(reach,3);
                tCorrTimeFileMS(placement,5) =  thoracicReachesNewTable(reach,1);
            end
        end
        
        pCorrTimeFileDP = vertcat(corrTimeHeader, num2cell(pCorrTimeFileDP));
        tCorrTimeFileDP = vertcat(corrTimeHeader, num2cell(tCorrTimeFileDP));
        pCorrTimeFileMS = vertcat(corrTimeHeader, num2cell(pCorrTimeFileMS));
        tCorrTimeFileMS = vertcat(corrTimeHeader, num2cell(tCorrTimeFileMS));
        
        cell2csv([newSubjRoot '\Output\Kinematics\Pelvic\' timeOutName 'DP.csv' ],pCorrTimeFileDP)
        cell2csv([newSubjRoot '\Output\Kinematics\Thoracic\' timeOutName 'DP.csv' ],tCorrTimeFileDP)
        cell2csv([newSubjRoot '\Output\Kinematics\Pelvic\' timeOutName 'MS.csv' ],pCorrTimeFileMS)
        cell2csv([newSubjRoot '\Output\Kinematics\Thoracic\' timeOutName 'MS.csv' ],tCorrTimeFileMS)
    end
end
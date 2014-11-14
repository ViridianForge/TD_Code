%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CLEANKINEMATICDATA.M
%
%Script to handle the cleaning and correction of onset times in Victor
%and Jennifer's Kinematic Data set.
%
%
%Author -- Wayne Manselle
%Date -- April 2014
%CHANGELOG -- 04.09.2014 -- Initial Creation, begin work from non-split
%                           ProcessSubjectData.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%Stage 0 -- Library and Constant Setup%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%See setupPath.m to ensure all paths are correctly set.
setupPath()

%Get the list of all subject files that need processing.
[fileList, levelText, topDir, curSubj] = CollectKinematicFiles();

%Error safety check.  If the user presses cancel or something.
if(topDir==0)
    disp('No files found for subject.  Please review their data directory.')
    return
end

%Study group specific setup variables.  Based on the subject string given,
%method will return the preEvent time to examine, and EMG channels to
%examine for the group that subject belongs to.
[preEventLength, emgHeaders, keyMuscChans, mergeMuscChans, mergeBack,...
    aChans, muscGroupings, kinSampRate] = groupSpecificSetup(curSubj);


%Begin setting up constants for file output.  Headers and whatnot.
buildOutputDirectories(topDir, levelText);

%Set all the Output paths.
outpath = [topDir '\Output\Kinematics\'];

%Current Kinematic Column headers.
kinHeader = {'Trial','hdX','hdY','hdZ','hdCOMX','hdCOMY','hdCOMZ','c7X',...
    'c7Y','c7Z','tkCOMX','tkCOMY','tkCOMZ','lhX','lhY','lhZ',...
    'rhX','rhY','rhZ','Notes'};

%MarkData Output, rows: right arm, left arm, traegus, head_top
%Columns: headxyz,c7xyz,leftxyz,rightxyz,M1_m1,M1_m2,M1_m3
%M2_m1,M2_m2,M2_m3,M3_m1,M3_m2,M3_m3,M4_m1,M4_m2,M4_m3
%Rows: Mark 1, Mark 2, Mark 3, Mark 4, Mark 7
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

setMsg = {'Right_Reach','Left_Reach','Right_Grasp_Data','Left_Grasp_Data'};
handTypes = {'Right','Left','Right','Left'};
eventTypes = {'Reach','Reach','Grasp','Grasp'};

%%%%End Stage 0%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%Stage 1 -- Select Subject Data%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Do all processing for each level of the data.
for level=1:length(levelText)
    
	%1 -- Check output dir for level.  If the level has output, ask the
    %user if they wish to rerun the level.
    if(exist([outpath levelText{level} 'BOSData.csv'],'file') && ...
            exist([outpath levelText{level} 'MarkData.csv'],'file') && ...
            exist([outpath levelText{level} 'MaxHeights.csv'],'file'))
        procLevel = questdlg(['The ' levelText{level} ' level has been run before.  Would you like to process it again?'],...
            'Reprocess Level?','Yes','No','Yes');
        if(strcmp(procLevel,'No'))
            continue
        end
    else
        uiwait(warndlg(['Press OK to process ' levelText{level} ' level data for this subject.'],'Begin Processing.','modal'))
        close(gcf)
    end
    
    if(~isempty(fileList{level,1}))
        %%%%Stage 2 -- Process OpenSHAPA Data%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        disp('Beginning OpenSHAPA Processing...')
        %Manually get the file names for testing.
        reachData = fileList{level,1};
        trialData = fileList{level,2};
        %Matrices from the InterpretOSHAPA function have five columns.
        %Column 1 -- Event Number
        %Column 2 -- Start of Event referenced to trial Start time in ms.
        %Column 3 -- End of Event referenced to trial Start time in ms.
        %Column 4 -- Trial Number
        %Column 5 -- Event Code
        %
        %The four tables are right handed reach events, left handed reach events,
        %right handed grasp events, and left handed grasp events respectively.
        disp('Interpreting the OpenSHAPA data...')
        [rReachData,lReachData] = ...
            InterpretOSHAPA(reachData, trialData, curSubj);
        
        %Scan across openSHAPA data sets, note the trials that have reach
        %data in them.
        usedTrials = [cell2mat(rReachData(:,4)') cell2mat(lReachData(:,4)')];
        
        cSetData = {rReachData, lReachData};
        
        %%%%End Stage 2%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%Stage 3 -- Process Kinematic Data%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        disp('Beginning Conversion of Kinematic Data...')
        kinRawData = fileList{level,3};
        %Pull out the separated trial data and other relevant data from the Kin
        %Data.
        
        %The Matrices here are:
        %Mat 1 -- An arrangement of cells, each cell containing a given trial's
        %kinematic data.
        %Mat 2 -- Mark Data
        %Mat 3 -- rpi Data
        %Mat 4 -- Base of Support Data
        
        [kinTrialData,rotTrialData, markData,rpiData,bosData, maxHdHt,...
            maxTkHt] = FranEraBirdConverter(kinRawData);
              
        %Review kinematic data for approval
        procLevel = questdlg(['Would you like to review the Kinematic data for the ' levelText{level} ' level?'],...
            'Review Kinematics?','Yes','No','Yes');
        if(strcmp(procLevel,'Yes'))
            acceptableKinTrials = kinReviewTrials(kinTrialData,bosData);
        else
            acceptableKinTrials = ones(size(kinTrialData,1),1);
        end
        
        
        %Convert Base of Support and Mark location Data into cm from inches
        %Please note that mark data and base of support data locations have
        %their zero referenced to the transmitter.
        markData=horzcat(markData(:,1:12).*2.54,markData(:,13:end));
        bosData=bosData.*2.54;
        
        %Save the mark data and the relative rotation matrices for Victor's
        %use.
        disp('Saving Rotation Matrices from Mark Data for Kinematic Collection')
        markDataOutput = cat(1,markHeader,num2cell(markData));
        cell2csv([outpath levelText{level} 'MarkData.csv'], markDataOutput);
        
        %Save the Base of Support data for later use.
        disp('Saving Base of Support Data from Kinematic Collection')
        %Add column and row headers for BOS
        bosOut = horzcat(bosRHeader,num2cell(bosData));
        bosOut = vertcat(bosCHeader,bosOut);
        cell2csv([outpath levelText{level} 'BOSData.csv'],bosOut);
        
        %Save the Max Hd and C7 heights for later use.
        disp('Saving Max Head and C7 Heights.')
        %Add column headers to Max Heights
        maxHtOut = vertcat({'MaxHdHt','MaxTkHt'},{maxHdHt,maxTkHt});
        cell2csv([outpath levelText{level} 'MaxHeights.csv'],maxHtOut);
        
        %For all the kinTrialData, convert to CM, Filter, and Save to File.
        disp('Beginning Conversion and Filtration of Good Kinematic Trials with Reaches in them.')
        for tabInd = 1:length(kinTrialData)
            if(acceptableKinTrials(tabInd)==1 && ismember(tabInd,usedTrials))
                disp(['Converting and Filtering Data from Kinematic Trial ' num2str(tabInd)])
                kinTrialData{tabInd} = cleanRawKinData(kinTrialData{tabInd},bosData,kinSampRate);
                outData = num2cell(kinTrialData{tabInd});
                kinTableOutput = cat(1,kinHeader,outData);
                %Do we want to maintain this step in the final data flow?
                disp(['Saving Data from Kinematic Trial ' num2str(tabInd)])
                cell2csv([outpath levelText{level} 'FullTrials\kinTrial_' num2str(tabInd) '.csv'],kinTableOutput);
            else
                disp(['Skipping kinematic trial ' num2str(tabInd) ' as it was deemed unusable or had no reaches.'])
                kinTrialData{tabInd}={};
            end
        end
        
        %%%%End Stage 3%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Now, grab the sections of the trials that correspond to their
        %reaching activity, with 500ms included before reaching onset
        %as determined by OpenSHAPA
        
        %Cell Matrix for storing reach times out to file.
        %Hand, Reach Num, Reach Onset, Reach Offset
        reachTimesMS = cell(size(cSetData(1),1)+size(cSetData(2),1),1);
        
        reachTimesDP = cell(size(cSetData(1),1)+size(cSetData(2),1),1);
        
        for setV=1:2
            disp(['Processing data for: ' setMsg{setV} ' at ' levelText{level}])
            setData = cSetData{setV};
            handT = handTypes{setV};
            timeLocations=zeros(size(setData,1),5);
            reachHand = ift(mod(setV,2)==0,4,5);
            setTrials = cell(size(setData,1),1);
            %Grab event start and end points from OpenSHAPA data
            disp('Aligning Kinematic Data Region Selection to Event Time')
            for eventNum=1:size(setData,1)
                if(acceptableKinTrials(setData{eventNum,4}))
                    eventStart = setData{eventNum,2};
                    eventEnd = setData{eventNum,3};
                    reachNum = setData{eventNum,1};
                    dataLine = setData{eventNum,4};
                    
                    kinPreEvent = round(((eventStart-preEventLength)/1000)*kinSampRate);
                    kinEventStart = round((eventStart/1000)*kinSampRate);
                    kinEventEnd = round((eventEnd/1000)*kinSampRate);
                    if(kinPreEvent<1)
                        disp('Trial too short to accommodate Pre-Reaching Length.  Dropping Reach.')
                    else
                        %Place the times in the event
                        timeLocations(eventNum,:) = [dataLine,kinPreEvent,kinEventStart,kinEventEnd,eventNum];
                        %Add the trial data to the data to be analyzed
                        setTrials(eventNum) = kinTrialData(dataLine);
                    end
                end
            end
            %Here, the users are presented with a graphical display (borrow
            %from the multiEMGPicker, to allow cross checking the OpenSHAPA
            %reaching onsets with the resultant position and resultant
            %velocity.
            
            %Begin reviewing the reach onsets provided that two conditions hold
            %true.
            %Condition 1 -- There is OpenSHAPA data for this hand and reach
            %Condition 2 -- There are good reaches to analyze in the OpenSHAPA
            if(~isempty(timeLocations) && all(~all(timeLocations==0)))
                gOut = [outpath '\Graphs\'];
                levelString = levelText{level};
                gTitle = [levelString(2:end-1) ' ' setMsg{setV}];
                [timeLocationsMS, timeLocationsDP] = reviewReachOnsets(setTrials,timeLocations,reachHand,setData(:,5),gTitle, gOut);
                
                %Save out a list of corrected reaching onset and offset times in ms
                %for use in the EMG section.
                msTimeOut = cat(1,corrTimeHeader,num2cell(timeLocationsMS));
                cell2csv([outpath levelText{level} setMsg{setV} '_corrReachOnsetsMS.csv'],msTimeOut);
                
                %Save out the list of corrected reaching onset and offset
                %times in DP for use in the second Kinematic Section
                dpTimeOut = cat(1,corrTimeHeader,num2cell(timeLocationsDP));
                cell2csv([outpath levelText{level} setMsg{setV} '_corrReachOnsetsDP.csv'],dpTimeOut);
                
                %Isolate Reach/Grasp Data
                for dataLine=1:size(setTrials,1)
                    if(~(timeLocationsDP(dataLine,1)==0))
                        kinEventTable = setTrials{dataLine};
                        trialNum = setData{dataLine,4};
                        eventT = setData{dataLine,5};
                        %Older code expects time to be in seconds.
                        trialDur = (timeLocationsDP(dataLine,4)-timeLocationsDP(dataLine,3))/84;
                        reachNum = setData{dataLine,1};
                        kinEventData = kinEventTable(timeLocationsDP(dataLine,3):timeLocationsDP(dataLine,4),:);
                        %Save out the reach specific trial data
                        disp(['Saving Data from Kinematic Reach ' num2str(dataLine)])
                        kinEventOutput = cat(1,kinHeader,num2cell(kinEventData));
                        cell2csv([outpath levelText{level} 'ReachTrials\' setMsg{setV} '\kinTrial_' num2str(trialNum) '_' eventT '_' num2str(reachNum) '.csv'],kinEventOutput);
                    end
                end
            else
                disp('No usable reach regions to review at this level.')
            end
        end
    else
        disp(['No data available for ' levelText{level} ' level.'])
    end
end
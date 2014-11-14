%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%PROCESSKINEMATICSTATS.M
%
%Script to handle the processing and possibly statistical analysis of
%the kinematics in Jennifer's TD study.
%
%
%Author -- Wayne Manselle
%Date -- January 2014
%CHANGELOG -- 01.22.2014 -- Initial Creation, begin work from old
%                           ProcessSubjectData.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%Stage 0 -- Library and Constant Setup%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%See setupPath.m to ensure all paths are correctly set.
setupPath()

%Select all folders of subject data to process kinematic stats for --
%returns 0 on a cancelled selection
foldersToProcess = uipickfiles();

%Process those subjects
if(iscell(foldersToProcess))
    for procFolder=1:size(foldersToProcess,2)
        
        %Data Storage space for making scaled 3D graphs
        reachGraphStorage = {};
        
        %Storage space for the minimum and maximum extents of the reaching
        %data for this subject.  The organization is the minimum and
        %maximum of each of the three components of the reach, ML, AP and
        %Vertical.
        scaling = [NaN NaN NaN NaN NaN NaN];
        
        disp(['Currently Processing: ' foldersToProcess{procFolder}])
        %Get the list of all subject files that need processing.
        [fileList, levelText, topDir, curSubj] = CollectKinematicFiles(foldersToProcess{procFolder});
        
        %Study group specific setup variables.  Based on the subject string given,
        %method will return the preEvent time to examine, and EMG channels to
        %examine for the group that subject belongs to.
        [preEventLength, emgHeaders, keyMuscChans, mergeMuscChans, mergeBack, aChans, muscGroupings] =...
            groupSpecificSetup(curSubj);
        
        %This is a touch of a hack so that we can generate differently axis'd
        %Excursion Zone Graphs dependent on if it is a TD subject or a CP subject.
        group=ift(size(aChans,2)==5,1,2);
        
        %Begin setting up constants for file output.  Headers and whatnot.
        buildOutputDirectories(topDir, levelText);
        
        %Set all the Output paths.
        outpath = [topDir '\Output\Kinematics\'];
        
        %Current Kinematic Column headers.
        kinHeader = {'Trial','hdX','hdY','hdZ','hdCOMX','hdCOMY','hdCOMZ','c7X',...
            'c7Y','c7Z','tkCOMX','tkCOMY','tkCOMZ','lhX','lhY','lhZ',...
            'rhX','rhY','rhZ','Notes'};
        
        %Headers for the Kinematic Data Statistics File
        kinStatHeader = {'InfantID', 'Support', 'TrialNum', 'Hand', 'EventType', ...
            'ReachNum','MT','PathLen','Speed','PkVel','PctMT',...
            'StScore','MvUnits','MLMnHTAng','MLSdHTAng','MLMinHTAng','MLMaxHTAng',...
            'MLHTAbsVel','MLHTAvgVel','MLHTStdVel','MLTotHTAngDisp',...
            'APMnHTAng','APSdHTAng','APMinHTAng','APMaxHTAng','APHTAbsVel',...
            'APHTAvgVel','APHTStdVel','APTotHTAngDisp','MnHTAngSpeed',...
            'SumHTResAng','MLMnTCAng','MLSdTCAng','MLMinTCAng','MLMaxTCAng',...
            'MLTCAbsVel','MLTCAvgVel','MLTCStdVel','MLTotTCAngDisp','APMnTCAng',...
            'APSdTCAng','APMinTCAng','APMaxTCAng','APTCAbsVel','APTCAvgVel',...
            'APTCStdVel','APTotTCAngDisp','MnTCAngSpeed','SumTCResAngDisp',...
            'NJS','TPLYRH','TPLYTkCOM','TrunkCoupling','MnCurv','StdCurv',...
            'TkStb%','TkCont%','TkFall%','MaxHeadHt','MaxTkCOMHt'};
        
        setMsg = {'Right_Reach','Left_Reach','Right_Grasp_Data','Left_Grasp_Data'};
        handTypes = {'Right','Left','Right','Left'};
        eventTypes = {'Reach','Reach','Grasp','Grasp'};
        
        %Starter matrix for the Kinematic Statistical Analysis Outputs
        kinReachStatOutput= kinStatHeader;
        kinGraspStatOutput= kinStatHeader;
        
        for level=1:length(levelText)
            if(~isempty(fileList{level,1}))
                disp(['Beginning to process ' levelText{level} ' level data for this subject.'])
                close(gcf)
                
                %Matrices from the InterpretOSHAPA function have five columns.
                %Column 1 -- Event Number
                %Column 2 -- Start of Event referenced to trial Start time in ms.
                %Column 3 -- End of Event referenced to trial Start time in ms.
                %Column 4 -- Trial Number
                %Column 5 -- Event Code
                
                %The four tables are right handed reach events, left handed reach events,
                %right handed grasp events, and left handed grasp events respectively.
                disp('Interpreting the OpenSHAPA data...')
                reachData = fileList{level,1};
                trialData = fileList{level,2};
                
                [rReachData,lReachData] = ...
                    InterpretOSHAPA(reachData, trialData, curSubj);
                
                %Scan across openSHAPA data sets, note the trials that have reach
                %data in them.
                usedTrials = [cell2mat(rReachData(:,4)') cell2mat(lReachData(:,4)')];
                
                cSetData = {rReachData, lReachData};
                
                %%Important Note!  The following x lines of code are for the
                %%express purpose of correcting RPI issues in pre-calculated data.
                %%If your HDCOM and TKCOM data wasn't calculated with RPI, do not
                %%use this methodology.
                
                %Load Mark Data for correcting HD and TK COMS
                levMarkData = csvread([outpath levelText{level} 'MarkData.csv'],1,0);
                %Grab the position data from the sensors for Marks 3 and 7, as
                %prescribed, and reshape so each row is one sensor's data.
                hdPosData = reshape(levMarkData(3,1:12),3,4)';
                tkPosData = reshape(levMarkData(7,1:12),3,4)';
                
                %Load BOS for Level for Excursion Graphs and strip headers
                %Also grab maximum head and c7 heights
                bosData = readtext2([outpath levelText{level} 'BOSData.csv'],',','','','');
                bosData = cell2mat(bosData(2:end,2:end));
                maxHtData = readtext2([outpath levelText{level} 'MaxHeights.csv'],',','','','');
                maxHdHt = cell2mat(maxHtData(2,1));
                maxTkHt = cell2mat(maxHtData(2,2));
                
                disp('Processing Statistical Calculations for Level.')
                for setV=1:2
                    %Grab the Relevant OpenSHAPA guides
                    setData = cSetData{setV};
                    handT = handTypes{setV};
                    
                    %Check to make sure DP files are there
                    if(exist([outpath levelText{level} setMsg{setV} '_corrReachOnsetsDP.csv'],'file'))
                        %Load the DP Time Correct Data
                        timeLocationsDP = readtext2([outpath levelText{level} setMsg{setV} '_corrReachOnsetsDP.csv'],',','','','');
                        %Strip Headers
                        timeLocationsDP = cell2mat(timeLocationsDP(2:end,:));
                        
                        for dataLine=1:size(timeLocationsDP,1)
                            %Isolate Reach/Grasp Data
                            if(~(timeLocationsDP(dataLine,1)==0))
                                trialNum = setData{dataLine,4};
                                eventT = setData{dataLine,5};
                                reachHand = ift(mod(setV,2)==0,4,5);
                                %Older code expects time to be in seconds.
                                trialDur = (timeLocationsDP(dataLine,4)-timeLocationsDP(dataLine,3))/84;
                                reachNum = setData{dataLine,1};
                                
                                %Load the Reach Data
                                kinEventData = readtext2([outpath levelText{level} 'ReachTrials\' setMsg{setV} '\kinTrial_' num2str(trialNum) '_' eventT '_' num2str(reachNum) '.csv'],',','','','');
                                %Strip Header
                                kinEventData = cell2mat(kinEventData(2:end,:));
                                
                                %%Again, only if your HDCOM and TKCOM need
                                %%correction should you be executing the following
                                %%code
                                disp(['Correcting HDCom and TKCom from Kinematic Reach ' num2str(dataLine)])
                                
                                kinEventData = corCOM(kinEventData, hdPosData, tkPosData);
                                %%Hook for overwriting the kinEventData files that
                                %%are present.
                                
                                disp(['Saving Corrected Data from Kinematic Reach ' num2str(dataLine)])
                                kinEventOutput = cat(1,kinHeader,num2cell(kinEventData));
                                cell2csv([outpath levelText{level} 'ReachTrials\' setMsg{setV} '\kinTrial_' num2str(trialNum) '_' eventT '_' num2str(reachNum) '.csv'],kinEventOutput);
                                
                                %Insertion point for Reach Specific Graph Generation
                                levCode = levelText{level};
                                levCode = levCode(2);
                                zoneBreakdown = ...
                                    exZoneAnalysis(kinEventData(:,11:13),bosData,...
                                    0.5,1,[levCode '_T' num2str(trialNum) '_R' num2str(reachNum) '_' handT '_' eventT],...
                                    [outpath '\Graphs\'],group);
                                                               
                                %Do the 3D reach graphs
                                reachCol = ift(mod(setV,2)==0,14,17);
                                graph3DReach(kinEventData(:,reachCol:reachCol+2),...
                                    kinEventData(:,11:13),...
                                    [levCode '_T' num2str(trialNum) '_R' num2str(reachNum) '_' handT '_' eventT],...
                                    [outpath '\Graphs\']);
                                
                                %Add data used for these 3D reach graphs
                                %for later plotting
                                reachGraphStorage = vertcat(reachGraphStorage,...
                                    horzcat({kinEventData(:,reachCol:reachCol+2)},...
                                        {kinEventData(:,11:13)},...
                                        {['Scaled_' levCode '_T' num2str(trialNum) '_R' num2str(reachNum) '_' handT '_' eventT]},...
                                        {[outpath '\Graphs\']}));
                                
                                %Test range data and replace ranges as
                                %needed.
                                %If no ranges have been set yet, seed the
                                %data structure.
                                if(isnan(scaling(1)))
                                    scaling=[min(kinEventData(:,reachCol)) max(kinEventData(:,reachCol))...
                                        min(kinEventData(:,reachCol+1)) max(kinEventData(:,reachCol+1))...
                                        min(kinEventData(:,reachCol+2)) max(kinEventData(:,reachCol+2))];
                                else
                                    %Otherwise, test the min and max of
                                    %each range of motion and replace as
                                    %necessary.
                                    %XMin
                                    if(min(kinEventData(:,reachCol)) < scaling(1))
                                        scaling(1) = min(kinEventData(:,reachCol));
                                    end
                                    %XMax
                                    if(max(kinEventData(:,reachCol)) > scaling(2))
                                        scaling(2) = max(kinEventData(:,reachCol));
                                    end
                                    %YMin
                                    if(min(kinEventData(:,reachCol+1)) < scaling(3))
                                        scaling(3) = min(kinEventData(:,reachCol+1));
                                    end
                                    %YMax
                                    if(max(kinEventData(:,reachCol+1)) > scaling(4))
                                        scaling(4) = max(kinEventData(:,reachCol+1));
                                    end
                                    %ZMin
                                    if(min(kinEventData(:,reachCol+2)) < scaling(5))
                                        scaling(5) = min(kinEventData(:,reachCol+2));
                                    end
                                    %ZMax
                                    if(max(kinEventData(:,reachCol+2)) > scaling(6))
                                        scaling(6) = max(kinEventData(:,reachCol+2));
                                    end
                                end
                                
                                %disp('Current State of Scaling')
                                %scaling
                                
                                [ hdC7Angs, c7CBOSAngs ] = calcKinAngs(kinEventData(:,2:19));
                                kinReachStats = ...
                                    num2cell(calcKinStats(kinEventData(:,2:19), reachHand, trialDur, hdC7Angs, c7CBOSAngs));
                                %Add any necessary extra columnary data to the kinReachStats array.
                                kinReachStatRow = ...
                                    horzcat(curSubj,levelText{level},trialNum,handT,eventT,reachNum,trialDur,kinReachStats,zoneBreakdown(1),zoneBreakdown(2),zoneBreakdown(3),maxHdHt,maxTkHt);
                                %Append the new Row of Data to the proper final kinematic stat output
                                %file.
                                kinReachStatOutput = cat(1,kinReachStatOutput,kinReachStatRow);
                            end
                        end
                    else
                        disp(['No Time & Location Data found for: ' levelText{level}  ' ' setMsg{setV} 'Combination.'])
                    end
                end
            else
                disp(['No data available for ' levelText{level} ' level.'])
            end
        end
        
        %%%%Stage 3.5 -- Generate both styles of Kinematic Reaching Graphs%
        
        %Now, expand each of the ranges given for the within subjects
        %3D-reach scaled graph so the visuals have some whitespace.
        scaling(1:2:size(scaling,2)) = floor(scaling(1:2:size(scaling,2))) - 1;
        scaling(2:2:size(scaling,2)) = ceil(scaling(2:2:size(scaling,2))) + 1;
        
        for dataSet=1:size(reachGraphStorage,1)
            graph3DReach(reachGraphStorage{dataSet,1},...
                reachGraphStorage{dataSet,2},reachGraphStorage{dataSet,3},...
                reachGraphStorage{dataSet,4},scaling);
        end
        
        %%%%Stage 4 -- Export Kinematic Stats%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %Save out the kinStatFile
        if(size(kinReachStatOutput,1)>1)
            cell2csv([outpath 'Stats\KinematicStats.csv'],kinReachStatOutput);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%End Stage 4%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
else
    disp('No Directories Selected.  Exiting.')
end
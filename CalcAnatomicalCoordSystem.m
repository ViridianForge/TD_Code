%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CALCANATOMICALCOORDSYSTEM.M -- This script contains all the steps and
%interaction necessary to derive the anatomical and joint coordinate
%systems for the Head and Trunk from the Rachwani-Santamaria TD
%Longitudinal Experiment.
%
%To generate these ACS files, we rely on the mark and base of support data
%calculated during the initial analysis of the subject's kinematic data
%files.  As such, it is essential that the cleanKinData.m script be run on
%the subject's data before this script, so all necessary data files exist.
%
%The final output from this script will be two csv files, consisting of the
%Head and Trunk Anatomical Coordinate Systems.  These files will be in the
%following format:
%
%HEADERS -- i  j  k
%DATA    -- ix jx kx
%           iy jy ky
%           iz jz kz
%
%Author -- Wayne Manselle
%Date -- June 2014
%Changelog -- Initial Creation - 6/4/2014
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%How can I rig this to run over an arbitrarily selected number of folders?


%%%%Stage 0 -- Library and Constant Setup%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%See setupPath.m to ensure all paths are correctly set.
setupPath()

handAdds = {'Left_Reach','Right_Reach'};

rotMatOutHeader={'Hd_i','Hd_j','Hd_k','Tk_i','Tk_j','Tk_k'};

angleOutHeader={'HGGamma','HGBeta','HGAlpha','TGGamma','TGBeta','TGAlpha',...
    'HTGamma','HTBeta','HTAlpha'};

hgStatsHeader={'HGMinAngG','HGMaxAngG','HGMeanAngG','HGStdAngG',...
    'HGStdAbsG','HGPathLenG','HGAngRangG','HGMinAngB','HGMaxAngB','HGMeanAngB',...
    'HGStdAngB','HGStdAbsB','HGPathLenB','HGAngRangB','HGMinAngA','HGMaxAngA',...
    'HGMeanAngA','HGStdAngA','HGStdAbsA','HGPathLenA','HGAngRangA'};

tgStatsHeader={'TGMinAngG','TGMaxAngG','TGMeanAngG','TGStdAngG',...
    'TGStdAbsG','TGPathLenG','TGAngRangG','TGMinAngB','TGMaxAngB','TGMeanAngB',...
    'TGStdAngB','TGStdAbsB','TGPathLenB','TGAngRangB','TGMinAngA','TGMaxAngA',...
    'TGMeanAngA','TGStdAngA','TGStdAbsA','TGPathLenA','TGAngRangA'};

htStatsHeader={'HTMinAngG','HTMaxAngG','HTMeanAngG','HTStdAngG','HTStdAbsG',...
    'HTPathLenG','HTAngRangG','HTMinAngB','HTMaxAngB','HTMeanAngB',...
    'HTStdAngB','HTStdAbsB','HTPathLenB','HTAngRangB','HTMinAngA','HTMaxAngA',...
    'HTMeanAngA','HTStdAngA','HTStdAbsA','HTPathLenA','HTAngRangA','HTAnchIndG',...
    'HTAnchIndB','HTAnchIndA'};

%Graphic Buffer -- The percentage on either side of the absolute
%range of the minimum angle to maximum angle of each angle group to give 
%as buffer to the graphs.
%i.e. if the range was 0-80 degrees, then there would be an 8 degree buffer
gBuf = 10;

%Run UI Pick Files
foldersToProcess=uipickfiles();

for procFold=1:size(foldersToProcess,2)
    %Get the list of all subject files that need processing.
    [fileList, levelText, topDir, curSubj] = CollectKinematicFiles(foldersToProcess{procFold});
    
    %Prep the Subject's Angular Data Storage
    %In these two declarations, I am using the deal function to enable
    %initializing multiple varables to the same value.
    [headGlobAngs, trunkGlobAngs, headTrunkAngs, reachLevels, reachLabels] = ...
        deal({});
    
    %Prep the stat storage for each subject   
    [hdWRTGlobStats,tkWRTGlobStats,hdWRTTkStats] = deal([]);
    
    %Error case checks.  If any of these match, skip this subject, give the
    %user a warning to note, and continue on the processing.
    if(topDir==0)
        disp('No files found for subject.  Please review their data directory.')
        continue
    end
    
    disp('Getting Kin File')
    %Get the labelling from the stat file.
    if(exist([topDir '\Output\Kinematics\Stats\KinematicStats.csv'],'file'))
        statLabels = readtext2([topDir '\Output\Kinematics\Stats\KinematicStats.csv'],',','','','');
    else
        disp('Selected Folder lacking Kinematic Stats file.')
        disp(['Check ' curSubj ' to see if subject has been run through Kinematic Processing.'])
        continue
    end
    statLabels = statLabels(:,1:6);
    labelCount = 2;
    
    %%Begin Generating the ACS for each level
    disp('Beginning Generation of Anatomical Coordinate Systems.')
    for sLevel=1:size(levelText,2)
        
        curLev = levelText{sLevel};
        
        %%STEP 1 -- Load the Data!
        dataLocation = [topDir '\Output\Kinematics' curLev];
        statsDir = [topDir '\Output\Kinematics\Stats\'];
        kinRawData = fileList{sLevel,3};
        
        %Make sure our angular trial output location exists
        if(~exist([dataLocation 'reachAngData\'],'dir'))
            mkdir([dataLocation 'reachAngData\']);
        end
        
        %Make sure our rot mat trial output location exists
        if(~exist([dataLocation 'reachRotMatData\'],'dir'))
            mkdir([dataLocation 'reachRotMatData\']);
        end
        
        if(~exist([dataLocation 'reachRotMatGraphs\'],'dir'))
            mkdir([dataLocation 'reachRotMatGraphs\'])
        end
        
        if(~exist([dataLocation 'reachRotMatGraphsScaled\'],'dir'))
            mkdir([dataLocation 'reachRotMatGraphsScaled\'])
        end
        
        %Load the Raw Kinematic File for this level in order to get access to
        %the trial by trial rotational matrices for Stage 2 and 3 processing
        [kinTrialData,rotTrialData, markData,rpiData,bosData, maxHdHt,...
            maxTkHt] = FranEraBirdConverter(kinRawData);
        
        %We'll also need the event times for this level.
        if(exist([topDir '\Output\Kinematics' curLev 'Right_Reach_corrReachOnsetsDP.csv'],'file'))
            reachEvents{1} = csvread([topDir '\Output\Kinematics' curLev 'Right_Reach_corrReachOnsetsDP.csv'],1,0);
        else
            reachEvents{1} = nan;
        end
        
        if(exist([topDir '\Output\Kinematics' curLev 'Left_Reach_corrReachOnsetsDP.csv'],'file'))
            reachEvents{2} = csvread([topDir '\Output\Kinematics' curLev 'Left_Reach_corrReachOnsetsDP.csv'],1,0);
        else
            reachEvents{2} = nan;
        end
        
        %The CBOS data for the Subject,Session,Level combo
        levBOSData = csvread([dataLocation 'BOSData.csv'],1,1);
        %Grab the position data marking the derived center of base of support.
        %Invert the matrix to play nicely with the reshaped marker data
        %matrices coming up below.
        
        %multiplying the z component of cbos data by -1:
        %this is to convert the z component of the data back into the
        %miniBird's original Z-Axis positive toward the floor notation
        levBOSData(3,9)=levBOSData(3,9)*(-1);
        cbosPosData = levBOSData(3,7:9);
        
        %The Mark data for the Subject,Session,Level combo
        levMarkData = csvread([dataLocation 'MarkData.csv'],1,0);
        %Grab the position data from the sensors for Marks 3 and 7, as
        %prescribed, and reshape so each row is one sensor's data.
        
        %multiplying the z component of mark data by -1:
        %this is to convert the z component of the data back into the
        %miniBird's original Z-Axis positive toward the floor notation
        levMarkData(:,1:12) = levMarkData(:,1:12);
        levMarkData(:,3:3:12) = levMarkData(:,3:3:12)*(-1);
        
        mark3PosData = reshape(levMarkData(3,1:12),3,4);
        mark7PosData = reshape(levMarkData(7,1:12),3,4);
        
        %Reassemble the Rotational Matrices of Marks 3 and 7 from the Fran
        %Era bird data.  We only care about the head sensor for Mark 3,
        %which is Sensor 1.  For Mark 7, we only care about the C7 marker,
        %which is Sensor 2.
        
        mark3RotMat = [markData(3,13:15);markData(3,16:18);markData(3,19:21)]';
        
        mark7RotMat = [markData(7,22:24);markData(7,25:27);markData(7,28:30)]';
        
        %%Create Anatomical Coordinate System for the Head
        %Head ACS needs Data from Mark 3, Sensors 1, 3 and 4. (HdTrk,L.Arm,R.Arm)
        %Origin Head  = ((Sensor 4 + Sensor 3)/2)
        
        originPosHd = (mark3PosData(:,4)' + mark3PosData(:,3)')/2;
        %iVector Calcs
        %Sensor 3 - Origin Head = iVecHd
        %(iVecHd/norm(iVecHd)) = iUnitVecHd
        iVecHd = mark3PosData(:,3)' - originPosHd;
        
        iUnitVecHd = (iVecHd/norm(iVecHd));
        
        %Y Coordinate of Sensor 1 - Y Coordinate of Origin Head = Y Virtual Hd Top
        %Virtual Hd Top (x,y,z) = Head Origin X, Head Origin Y, Sensor 1 Z
        virPosHdTop = [originPosHd(1);originPosHd(2);mark3PosData(3,1)];
        
        %Virtual Hd Top (x,y,z) - Origin Head = VecHdTop
        %(jVecHd/norm(jVecHd)) = jUnitVecHd
        VecHdTop = virPosHdTop' - originPosHd;
        
        jVecHd = cross(iVecHd,VecHdTop);
        jUnitVecHd = (jVecHd/norm(jVecHd));
        
        %iUnitVecHd crossproduct jUnitVecHd = kUnitVecHd
        kUnitVecHd = cross(iUnitVecHd,jUnitVecHd);
        
        %Concatenate the transposed Unit Vectors together into the final ACS
        %for the head.  i,j,k ordering.
        acsHead = horzcat(iUnitVecHd',jUnitVecHd',kUnitVecHd');
        
        %%Create Anatomical Coordinate System for the Trunk
        %Trunk ACS needs data from Mark 7 AND the CBOS file
        %From Mark 7
        %(Sensor 4 + Sensor 2)/2 = OriginTrunk
        midPtNeck = (mark7PosData(:,4)' + mark7PosData(:,2)')/2;
        
        originTrunk = (cbosPosData + midPtNeck)/2;
        
        %Translated Sternal Notch Mark
        transSNMk = [mark7PosData(1,4) mark7PosData(2,4) originTrunk(3)];
        
        %% jVecCalcs
        %(Sensor 4 - OriginTrunk) = jVecTrunk
        %(jVecTrunk/norm(jVecTrunk)) = jUnitVecTrunk
        jVecTrunk = mark7PosData(:,4)' - transSNMk;
        jUnitVecTrunk = (jVecTrunk/norm(jVecTrunk));
        
        %% kVecCalcs
        %(CBOS - originTrunk) = kVecTrunk
        %(kVecTrunk/normkVecTrunk) = kUnitVecTrunk
        %We're calculating a temporary K vector to help us hone in on the
        %true i vector, and through it, the true K vector.
        addKVecTrunk = cbosPosData - originTrunk;
        %addKUnitVecTrunk = (addKVecTrunk/norm(addKVecTrunk));
        
        %jUnitVecTrunk crossproduct kUnitVecTrunk = iUnitVecTrunk
        iUnitVecTrunk = (cross(jVecTrunk,addKVecTrunk)/norm(cross(jVecTrunk,addKVecTrunk)));
        
        kUnitVecTrunk = cross(iUnitVecTrunk,jUnitVecTrunk);
        
        %Concatenate the transposed Unit Vectors together into the final ACS
        %for the trunk.  i,j,k ordering.
        acsTrunk = horzcat(iUnitVecTrunk',jUnitVecTrunk',kUnitVecTrunk');
        
        
        %Create our Anatomical Referenced to Tracking Matrix Constants
        %using the rotational matrices from the Mark Data in order to have
        %a constant path translation for angular calculations.
        
        HdCal = mark3RotMat' * acsHead;
        TkCal = mark7RotMat' * acsTrunk;
        
        
        %Save the ACS of the Head for this level.
        cell2csv([dataLocation 'AnatomicalHeadCoordinateSystem.csv'],...
            vertcat({'i','j','k'},num2cell(acsHead)));
        
        %Save the ACS of the Trunk for this level.
        cell2csv([dataLocation 'AnatomicalTrunkCoordinateSystem.csv'],...
            vertcat({'i','j','k'},num2cell(acsTrunk)));
        
        disp('Coordinate Systems Generated.  Beginning Further Processing.')
        
        %%Stage 2 -- Use the ACS and TCS to modify the rotational matrices
        for reachType=1:2
            if(~isnan(reachEvents{reachType}))
                curEvSet = reachEvents{reachType};
                for event=1:size(curEvSet,1)
                    curEvent = curEvSet(event,:);
                    %Look at the time data here get on and off and trial
                    if(curEvent(1)~=0)
                        
                        %% Prep Event Information
                        trial=curEvent(1);
                        eventOn=curEvent(3);
                        eventOff=curEvent(4);
                        if(trial <= size(rotTrialData,1))
                            curTrial = rotTrialData{trial};
                        else
                            disp('*******************************************************************************')
                            disp('Please review the timing data for this level for errors.')
                            disp('There is a mismatch in trial numbering between the index files and the data.')
                            disp('Skipping reach.')
                            disp('All other reaches that successfully process should be considered suspect.')
                            disp('Diagnostic Information Follows: ')
                            disp(['Trial ' num2str(trial) ' was requested.'])
                            disp(['There are only ' num2str(size(rotTrialData,1)) ' trials present in the file.'])
                            disp('********************************************************************************')
                            continue
                        end
                        %Here's where we've run into problems before.
                        %Gonna try some try/catch magic
                        
                        if(eventOff <= size(curTrial,1))
                            curRegion = curTrial(eventOn:eventOff,:);
                        else
                            disp('********************************************************************************')
                            disp('Please review the timing data for this level for errors.')
                            disp('The reach event offset time extends beyond the available reach data.')
                            disp('Skipping this reach.')
                            disp('All other reaches that successfully process should be considered suspect.')
                            disp('Diagnostic Information Follows: ')
                            disp(['Reported Event Onset of: ' num2str(eventOn) ' and Offset of: ' num2str(eventOff)])
                            disp(['Actual amount of available data for trial ' num2str(trial) ' is: ' num2str(size(curTrial,1))])
                            disp('********************************************************************************')
                            continue
                        end
                        
                        %% Prep Variable Storage
                        % Again, using deal here to automate the
                        % initialization of multiple variables to the same
                        % values.
                        
                        %Storage of compiled output
                        [hdWRTGOut, tkWRTGOut, hdWRTTkOut] = ...
                            deal(cell(size(curRegion,1)*3,3));
                        
                        %Storage for Angles
                        [gammaHG, betaHG, alphaHG,...
                            gammaTG, betaTG, alphaTG,...
                            gammaHT, betaHT, alphaHT] = ...
                            deal(zeros(size(curRegion,1),1));
                        
                        %% Begin Processing each datapoint in the event
                        for dataLine=1:size(curRegion,1)
                            
                            %Calculate translated rotational matrices.
                            hdWRTSpace=(curRegion{dataLine,1} * HdCal);
                            tkWRTSpace=(curRegion{dataLine,2} * TkCal);

                            %6/23/2014 approach
                            hdWRTTk = (((HdCal' * curRegion{dataLine,1}') * curRegion{dataLine,2}) * TkCal);

                            %Original Approach
                            %hdWRTTk = (((acsHead' * curRegion{dataLine,1}') * curRegion{dataLine,2}) * acsTrunk);
                            
                            hdWRTGOut((dataLine*3-2):dataLine*3,:) = num2cell(hdWRTSpace);
                            tkWRTGOut((dataLine*3-2):dataLine*3,:) = num2cell(tkWRTSpace);
                            hdWRTTkOut((dataLine*3-2):dataLine*3,:) = num2cell(hdWRTTk);
                            
                            %Append these matrices to their own files for
                            %eventual saving.
                            
                            %%Stage 3 -- Get the angles of each of these matrices?
                            %Also, make sure you have the right locations!
                            
                            %Head with Respect to Global
                            gammaHG(dataLine) = mod(atan2(hdWRTSpace(3,3),hdWRTSpace(2,3)),2*pi);
                            betaHG(dataLine) = mod(atan2(-hdWRTSpace(3,3),(hdWRTSpace(1,3)*cos(gammaHG(dataLine)))),2*pi);
                            alphaHG(dataLine) = mod(atan2(hdWRTSpace(1,1),hdWRTSpace(1,2)),2*pi);
                            
                            %Trunk with Respect to Global
                            gammaTG(dataLine) = mod(atan2(tkWRTSpace(3,3),tkWRTSpace(2,3)),2*pi);
                            betaTG(dataLine) = mod(atan2(-tkWRTSpace(3,3),(tkWRTSpace(1,3)*cos(gammaTG(dataLine)))),2*pi);
                            alphaTG(dataLine) = mod(atan2(tkWRTSpace(1,1),tkWRTSpace(1,2)),2*pi);
                            
                            %Head with Respect to Trunk
                            gammaHT(dataLine) = mod(atan2(hdWRTTk(3,3),hdWRTTk(2,3)),2*pi);
                            betaHT(dataLine) = mod(atan2(-hdWRTTk(3,3),(hdWRTTk(1,3)*cos(gammaHT(dataLine)))),2*pi);
                            alphaHT(dataLine) = mod(atan2(hdWRTTk(1,1),hdWRTTk(1,2)),2*pi);
                        end
                        
                        gammaHG = remAngDisconts(gammaHG);
                        betaHG = remAngDisconts(betaHG);
                        alphaHG = remAngDisconts(alphaHG);
                        
                        gammaTG = remAngDisconts(gammaTG);
                        betaTG = remAngDisconts(betaTG);
                        alphaTG = remAngDisconts(alphaTG);
                        
                        gammaHT = remAngDisconts(gammaHT);
                        betaHT = remAngDisconts(betaHT);
                        alphaHT = remAngDisconts(alphaHT);
                        
                        %File Label to be applied to all output for this
                        %reach.
                        fileLabel = [num2str(statLabels{labelCount,3}) '_' statLabels{labelCount,5} '_' num2str(statLabels{labelCount,6})];
                        
                        %% Rotational Matrix Output
                        
                        %Assemble Rotational Matrix Output for this event
                        cell2csv([dataLocation 'reachRotMatData\hdWRTGlobMats' fileLabel '.csv'],hdWRTGOut);
                        cell2csv([dataLocation 'reachRotMatData\tkWRTGlobMats' fileLabel '.csv'],tkWRTGOut);
                        cell2csv([dataLocation 'reachRotMatData\hdWRTTkMats' fileLabel '.csv'],hdWRTTkOut);
                        
                        labelCount=labelCount+1;
                        
                        %Assemble Angular Data for this reach/level combo
                        headGlobAngs = horzcat(headGlobAngs, {horzcat(gammaHG,betaHG,alphaHG)});
                        trunkGlobAngs = horzcat(trunkGlobAngs, {horzcat(gammaTG,betaTG,alphaTG)});
                        headTrunkAngs = horzcat(headTrunkAngs, {horzcat(gammaHT,betaHT,alphaHT)});
                        reachLevels = horzcat(reachLevels, curLev);
                        reachLabels = horzcat(reachLabels, fileLabel);
                        
                        %Assemble Angular Output for this event
                        evtOut = vertcat(angleOutHeader,num2cell(horzcat(gammaHG,betaHG,alphaHG,gammaTG,betaTG,alphaTG,gammaHT,betaHT,alphaHT)));
                        cell2csv([dataLocation 'reachAngData\compiledAngularData_' fileLabel '.csv'],evtOut);
                        
                        %% Put the Stats together
                        
                        %Assemble Angular Stats for this event
                        hdWRTGlobRow = rotMatAngStats(gammaHG,betaHG,alphaHG);
                        tkWRTGlobRow  = rotMatAngStats(gammaTG,betaTG,alphaTG);
                        hdWRTTkRow = rotMatAngStats(gammaHT,betaHT,alphaHT);
                        
                        %Add the Anchoring Index to the Head WRT Trunk Stats
                        %Formula from Head, arm and trunk coordination during
                        %reaching in children by Sveistrup, Schneiberg,
                        %McKinley, McFadyen, and Levin - Exp Brain Res 2008
                        %
                        %std(head_trunk) - std(head_global) / std(head_trunk) +
                        %std(head_global)
                        %
                        %Positive Result --> Better stabilization of the head
                        %in space
                        %Negative Result --> Better stabilization of the head
                        %on the trunk
                        
                        anchIndG = ((hdWRTTkRow(:,4).^2-hdWRTGlobRow(:,4).^2)./(hdWRTTkRow(:,4).^2+hdWRTGlobRow(:,4).^2));
                        anchIndB = ((hdWRTTkRow(:,11).^2-hdWRTGlobRow(:,11).^2)./(hdWRTTkRow(:,11).^2+hdWRTGlobRow(:,11).^2));
                        anchIndA = ((hdWRTTkRow(:,18).^2-hdWRTGlobRow(:,18).^2)./(hdWRTTkRow(:,18).^2+hdWRTGlobRow(:,18).^2));
                        
                        hdWRTGlobStats = vertcat(hdWRTGlobStats,hdWRTGlobRow);
                        tkWRTGlobStats = vertcat(tkWRTGlobStats,tkWRTGlobRow);
                        hdWRTTkStats = vertcat(hdWRTTkStats,horzcat(hdWRTTkRow,anchIndG,anchIndB,anchIndA));
                    end
                end
            else
                disp('No reaches of this type at this level.')
            end
        end
    end
    %% Output Compiled Statistics to File
    
    %First, test to make sure labelling will actually work out and not
    %crash.
    try
        cell2csv([statsDir '\HdWRTGlobalStats.csv'],horzcat(statLabels, vertcat(hgStatsHeader,num2cell(hdWRTGlobStats))));
        cell2csv([statsDir '\TkWRTGlobalStats.csv'],horzcat(statLabels, vertcat(tgStatsHeader,num2cell(tkWRTGlobStats))));
        cell2csv([statsDir '\HdWRTTkStats.csv'],horzcat(statLabels, vertcat(htStatsHeader,num2cell(hdWRTTkStats))));
               
        %%Calculate the scaling factors for all graphs
        
        %Organize max of each angle group for graphics purposes
        limHGAngs = [floor(min(hdWRTGlobStats(:,1))) floor(min(hdWRTGlobStats(:,8))) floor(min(hdWRTGlobStats(:,15)));
            ceil(max(hdWRTGlobStats(:,2))) ceil(max(hdWRTGlobStats(:,9))) ceil(max(hdWRTGlobStats(:,16)))];
        limTGAngs = [floor(min(tkWRTGlobStats(:,1))) floor(min(tkWRTGlobStats(:,8))) floor(min(tkWRTGlobStats(:,15)));
            ceil(max(tkWRTGlobStats(:,2))) ceil(max(tkWRTGlobStats(:,9))) ceil(max(tkWRTGlobStats(:,16)))];
        limHTAngs = [floor(min(hdWRTTkStats(:,1))) floor(min(hdWRTTkStats(:,8))) floor(min(hdWRTTkStats(:,15)));
            ceil(max(hdWRTTkStats(:,2))) ceil(max(hdWRTTkStats(:,9))) ceil(max(hdWRTTkStats(:,16)))];
        
        %Use the graph buffer constant set above to calculate the buffer to
        %use in each graph group.
        hgBuf = ceil(abs(limHGAngs(1,:) - limHGAngs(2,:))/gBuf);
        tgBuf = ceil(abs(limTGAngs(1,:) - limTGAngs(2,:))/gBuf);
        htBuf = ceil(abs(limHTAngs(1,:) - limHTAngs(2,:))/gBuf);
        
        %Adjust Head v. Global  Graph Limits
        limHGAngs(1,:) = limHGAngs(1,:) - hgBuf;
        limHGAngs(2,:) = limHGAngs(2,:) + hgBuf;
        
        %Adjust Trunk v. Global Graph Limits
        limTGAngs(1,:) = limTGAngs(1,:) - tgBuf;
        limTGAngs(2,:) = limTGAngs(2,:) + tgBuf;
        
        %Adjust Head v. Trunk Graph Limits
        limHTAngs(1,:) = limHTAngs(1,:) - htBuf;
        limHTAngs(2,:) = limHTAngs(2,:) + htBuf;
        
                
        %% Graphics!
        %Generate a plot of Gamma, Beta and Alpha for each
        %rotational matrix perspective.        
        for angSet = 1:size(headGlobAngs,2)
            
            %Plot Self-Scaled Graphs
            graphRotMatAngs(headGlobAngs{angSet},['Head Versus Global of ' reachLabels{angSet}],...
                reachLabels{angSet},[topDir '\Output\Kinematics' reachLevels{angSet} 'reachRotMatGraphs\hdWRTGlob']);
            graphRotMatAngs(trunkGlobAngs{angSet},['Trunk Versus Global of ' reachLabels{angSet}],...
                reachLabels{angSet},[topDir '\Output\Kinematics' reachLevels{angSet} 'reachRotMatGraphs\trkWRTGlob']);
            graphRotMatAngs(headTrunkAngs{angSet},['Head Versus Trunk of ' reachLabels{angSet}],...
                reachLabels{angSet},[topDir '\Output\Kinematics' reachLevels{angSet} 'reachRotMatGraphs\hdWRTTrk']);
            
            %Plot "Max Angle"-Scaled Graphs
            graphRotMatAngs(headGlobAngs{angSet},['Head Versus Global of ' reachLabels{angSet}],...
                reachLabels{angSet},[topDir '\Output\Kinematics' reachLevels{angSet} 'reachRotMatGraphsScaled\hdWRTGlob'],limHGAngs);
            graphRotMatAngs(trunkGlobAngs{angSet},['Trunk Versus Global of ' reachLabels{angSet}],...
                reachLabels{angSet},[topDir '\Output\Kinematics' reachLevels{angSet} 'reachRotMatGraphsScaled\trkWRTGlob'],limTGAngs);
            graphRotMatAngs(headTrunkAngs{angSet},['Head Versus Trunk of ' reachLabels{angSet}],...
                reachLabels{angSet},[topDir '\Output\Kinematics' reachLevels{angSet} 'reachRotMatGraphsScaled\hdWRTTrk'],limHTAngs);
        end
    catch err
        disp('********************************************************************************')
        disp(['Saving of the stats files has failed for ' curSubj])
        disp('This is likely due to a mismatch between the number of trials in the kinematic stats file, and the number of trials found to be valid for the rotational matrices.')
        disp('Please review the script output to see if this subject had trial timings that did not work out.')
        disp('Diagnostic Information Follows: ')
        disp(['The reference statistics file indicates there should be ' num2str(size(statLabels,1)-1) ' trials of data across levels of support.'])
        disp(['The processed data only yielded data for ' num2str(size(hdWRTTkStats,1)) ' trials across levels of support.'])
        disp('********************************************************************************')
    end
end
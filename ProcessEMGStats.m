%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%PROCESSEMGSTATS.M
%
%Script to handle the processing and possibly statistical analysis of
%Jennifer's TD study.
%
%
%Author -- Wayne Manselle
%Date -- January 2014
%CHANGELOG -- 01.22.2014 -- Initial Creation, begin work from old
%                           ProcessSubjectData.m
%             03.15.2014 -- Building logic for generating binned IEMG and
%                           picking onsets automatically.
%             03.22.2014 -- Adding graphical review of onsets.
%             04.10.2014 -- Adding in metric processing
%             05.05.2014 -- Adding in automated graph generation similar to
%                           the adult paper's
%             05.07.2014 -- Further parameterization of functions for
%                           maximal customizability
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%Stage 0 -- Library and Constant Setup%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%See setupPath.m to ensure all paths are correctly set.
setupPath()

%Constants used by the function

%Successful Reaches, Event codes that indicate a subject's reach was
%successful.  These are used in Co-Activation Analysis, where we only want
%to process only successful reaches.
succReaches = {'BDS','BDSG','US','USG','UDSR','BDSR','CBDSR'};

%BinSize -- The number of milliseconds each iEMG bin is to use
binSize=10;

%WindowSize -- The number of milliseconds in the Quiet Segment Window
winSize=3000;

%actSize -- The number of milliseconds the normalized activity must be
%at or above the set threshold to be considered activated.
actSize=80;

%deactSize -- The number of milliseconds the normalized activity must be
%below the set threshold to be considered deactivated.
deactSize=actSize;

%sdThreshold -- The Number of Standard Deviations to use in the
%Normalization Function
normFactor=2;

%apaPreLength -- The number of ms before the reach onset to consider the
%APA section
apaPreLength=-300;

%maxGroupSize -- The largest number of muscles in a group
maxGroupSize = 3;

%1 -- Number of activations across APA and CPA stages
%2 -- Onset Time in APA Stage
%3 -- Onset Time in CPA Stage
%4 -- Total Activation Time in APA Stage
%5 -- Total Activation Time in CPA Stage
%6 -- Total IEMG in Baseline Stage
%7 -- Total IEMG in APA Stage
%8 -- Total IEMG in CPA Stage
%9 -- Co-Activation in APA Stage -- B CoAc T, AD CoAc T, L CoAc T
%10 -- Co-Activation in CPA Stage

emgMetricHeader = {'Muscle','SupportLevel','Hand','ReachType','TrialNum',...
    'ReachNum','Tot Num Bursts','Num Baseline Bursts','Num APA Bursts',...
    'Num CPA Bursts','Baseline Onset Time','Baseline Offset Time',...
    'APA Onset Time','APA Offset Time','CPA Onset Time','CPA Offset Time',...
    'Time Activated APA','Time Activated CPA','Norm. IEMG of Baseline',...
    'Norm. IEMG of APA','Norm. IEMG of CPA','Reach Offset Time','Musc Act. Whole Reach'};

%Select all folders of subject data to process kinematic stats for --
%returns 0 on a cancelled selection
foldersToProcess = uipickfiles();

%If the number of folders selected is more than 1, then turn off asking the
%user if they want to review data.
askReview = ift((size(foldersToProcess,2) > 1),0,1);

%Process those subjects
if(iscell(foldersToProcess))
    for procFolder=1:size(foldersToProcess,2)
        disp(['Currently Processing: ' foldersToProcess{procFolder}])
        %Set up the EMG Out File
        emgMetricOut = emgMetricHeader;
        
        %Get the list of all subject files that need processing.
        [fileList, levelText, topDir, curSubj] = CollectEMGFiles(foldersToProcess{procFolder});
        
        %Begin setting up constants for file output.  Headers and whatnot.
        buildOutputDirectories(topDir, levelText);
        
        %Set all the Output paths.
        outpath = [topDir '\Output\EMG\'];
        
        %Study group specific setup variables.  Based on the subject string given,
        %method will return the preEvent time to examine, and EMG channels to
        %examine for the group that subject belongs to.
        [preEventLength, emgHeaders, keyMuscChans, mergeMuscChans, mergeBack,...
        aChans, muscGroupings, kinSampRate] = groupSpecificSetup(curSubj);
        
        coActTabLabels={'rBi';'rTri';'rAD';'lBi';'lTri';'lAD';'Merg.Thor.';'Merg.Lum';''};
        
        if(mergeBack)
            mergedHeaders = mergeHeaders(emgHeaders,mergeMuscChans);
        else
            mergedHeaders = emgHeaders;
        end
        
        %Storage Variables for processed data by level
        procEMG=cell(length(levelText),1);
        trigChans=cell(length(levelText),1);
        totPkAmps = nan(size(mergedHeaders));
        baseLines=cell(length(levelText));
        stDevs=cell(length(levelText));
        
        %%%%%%%%%%%%%%%%%%%Begin the actual data processing!%%%%%%%%%%%%%%%%%%%%%%%
        
        %Begin with an assumption that the subject has already been run
        %through CleanEMG
        cleanData=1;
        
        %1 -- Load in the processed data
        for level=1:size(procEMG,1)
            %Try loading in the CleanedEMG files.  If a level is somehow
            %missing CleanedEMG, that implies that CleanEMGData was either
            %not run for this subject, or didn't successfully complete.
            try
                levelData = ...
                    csvread([outpath levelText{level} 'FullTrials\CleanedEMG.csv']);
                procEMG{level} = levelData;
                trigChans{level} = levelData(:,end);
                %Determine Peak Amplitudes of each channel across levels in order to
                %inform graph limits.
                totPkAmps = max(max(procEMG{level}),totPkAmps);
            catch
                cleanData = 0;
            end
        end
        
        %Here if this subject has had a problem, we simply continue to the
        %next subject.
        if(cleanData~=1)
            disp('This Subject was missing one or more CleanedEMG levels.')
            disp('Skipping this Subject and moving on to the Next.')
            continue
        end
        
        %Compare the Trigger channel to the timing list to determine the areas of
        %EMG to examine
        timingData = computeReachRegions(fileList, trigChans);
        
        %2 -- Determine Quietest 2 seconds of data across all EMG
        [quietSegAIEMG, quietSegSDIEMG, quietSegLims] = detQuietSeg(procEMG, binSize, winSize);
        
        %3 -- Allow for the review of the quietest segments
        if(askReview==1)
            revQSegs = questdlg('Would you like to review the detected Quiet Segments?',...
                'Evaluate Quiet Segments?','Yes','No','Yes');
        else
            revQSegs='No';
        end
        
        %Plot the locations of the quiet segment for manual verication
        if(strcmp(revQSegs,'Yes'))
            reviewQuietSegs(procEMG, quietSegLims, mergedHeaders(1:end-2));
        end
        
        %Save the quietSegAverage and the quietSegSD to disk
        
        quietDataOut = horzcat(num2cell(quietSegAIEMG), num2cell(quietSegSDIEMG), num2cell(quietSegLims));
        quietDataOut = horzcat(mergedHeaders(1:end-2)',quietDataOut);
        quietDataOut = vertcat({'Channel','Average Quiet IMEG','SD of Quiet IEMG','Start Quiet Seg (MS)','End Quiet Seg (MS)','Level QSeg Chosen From'},...
            quietDataOut);
        cell2csv([outpath '\Stats\QuietSegData.csv'], quietDataOut)
        
        %3 -- Normalize the Data
        %Here, the trials are separated and normalized according to the quietest
        %segment of EMG for each channel as determined in stage 4.10.
        [normData, procReachData] = normalizeEMG(procEMG,timingData,quietSegAIEMG,...
            normFactor, quietSegSDIEMG, binSize);
        
        %4 -- Save trial data into output location
        disp('Writing Normalized EMG Trials to Disk...')
        for level=1:size(normData,1)
            disp(['Processing ' levelText{level} ' data'])
            levelData = normData{level};
            for trial=1:size(levelData,1)
                outData = vertcat(mergedHeaders, num2cell(levelData{trial}));
                cell2csv([outpath levelText{level} 'ReachTrials\emgTrial' num2str(trial) '.csv'],...
                    outData);
            end
        end
        
        %4 -- Begin to look at Onsets and Offsets of Data
        disp('Calculating and Reviewing Muscle Onsets and Offsets')
        activationPairs=cell(size(normData,1),1);
        verificationOut = {'Support','TrialNum','Algorithm Accuracy'};
        %evaluationOut = cell(size(normData,1),1);
        
        
        %Ask the User if they'd like to review the performance of the onset picker.
        %This way, we only need to ask once.
        if(askReview==1)
            procVerification = questdlg('Would you like to evaluate the performance of the automated onset picker?',...
                'Evaluate Onset Correctness?','Yes','No','Yes');
        else
            procVerification = 'No';
        end
        
        for level=1:size(normData,1)
            trialNum = 1;
            lvTimeData = timingData{level};
            levelData = normData{level};
            lvReachData = procReachData{level};
            curLevActTimes = cell(size(levelData,1),1);
            curLevEvals = cell(size(levelData,1),1);
            for trial=1:size(levelData,1)
                
                %Placeholder for logic to selectively alter the headers and muscle
                %data based on what hand we're looking at.
                if(strcmp(lvTimeData{trial,5},'Left'))
                    analysisHeaders = mergedHeaders(aChans(2,:));
                    analysisData = levelData{trial};
                    reachData = lvReachData{trial};
                    analysisData = analysisData(:,aChans(2,:));
                    reachData = reachData(:,aChans(2,:));
                    reachPkAmps = totPkAmps(aChans(2,:));
                    tSpQSegs = normFactor * quietSegAIEMG(aChans(2,:));
                else
                    analysisHeaders = mergedHeaders(aChans(1,:));
                    analysisData = levelData{trial};
                    reachData = lvReachData{trial};
                    analysisData = analysisData(:,aChans(1,:));
                    reachData = reachData(:,aChans(1,:));
                    reachPkAmps = totPkAmps(aChans(1,:));
                    tSpQSegs = normFactor * quietSegAIEMG(aChans(1,:));
                end
                               
                %Okay, here we need to find a way to correct the time onsets for
                %the difference between EMG and OpenSHAPA so that things are synced
                %properly.
                
                %The strategy should consist of three stages.
                %1 -- Determine the onset times, in EMG time, of each Trial
                %2 -- Get the differences between OSHAPA onset times and the EMG
                %     Onset Times
                %3 -- Convert the reach onset times from OSHAPA to EMG time by
                %subtracting the differences
                
                [curLevActTimes{trial}, curVerf, curLevEvals{trial}]=...
                    activationDetection(analysisData, reachData, preEventLength, ...
                    binSize, actSize, deactSize, reachPkAmps, analysisHeaders, ...
                    tSpQSegs, ...
                    [levelText{level} '_Trial_' num2str(lvTimeData{trial,7}) '_Reach_' num2str(lvTimeData{trial,1}) '_' lvTimeData{trial,5} '_' lvTimeData{trial,6}],...
                    strcmp(procVerification,'Yes'));
                verificationOut = vertcat(verificationOut, {levelText{level}, num2str(lvTimeData{trial,1}), num2str(curVerf)});
                
                %Generate Graphics
                %Attempt at porting over adult graphing code.
                %Set 1 -- Setting Channel Graph Limits to the Peak Amplitude Across
                %Channels
                graphGroupEMGMV(reachData,analysisHeaders,binSize,preEventLength,...
                    curLevActTimes{trial},reachPkAmps,...
                    'totalPeak',...
                    [strrep(levelText{level},'\',''), '_Trial_' num2str(lvTimeData{trial,7}) '_Reach_' num2str(lvTimeData{trial,1}) '_' lvTimeData{trial,5} '_' lvTimeData{trial,6}],...
                    [outpath '\Graphs\']);
                
                %Set 2 -- Setting Channel Graph Limits to the peak of the
                %individual reach channels.
                graphGroupEMGMV(reachData,analysisHeaders,binSize,preEventLength,...
                    curLevActTimes{trial},0,...
                    'selfPeak',...
                    [strrep(levelText{level},'\',''), '_Trial_' num2str(lvTimeData{trial,7}) '_Reach_' num2str(lvTimeData{trial,1}) '_' lvTimeData{trial,5} '_' lvTimeData{trial,6}],...
                    [outpath '\Graphs\']);
                
                %5 -- Begin processing statistics
                
                metricChunk = ...
                    emgCalcReachMetrics(analysisData,curLevActTimes{trial},...
                    binSize,preEventLength,apaPreLength);
                
                %Build the Row Labels for this trial
                metLabs = cell(size(metricChunk,1),6);
                metLabs(1:end,1) = analysisHeaders';
                metLabs(1:end,2) = levelText(level);
                metLabs(1:end,3) = lvTimeData(trial,5);
                metLabs(1:end,4) = lvTimeData(trial,6);
                metLabs(1:end,5) = lvTimeData(trial,1);
                metLabs(1:end,6) = {trialNum};
                trialNum=trialNum+1;
                
                %Pair the Metric chunk to its muscle and reach identifiers
                metricChunk = horzcat(metLabs,num2cell(metricChunk));
                
                %Now append this onto the final output
                emgMetricOut = vertcat(emgMetricOut,metricChunk);
            end
            activationPairs{level} = curLevActTimes;
        end
        
        
        %% Co-Activation Metric Processing Section
        %
        %6/24/2014 -- Realization that these stats need to be separated into
        %successful and unsuccessful reaches
        coActTabOutput = {};
        for level=1:size(levelText,2)
            metricSubset = emgMetricOut(strcmp(emgMetricOut(:,2),levelText{level}),:);
            %Create output storage for the process
            %Columns -- Description, Num Co-Activations, Total Num Reaches
            coActChunk = cell(size(muscGroupings,2),4);
            coActChunk(:,2:4) = {0};
            outRow=1;
            %Explanation of numTrials logic --
            %metricSubset(:,4) yields the reach classification code for
            %each muscle in the EMG statistic subset.
            %ismember asks, for each classification code, is that code a
            %member of the set represented in succReaches
            %the result of this is a logical array, where 1 means a
            %successful reach, and 0 means unsuccessful.
            %The sum of this array, divided by the number of muscles (as
            %there is a 1 for each muscle in the successful reach), yields
            %the total number of successful reaches in the dataset.
            numTrials=sum(ismember(metricSubset(:,4),succReaches))/size(metricChunk,1);
            for pairs=1:size(muscGroupings,2)
                muscNames = mergedHeaders(muscGroupings{pairs});
                matchMuscs = zeros(size(metricSubset,1),1);
                %This loop goes over the names of the muscles in the muscle group,
                %regardless of number of names, and builds a logical addressing for
                %indexing the coActivation Matrix for the level.
                for musc=1:size(muscNames,2)
                    matchMuscs = or(matchMuscs,strcmp(metricSubset(:,1),muscNames(musc)));
                end
                coActSubset = metricSubset(matchMuscs,:);
                coActChunk(outRow,1) = {strjoin(muscNames,'+')};
                for subsect=1:size(muscNames,2):size(coActSubset,1)
                    %disp(['Current Event type is: ' coActSubset(subsect,4)])
                    if(ismember(coActSubset(subsect,4),succReaches))
                        %disp('Successful Reach detected, appropriately or not.')
                        %Grab the Onset times in the APA and CPA segments
                        apaOnsets = cell2mat(coActSubset(subsect:subsect+size(muscNames,2)-1,13));
                        cpaOnsets = cell2mat(coActSubset(subsect:subsect+size(muscNames,2)-1,15));
                        
                        %Determine if there are CoActivations
                        %Important Note -- combnk comes from the statistics toolbox,
                        %thereby making this code dependent on it.  I'll see about
                        %bundling it into our libraries.
                        apaCoActs = (abs(diff(combnk(apaOnsets,2),1,2))<=40);
                        cpaCoActs = (abs(diff(combnk(cpaOnsets,2),1,2))<=40);
                        
                        %APA Section
                        if(all(apaCoActs))
                            coActChunk(outRow,2) = {coActChunk{outRow,2}+1};
                        end
                        %CPA Section
                        if(all(cpaCoActs))
                            coActChunk(outRow,3) = {coActChunk{outRow,3}+1};
                        end
                        coActChunk(outRow,4) = {numTrials};
                    end
                end
                outRow=outRow+1;
            end
            coActTabOutput = vertcat(coActTabOutput,vertcat({levelText{level},'APA CoActs','CPA CoActs','Num Reaches'},coActChunk));
        end
        
        %% Write Outputs
        disp('Writing files and cleaning up.')
        %Verifications
        cell2csv([outpath '\Stats\GuiVerificationRating.csv'],...
            verificationOut);
        
        %Metrics
        cell2csv([outpath '\Stats\EMGMetricsByReach.csv'],emgMetricOut);
        
        %CoActivation Table.
        cell2csv([outpath '\Stats\EMGMetricsByLevel.csv'],coActTabOutput)
    end
else
    disp('No Directories Selected.  Exiting.')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%BETWEENLEVELSGRAPHS.M
%
%Script that generates EMG graphs where each channel is scaled to the peak
%activity of that channel across a group of subjects for each of their
%given levels of support.
%
%Author -- Wayne Manselle
%Date -- October 2014
%CHANGELOG -- 10.27.2014 -- Initial Creation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%Stage 0 -- Library and Constant Setup%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%See setupPath.m to ensure all paths are correctly set.
setupPath()

%Load all Subjects that are to be processed
%Select all folders of subject data to process kinematic stats for --
%returns 0 on a cancelled selection
foldersToProcess = uipickfiles();

%Specifying the bin time length is important to our calculations and
%plotting the graphs.  For ease, this is specified as a global variable,
%units are in ms
binSize = 10;

peakList = [];

%First pass, figure out the peak of peaks across subjects.
if(iscell(foldersToProcess))
    for procFolder=1:size(foldersToProcess,2)
        
        %We're gonna need to regenerate the file list on every run, so grab
        %that plus other subject specific data each time around.
        [fileList, levelText, topDir, curSubj] = CollectEMGFiles(foldersToProcess{procFolder});
        
        
        %For the very first folder, we need to seed some particulars so
        %that the rest of the processing can proceed.
        if(procFolder == 1)            
            [preEventLength, emgHeaders, keyMuscChans, mergeMuscChans, mergeBack,...
                aChans, muscGroupings, kinSampRate] = groupSpecificSetup(curSubj);
            
            if(mergeBack)
                mergedHeaders = mergeHeaders(emgHeaders,mergeMuscChans);
            else
                mergedHeaders = emgHeaders;
            end
            
            peakList = zeros(size(levelText,2),size(mergedHeaders,2));
        end
        
        disp(['Currently Processing: ' foldersToProcess{procFolder}])
        
        procEMG=cell(length(levelText),1);
        trigChans=cell(length(levelText),1);
        cleanData = 1;
        
        for level=1:size(levelText,2)
            
            %Load the Subject's Processed EMG data, isolate the reaches,
            %and then save that data back out to file for access later.
            try
                levelData = ...
                    csvread([foldersToProcess{procFolder} '\Output\EMG' levelText{level} 'FullTrials\CleanedEMG.csv']);
                procEMG{level} = levelData;
                trigChans{level} = levelData(:,end);
            catch
                cleanData = 0;
            end
            
            %Here if this subject has had a problem, we simply continue to the
            %next subject.
            if(cleanData~=1)
                disp('This Subject was missing one or more CleanedEMG levels.')
                disp('Skipping this Subject and moving on to the Next.')
                continue
            end
        end
        
        %Compare the Trigger channel to the timing list to determine the areas of
        %EMG to examine
        timingData = computeReachRegions(fileList, trigChans);
        
        for level=1:size(levelText,2)
            reachLocation = [foldersToProcess{procFolder} '\Output\EMG' levelText{level} 'ReachTrials\'];
            reachFiles = dir([reachLocation '*.csv']);
            
            curLevEMG = procEMG{level};
            curTiming = timingData{level};
            
            for reach=1:size(curTiming,1)
                %Determine any compenstory time lengths.  We did this
                %during the EMG Normalization phase to ensure all our bins
                %worked out.  Here we're going to do it to make sure all of
                %our EMG graphics work out.
                setLength = round(curTiming{reach,4})-round(curTiming{reach,2});
                compLen=(binSize-mod(setLength,binSize));
                
                if(curTiming{reach,4}+compLen<=(size(curLevEMG,1)))
                    emgProcessRegion = ...
                        curLevEMG(round(curTiming{reach,2}):round(curTiming{reach,4})+compLen,:);
                else
                    emgProcessRegion = ...
                        curLevEMG(round(curTiming{reach,2}):round(curTiming{reach,4}),:);
                end
                
                %Search for any new peaks
                peakList(level,:) = max(peakList(level,:),max(emgProcessRegion));
                
                %Save out the new Reach Trials
                csvwrite([reachLocation 'procEMG_Trial' num2str(curTiming{reach,7}) '_Reach_' num2str(curTiming{reach,1}) '_' curTiming{reach,5} '_' curTiming{reach,6} '.csv'],emgProcessRegion)
            end
        end
    end
end

%Second pass, figure out the peak of peaks across subjects.
if(iscell(foldersToProcess))
    for procFolder=1:size(foldersToProcess,2)
        
        %Gonna need a few things to make these graphs happen.
        %reachData -- We need the specific muscular data to be graphed.
        %analysisHeaders -- the names of the channels to be graphed
        %binSize -- the size of the EMG bins used
        %preEventLength -- the amount of preEvent Data for the subject
        %curLevActTimes -- the times the muscle was activated for this
        %reach
        %reachPkAmps -- the Peak amplitudes for the reach
        %Graph Title
        %Graph Output location
        
        %Total Sum of all Reach Metrics for this subject.
        emgMetrics = readtext2([foldersToProcess{procFolder} '\Output\EMG\Stats\EMGMetricsByReach.csv'],',','','');
        
        graphOutpath = [foldersToProcess{procFolder} '\Output\EMG\Graphs\'];
        
        for level=1:size(levelText,2)
            
            %Separate out the level specific chunk of the EMG Metric file
            levelRows = find(strcmp(emgMetrics(:,2),levelText{level}));
            
            levelMetrics = emgMetrics(levelRows,:);
            
            %Load the Subject's EMG data files, one at a time, for all the
            %reaches they used.
            reachLocation = [foldersToProcess{procFolder} '\Output\EMG' levelText{level} 'ReachTrials\'];
            reachFiles = dir([reachLocation 'procEMG*.csv']);
            
            for reach=1:size(reachFiles,1)
                %Grab the beginning activation times
                activationTimes = levelMetrics(cell2mat(levelMetrics(:,6))==reach,13:16);
                
                %Now they need to be re-formatted into the way they would
                %have appeared
                curActivations = cell(1,size(mergedHeaders,2));
                %I've commented this out for now.  In the event onsets and
                %offsets need to be plotted in the future, this code is a
                %springing off point.
                
%                 for row=1:size(activationTimes,1)
%                    apaOn = (activationTimes{row,1}+preEventLength)/binSize;
%                    apaOff = (activationTimes{row,2}+preEventLength)/binSize;
%                    cpaOn = (activationTimes{row,3}+preEventLength)/binSize;
%                    cpaOff = (activationTimes{row,4}+preEventLength)/binSize;
% %                     The graph generation program seems to have assumed
% %                     times were in bins, rather than ms, so we have to
% %                     convert them back for graphical purposes
%                    actAddition = [];
%                    if(~isnan(apaOn))
%                        actAddition = vertcat(actAddition,[apaOn apaOff]);
%                    end
%                    if(~isnan(cpaOn))
%                        actAddition = vertcat(actAddition,[cpaOn,cpaOff]);
%                    end
%                    curActivations{row} = actAddition;
%                 end
                
                graphName = [strrep(levelText{level},'\',''), '_BetweenSubjectsWithinLevel' reachFiles(reach).name(8:end-4)];
                
                curEMG = csvread([reachLocation reachFiles(reach).name],1,0);
                
                %Graphs -- The array indexing done on the variables here is
                %so we're not attempting to plot the heartbeat or trigger
                %channels, which are empty anyway.
                
                graphGroupEMGMV(curEMG(:,1:end-2),mergedHeaders(1:end-2),binSize,preEventLength,...
                    curActivations,peakList(level,:),...
                    'betweenPeak',graphName,graphOutpath);
            end
            
        end
        
    end
end
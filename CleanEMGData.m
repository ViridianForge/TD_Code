%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CLEANEMGDATA.M -- This script contains all the steps and interaction necessary
%to filter and clean the EMG, including removing any detected EKG based on
%user input.
%
%Author -- Wayne Manselle
%Date -- April 2014
%Changelog -- Initial Split from ProcessEMGData.m
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%Stage 0 -- Library and Constant Setup%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%See setupPath.m to ensure all paths are correctly set.
setupPath()

sampRate=1000;

%Get the list of all subject files that need processing.
[fileList, levelText, topDir, curSubj] = CollectEMGFiles();

%Error safety check.  If the user presses cancel or something.
if(topDir==0)
    disp('No files found for subject.  Please review their data directory.')
    return
end

%Begin setting up constants for file output.  Headers and whatnot.
buildOutputDirectories(topDir, levelText);

%Set all the Output paths.
outpath = [topDir '\Output\EMG\'];

%Study group specific setup variables.  Based on the subject string given,
%method will return the preEvent time to examine, and EMG channels to
%examine for the group that subject belongs to.
[preEventLength, emgHeaders, keyMuscChans, mergeMuscChans, mergeBack,...
    aChans, muscGroupings, kinSampRate] = groupSpecificSetup(curSubj);

for level=1:length(levelText)
    
    %1 -- Check output dir for level.  If the level has output, ask the
    %user if they wish to rerun the level.
    if(exist([outpath levelText{level} 'FullTrials\CleanedEMG.csv'],'file'))
        procLevel = questdlg(['The ' levelText{level} ' level has been run before.  Would you like to process it again?'],...
            'Reprocess Level?','Yes','No','Yes');
        if(strcmp(procLevel,'No'))
            continue
        end
    end
    
    %%%%Stage 4 -- Process EMG Data%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    disp(['Beginning EMG processing at ' levelText{level} ' level.'])
    emgRawData = fileList{level,5};
    %4.1 -- Pull in raw EMG data
    [rawEMGData] = csvread(emgRawData,3,0);
    
    %4.2 -- EMG Gains used in Collection
    gains = readGains(fileList{level,6});
    
    %4.3 -- Adjust the data for the gains.
    disp('Adjusting EMG Gains...')
    adjEMGData = emgGainAdjust(rawEMGData,gains);
    
    %4.3 -- Give user the option to observe the Amplitude v. Frequency
    %domain of the data.
    faReview = questdlg('Would you like to review EMG Signal in Frequency Domain?','Examine Frequency Domain','Yes','No','Yes');
    if(strcmp(faReview,'Yes'))
        fftRawData = zeros(size(adjEMGData));
        amp_spec = zeros(size(adjEMGData));
        abscVW = zeros(size(adjEMGData));
        for chans = 1:size(adjEMGData,2)-2
            fftRawData(:,chans) = fft(adjEMGData(:,chans)*1000);
            cmplxConj = size(adjEMGData(:,chans),1)/2;
            amp_spec(:,chans) = abs(fftRawData(:,chans))/cmplxConj;
            abscVW(:,chans) = (0:size(fftRawData,1)-1)/(2*cmplxConj*(1/sampRate));
        end
        visMultChans(abscVW, amp_spec(1:size(fftRawData,1),:), emgHeaders(1:end-2),...
            'Frequency Domain (Hz)', 'Amplitude', 'EMG Signal in Frequency Domain',...
            0:20:(sampRate/2))
    end 
    
    %4.4 -- De-Noise the Data
    disp('Removing Magnetic Noise from Data...')
    deNoisedEMG = filtNoiseHarmonics(adjEMGData,1000,84,4,emgHeaders);
           
    %4.5 -- Calculate and selectively remove EKG the average EKG present.
    disp('Starting EKG Subtraction Decider...')
    [selHBEMG, subHBEMG] = emgFiltAvgEKG(deNoisedEMG, deNoisedEMG(:,end-1), emgHeaders);
    
    %4.6 -- Perform EMG Filtration, currently using a methodology based on
    %Leonard and Julia's paper <paper title>
    disp('Beginning EMG Filtration...')
    %[smoothedEMG, filteredEMG] = emgTKEOSmooth(selHBEMG,emgHeaders);
    smoothedEMG = emgSmoothProcess(selHBEMG,emgHeaders);
       
    %4.9 -- Merge any Muscles Requiring Merging
    disp('Merging Selected EMG Channels')
    if(mergeBack)
        [emgMerged, emgProcHeaders] = ...
            mergeMuscs(smoothedEMG,mergeMuscChans,emgHeaders);
    else
        emgMerged = smoothedEMG;
        emgProcHeaders = emgHeaders;
    end
    
    %4.10 -- Convert everything from V into mV
    emgMerged = emgMerged * 1000;
    
    disp('Saving cleaned EMG for this level to disk.')
    csvwrite([outpath levelText{level} 'FullTrials\CleanedEMG.csv'],emgMerged)
        
    %%%%First Portion of Processing%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
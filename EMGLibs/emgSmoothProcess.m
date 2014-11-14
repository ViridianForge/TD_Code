function [ smoothedEMG ] = emgSmoothProcess( emgData, titles )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%SMOOTHEDEMG Smooth and Filter EMG to Specifications
%   This function smoothes and filters the EMG data given to the
%   specification laid out by Gonzalez and Rachwani for the purposes of
%   analyzing their TD and CP EMG data.
%
%   This process is adapted from Thielen and Spencer:
%   1 -- Filter with a 4th Order Butterworth Bandpass Filter (10-160Hz)
%   2 -- Perform Full Wave Rectification of the Data
%   3 -- Boxcar Average of Data
%
%Author - Wayne Manselle - April 2014
%INPUTS -- emgData - the EMG data to be smoothed.
%          titles - Channel Titles for data reviewing purposes
%
%OUTPUTS -- smoothedEMG - the EMG data after smoothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

bandPassFiltData = zeros(size(emgData));
rectFiltData = zeros(size(emgData));
boxCarData = zeros(size(emgData));

% Butterworth filter specifications 
nyquist=1000/2;
[bBP,aBP]=butter(4,[10 160]/nyquist,'bandpass');

%Thielen and Spencer methodology
for chans=1:size(emgData,2)-2
    %Step 1 -- Filter Data
    bandPassFiltData(:,chans) = filtfilt(bBP,aBP,emgData(:,chans));

    %Step 2 -- Rectify the Data
    rectFiltData(:,chans) = abs(bandPassFiltData(:,chans));
    
    %Step 3 -- Boxcar Average the Data
    boxCarData(:,chans) = fastsmooth(rectFiltData(:,chans),7,1);
end

%Set output variable
smoothedEMG = boxCarData;

%Possible Step 3 -- Welch Power Analysis
wReview = questdlg('Would you like to look at the power analysis of the Data?','Examine Power Analysis?','Yes','No','Yes');

if(strcmp(wReview,'Yes'))
    %Hackery to preallocate the proper window size
    nfft = max(256,2^nextpow2(size(emgData,1)/8));
    %Removing the /2 here to account for the 50% window overlap
    windowSize = ift(mod(nfft,2)==0,(nfft+1),(nfft+1));
    pxxNoFilt=zeros(windowSize,size(emgData,2)-2);
    pxxFilt=zeros(windowSize,size(emgData,2)-2);
    freqVec = 0;
    for chans=1:size(emgData,2)-2
        [pxxNoFilt(:,chans), freqVec] = pwelch(emgData(:,chans),[],[],[],2*nyquist,'onesided');
        pxxNoFilt(:,chans) = 10*log10(pxxNoFilt(:,chans));
        pxxFilt(:,chans) = 10*log10(pwelch(bandPassFiltData(:,chans),[],[],[],2*nyquist,'onesided'));
    end
    xTicks = 0:nyquist/10:nyquist;
    %Compare the power spectrums of the unfiltered to the filtered data
    visualComparison(pxxNoFilt,pxxFilt,...
        'Pre-Filtered EMG','Filtered EMG 10-160Hz',titles(1:end-2),...
        freqVec,'Frequency (Hz)','Power (dB/Hz)',...
        [0 nyquist],0:nyquist/10:nyquist)
end

%Possible Step 4 -- Remove Isolated Peaks

%Give user option of reviewing TKEO v. Un-TKEO'd Data
review = questdlg('Review EMG Filtration?','Would you like to review?','Yes','No','Yes');

%Create a Series of Plots to allow the user to observe the effects of TKEO
%Smoothing.
if(strcmp(review,'Yes'))
    visualComparison(emgData,smoothedEMG,...
        'Pre-Filtered EMG','Filtered EMG 10-160Hz, Rectified, Boxcar Averaged',...
        titles(1:end-2),1:size(emgData,1),'Time (s)','Amplitude (V)',...
        [0 size(emgData,1)-1],0:round((size(emgData,1)/1000)/10):(size(emgData,1)-1)/1000)
end

%Replace the Heart Beat and Trigger Channels with their unaltered values.
smoothedEMG(:,size(emgData,2)-1) = emgData(1:end,size(emgData,2)-1);
smoothedEMG(:,size(emgData,2)) = emgData(1:end,size(emgData,2));
end
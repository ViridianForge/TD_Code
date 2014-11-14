function [ selHBEMG, subHBEMG ] = ...
    emgFiltAvgEKG( emgData, filtEKG, titles )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%EMGDUALTHRESHEKGCALC Summary of this function goes here
%   Detailed explanation goes here
%   Author -- Wayne Manselle -- Dec 2012
%           - Wayne Manselle and Sandy Saavedra -- Sep 2009
%   INPUTS -- emgData - emgData to be scanned for Heart Beat Influence
%          -- polarity - the polarity of the HB Channel
%   OUTPUTS -- hbChanCalcs - the average HB channel data per EMG channel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Seed Value
selHBEMG=-1;

%Maybe Pick between the subtractable waveforms here?
while(selHBEMG==-1)
    %Identify Threshold and Polarity of EKG Signal
    threshold = hbThresholdClassifier(filtEKG);
    
    subWaveForm = calcAvgEKGByChan(emgData,threshold);
    %Make the HB Subtracted Versions of the Data
    subHBEMG = emgData - subWaveForm;
    
    %Attempt to Select the Heartbeat
    selHBEMG = groupEMGWaveComparison(emgData, subHBEMG, subWaveForm, titles);
end
end
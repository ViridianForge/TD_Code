function [ subWaveForm ] = calcAvgEKGByChan( emgData, threshold )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CALCAVGEKGBYCHAN - Calculates the average EKG present in each channel
%   This function, using channels of EMG data and an activation threshold,
%   finds all PQRST waveforms present in the EMG Data, and then averages
%   them into an average EKG waveform present in that channel.
%
%   Author: Wayne Manselle - February 2014
%           Sandy Saavedra - Author of basis code
%
%   INPUTS: emgData - the EMG to be analyzed for EKG waveforms
%           threshold - the Threshold of EKG activity
%   OUTPUTS: subWaveForm - the collection of averaged EKG waveforms from
%                          the EMG data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Get the number of channels in the EMG.
[rows,chans]=size(emgData);
demeanedEMG = zeros(rows,chans);

%Step through the channels of EMG, demeaning each non-trigger channel.
%The trigger channel is presumed to be the last channel in the data
%set.
for chn=1:chans-1
    demeanedEMG(:,chn) = emgData(:,chn)-mean(emgData(:,chn));
end
%transfer the trigger channel, just in case we need it.
demeanedEMG(:,chans) = emgData(:,chans);

HBC=demeanedEMG(:,chans-1);

%Calculate the Peak List

[RPeakList, qrsLens] = buildPeakList(HBC,threshold);

%with the first draft of the PQRST waveforms assembled it's time to check
%them against some heuristics.

%Heuristic 1:  Amplitude Regularity
%The heartbeat should follow a regular wave amplitude, assuming electrode
%connections stay solid through a collection.  If the amplitude goes too
%far away from our accepted average, that RPeak and corresponding P-T
%interval should be tossed.

RAmplitudes = zeros(length(RPeakList),1);

for pks=1:length(RAmplitudes)
    RAmplitudes(pks) = HBC(RPeakList(pks));
end

RAverageAmplitude = abs(mean(RAmplitudes));
RStDevAmplitude = abs(std(RAmplitudes));

TempRPeakList = [];
%TempQPeakList = [];
for pks=1:length(RPeakList)
    if (~(abs(HBC(RPeakList(pks))) > (RAverageAmplitude+2*RStDevAmplitude)))
        TempRPeakList = [TempRPeakList RPeakList(pks)];
    end
end

RPeakList = TempRPeakList;

%%%End Heuristic 1%%%

%Due to MATLAB requirements of integer indices, if we have an odd QRS
%length maximum, add one so we have even side lengths.
%
%Author Note:  I debated a lot on how to approach this situation.  I
%elected to avoid an extra data point rather than shift the window at all
%because we lack sufficient knowledge to know how best to favour the window
%shift to the left or right.  That and I'm sure it'd make all sorts of
%headaches in processing the data.
MaxQRSLength = max(qrsLens)-mod(max(qrsLens),2);

%% Averaging Code

%Determine the side lengths to explore to determine the PQRST Wave.
RSideLength=(MaxQRSLength/2)+20;

%Use the Max Length determined above of the QRS waveforms, and add 20MS
%further on each side to capture P and T.
PQRSTWaveMatrix = zeros(length(RPeakList),MaxQRSLength+41,chans-1);

%Step through all the RPeaks to grab the PQRST waves for each channel 
for nmChan=1:chans-1
    for pks=1:length(RPeakList)
        if RPeakList(pks)<= 30
            pks=pks+1;
        end
        if RPeakList(pks)<=length(HBC)-RSideLength
            PQRSTWaveMatrix(pks,:,nmChan) = demeanedEMG((RPeakList(pks)-RSideLength):(RPeakList(pks)+RSideLength),nmChan)';
        end
    end
end

%Average the QRS waves into one QRS Wave
AveragePQRSTWave=zeros(MaxQRSLength+41,chans-1);

for nmChan=1:chans-1
    AveragePQRSTWave(:,nmChan) = mean(PQRSTWaveMatrix(:,:,nmChan));
end

subWaveForm=zeros(size(emgData));

%Assemble Subtractable Waves
for chNm=1:chans-1
    %RPeaks
    for j=1:length(RPeakList)
        if RPeakList(j)<= 30
            j=j+1;
        end
        subWaveForm((RPeakList(j) - RSideLength):(RPeakList(j) + RSideLength),chNm) = AveragePQRSTWave(:,chNm);
    end
end
end
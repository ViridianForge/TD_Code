function [ adjEMGData ] = emgGainAdjust(rawEMG, gains)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%emgGainAdjust adjusts EMG data using the given gains
%   This function quickly adjusts the given set of raw EMG data for the
%   gain settings it was collected at.  This function is written with
%   Motion Labs MA300 system in mind.
%
%   Author: Wayne Manselle -- December 2012
%
%   INPUTS -- rawEMG -- a matrix of rawEMG data
%             gains -- a matrix of gains, assumed to correspond to each
%             channel of data in the rawEMG matrix
%   OUTPUT -- adjEMGData -- the gain adjusted EMG data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Prepare the output Matrix
adjEMGData=zeros(size(rawEMG));

%Set up reference Matrix of Gain Settings
%TODO -- Link to reference for these values
gainMat=[350,2000,4000,5700,8000,9500,11500,13200,16600,18000];

%Loop of over the set gains.  Author is presuming that there won't be a
%gain channel setting for the trigger channel, as it is not connected to
%the box.
%NOTE -- We'll have to check the ordering of things.  If the trigger gets
%between the muscles and the heart beat, we'll have to get creative.
for chan=1:length(gains)
    %The prescribed adjustment is to multiple the data by the gain channel
    %setting, and then dividing by 18000.  If the gain setting is 9, this
    %is effectively multiplying by 1.
    adjEMGData(:,chan) = rawEMG(:,chan).*(gainMat(gains(chan))/18000);
end
%Make sure the trigger channel is copied over.
adjEMGData(:,end) = rawEMG(:,end);

end
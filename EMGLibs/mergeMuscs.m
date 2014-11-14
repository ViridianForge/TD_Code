function [ mergedEMG, mergedHeaders ] = ...
    mergeMuscs( tkeoEMG, mergeChans, emgHeaders)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%MERGEMUSCCHANS Merges specified channels of EMG data and corrects headers
%   This function takes TKEO and Smoothed EMG data, the channels specified
%   in mergeChans have their data merged by summing, and their respective
%   headers corrected to reflect the merged datasets.
%
% Author: Wayne Manselle - November 2013
%
% INPUTS: tkeoEMG - The TKEO and Smoothed Full EMG Dataset
%         mergeChans - The Addresses of Muscle Channels to Merge
%         emgHeader - The Unaltered EMG Headers
%         cullArms - Whether this subject is having arm data culled
%
% OUTPUTS: mergedEMG - The Full EMG Data with specified channels merged
%          mergedHeaders - The matching headers for the above.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mergedHeaders = mergeHeaders(emgHeaders,mergeChans);
mergedEMG = tkeoEMG;

for ind=1:size(mergeChans,2)
    chans = mergeChans(:,ind);
    opData = horzcat(mergedEMG(:,chans(1)),mergedEMG(:,chans(2)));
    mergedEMG(:,chans(1)) = mergeChannels(opData);
    mergedEMG(:,chans(2)) = NaN;
end

mergedEMG(:,isnan(mergedEMG(1,:))) = [];
end
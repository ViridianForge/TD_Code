function [ mergedData ] = mergeChannels( dataChans )
%MERGECHANNELS Sums an arbitrary number of EMG Channels
%   This function replicates Dr. Sandy Saavedra's strategy to do merged
%   muscle analysis, but extends it by not limiting the maximum number of
%   channels that can be merged.  This merging is accomplished by summing
%   the values of the channels into one output.
%
%   This function assumes that dataChans is not a sparse array, and that
%   the data submitted to it is mergeable.
%
%AUTHOR: Wayne Manselle -- October 2013
%
%INPUTS: dataChans -- The EMG data to be merged
%
%OUTPUTS: mergedData -- The merged EMG data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mergedData = sum(dataChans,2);
end
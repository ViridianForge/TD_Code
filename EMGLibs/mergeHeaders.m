function [ mergedHeaders ] = mergeHeaders(header,mergeChans)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%MERGEHEADERS Returns a set of EMG Headers reflecting merged channels
%   This function, given a set of headers and a list of channels to merge
%   returns a shorter set of headers whose names reflect the merged names.
%
%   Author:  Wayne Manselle - November 2013
%
%   INPUTS:  header - the original headers
%            mergeChans - the channels needing to be merged
%            cullArms - flag to whittle down arm headers
%
%   OUTPUTS: mergedHeaders - the headers after selected header titles are
%                            merged.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mergedHeaders = header;

for ind=1:size(mergeChans,2)
    chans = mergeChans(:,ind);
    %Fix up the EMG Headers
    newHeader = mergedHeaders{chans(1)};
    mergedHeaders{chans(1)} = ['merg' newHeader(2:end)];
    mergedHeaders{chans(2)} = '';
end

mergedHeaders(strcmp(mergedHeaders(:),'')) = [];
end
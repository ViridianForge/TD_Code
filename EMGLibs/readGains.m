function [ gains ] = readGains( gainFile )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%READGAINS Reads EMG gains from file of gain data.
%Read in the Gain Data, pull out the second column (presumably the gains),
%covert to a numerical column, and then invert so we have it in Row
%Notation.
%   
%  Author -- Wayne Manselle - February 2013
%
%  INPUTS -- gainFile - file name of the location of the gain data.
%
%  OUTPUTS -- gains - the vector of the gains used for the given subject.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rawGainData = readtext2(gainFile,',','','');
gains = cell2mat(rawGainData(2:end,2))';
%All gains have to be incremented by one.
%Gains are 0-indexed.  MATLAB vectors are 1-indexed.
gains = gains+1;
%Tack on the 'gain' for the Trigger channel.
gains = horzcat(gains, 10);
end
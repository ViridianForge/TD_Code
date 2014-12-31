%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%GENERATEKINETICS.M
%
%This script uses the
%
%The script is currently specifically devoted to getting the kinetics of
%the trunk and head segments of the selected subjects.
%
%This script requires an output file from the GenerateSegmentLengths script
%that will be selected by the user.  The script tests the file for presence
%of a subject weight column, and if it isn't present, will query the
%script's user for the weight of each subject.
%
%The script also requires access to the trial by trial kinematic files for
%each subject as they're processed.
%
%This script uses the segment derivation table as defined by <> to
%determine the various blah-de-blahs
%
%Finally, using inverse dynamics, the script generates the 
%
%Author -- Wayne Manselle
%Date -- December 2014
%CHANGELOG -- 12.16.2014 -- Initial Creation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
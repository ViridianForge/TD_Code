function [ kinTrialData, rotTrialData, markData, rpiHead, bosData,...
                maxHdHt, maxTkHt, rpiTrunk, fDataLineOverTime ] = ...
                procGKFFile( kinRawData, markAnysFunc )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%PROCOKLAHOMAFILE Wrapper for processing General Kinematic Format Bird Data
%   This function wraps the neccessary steps to read in raw kinematic data
%   that is in the GKF scheme.
%
%Author: Wayne Manselle
%Creation Date: November 2014
%
%Inputs:
%       kinRawData -- Filename of the raw Oklahoma Formatted file to read
%       in.
%       markAnysFunc -- Mark Analysis Function to use
%
%Outputs: 
%       trialData -- Cell Array of Trial Data
%       rotMData -- Cell Array of Rotational Matrices by Trial
%       markData -- Data relevant to the marks collected around a 
%                      subject on the outset of data collection.
%       rpiMat -- Matrix of RPI data
%       bosMat -- Base of Support Data
%       maxHdHt -- The highest point the Head was at, converted to CM and
%                     filtered.
%       maxTkHt -- The highest point C7 was at, converted to CM and filtered.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[kinTrialData, rotTrialData, markData, metaData] = ...
    GeneralKinematicDataConverter(kinRawData,1,1,markAnysFunc);

%Since the Kinematic Trial Data that is read in from a GKF file doesn't
%necessarily have the expected trial and notes columns as present in the
%Oklahoma era files
for kinTrial = 1:size(kinTrialData,1)
    origTrial = kinTrialData{kinTrial};
    buffer = zeros(size(origTrial,1),1);
    kinTrialData(kinTrial) = {horzcat(buffer, origTrial, buffer)};
end

%The GKDC will use the passed Mark Analysis function in order to generate
%the RPI and BOS data.
rpiHead = metaData{1};
rpiTrunk = metaData{2};
bosData = metaData{3};
maxHdHt = metaData{4};
maxTkHt = metaData{5};

%I believe this was a diagnostic output variable from the Oklahoma format's
%legacy systems.  This may be removable in future releases.
fDataLineOverTime = 0;
end
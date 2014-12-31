function [ kinTrialData, rotTrialData, markData, rpiData, bosData,...
    maxHdHt, maxTkHt, rpiTrunk, fDataLineOverTime ] = procOklahomaFile( kinRawData )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%PROCOKLAHOMAFILE Wrapper for processing Oklahoma Formatted Bird Data
%   This function wraps the neccessary steps to read in raw kinematic data
%   that is in the Oklahoma Formatting scheme.  The markData and bosData
%   from the read is then converted into centimeres from inches as per
%   the standard convention established for the project.
%
%Author: Wayne Manselle
%Creation Date: November 2014
%
%Inputs:
%       kinRawData -- Filename of the raw Oklahoma Formatted file to read
%       in.
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
%       maxC7Ht -- The highest point C7 was at, converted to CM and filtered.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%The Matrices here are:
%Mat 1 -- An arrangement of cells, each cell containing a given trial's
%kinematic data.
%Mat 2 -- Mark Data
%Mat 3 -- rpi Data
%Mat 4 -- Base of Support Data

[kinTrialData,rotTrialData, markData,rpiData,bosData, maxHdHt,...
    maxTkHt, rpiTrunk, fDataLineOverTime] = FranEraBirdConverter(kinRawData);

%Run the mark conversion appropriate for this data set

end
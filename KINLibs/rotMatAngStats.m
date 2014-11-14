function [ statTable ] = rotMatAngStats( gammaAngs, betaAngs, alphaAngs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ROTMATANGSTATS Calculates the statistical analysis of a 3DRotMat
%   This function calculates the statistical measures requested by Jennifer
%   Rachwani and Victor Santamaria-Gonzalez for the purpose of data
%   analysis for the TD/CP Study.
%
%   The statistical measures current produced by this function are as
%   follows for each of the three angles (gamma, beta and alpha):
%   1 -- Min of Angles
%   2 -- Max of Angles
%   3 -- Mean of Angles
%   4 -- Standard Deviation of Angles
%   5 -- Standard Deviation of Absolute Angular Distribution
%   6 -- Angular Path Length of Event
%   7 -- Angular Range of Motion of Event
%
%   Author -- Wayne Manselle - June 2014
%
%   ChangeLog -- 06.13.2014 -- Initial Creation
%
%   INPUTS -- gammaAngs -- the array of event-related angle data for Gamma
%             betaAngs -- the array of event-related angle data for Beta
%             alphaAngs -- the array of event-related angle data for Alpha
%
%   OUTPUTS -- statTable -- The table of stats for these metrics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

statTable = zeros(1,21);

%Put the three input arguments together for ease of 
angProc = {gammaAngs,betaAngs,alphaAngs};

for angGrp = 1:3
    
    %The angular displacement between each data point to be used in stats.
    angDiff = diff(angProc{angGrp});
    
    statTable((7*(angGrp-1))+1)=min(angProc{angGrp});
    statTable((7*(angGrp-1))+2)=max(angProc{angGrp});
    statTable((7*(angGrp-1))+3)=mean(angProc{angGrp});
    statTable((7*(angGrp-1))+4)=std(angProc{angGrp});
    statTable((7*(angGrp-1))+5)=std(abs(angProc{angGrp}));
    statTable((7*(angGrp-1))+6)=sum(abs(angDiff));
    statTable((7*(angGrp-1))+7)=max(angProc{angGrp})-min(angProc{angGrp});
    
end
end
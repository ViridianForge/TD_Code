function [njs] = normalizedJerkSquared(pos, dT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%MEANSQUAREDJERK Returns the normalized-jerk squared of resultant position 
%   data.
%   Given an array of resultant position data, this function will find the
%   third derivitive of said data, and utilize Chang's NJS equation to
%   return the normalized Jerk Squared of said data.
%
%   NJS is defined as:
%   ((1/2)*Integral(jerk^2)*(time^5/amp^2))
%   Ref - Chang, Wu, Wu and Su - Kinematical measure for spastic reaching
%   in children with cerebral palsy - 2005
%   
%   Author - Wayne Manselle - December 2013
%   Version 0.1 - Created
%   Version 0.2 - Modified from Rigolodi's MSJ to utilize Chang's 
%   Normalized Jerk Squared algorithm and file renamed to match -March 2014
%
%   INPUTS - pos - Array of resultant position difference.
%            dT - The delta T of the position data in milliseconds
%
%   OUTPUTS - njs - The Mean-Squared Jerk of the dataset
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Build jerk of resultant position
resJerk = (diff(diff(pos./dT)./dT)./dT);
time = length(pos)*dT;

pathLen = sum(pos);

%Calculate Normalized Jerk Squared
njs = sqrt(0.5*(trapz(resJerk.^2)*dT)*(time^5/pathLen^2));
end
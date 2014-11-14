function [result] = kinExtentFlexExt(angularPos, mode)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%kinExtentFlexExt -- Returns a specialized min or max calculation for the
%given angular Position data that is respective of extension of flexion.
%
%This program, for the given angular position data, determines the location
%of the minimum or maximum angular position, regardless of whether that
%angular is from extension or flexion.  The value returned retains
%information related to whether the angle is extension or flexion.
%The value's sign will determine directionality of movement depending on
%the plane the data given was collected in.
%
%Author: Wayne Manselle -- June 2013
%
%INPUTS -- angularPos - the Angular Position Data to be searched
%          mode - 0 for min search, 1 for max search
%
%OUTPUTS -- result - the value found in the search
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Initialize index storage
ind=NaN;

%Determine index of flexion or extension extent extreme depending on mode.
%In the event that a subject has an equal flexion and extension, the search
%will return the first value it comes across.
if(mode)
  [val, ind] = max(abs(angularPos));
else
  [val, ind] = min(abs(angularPos));  
end

%Return the signed angular position if it exists, NaN otherwise.
if(~isnan(ind))
    result = angularPos(ind);
else
    result=NaN;
end

end
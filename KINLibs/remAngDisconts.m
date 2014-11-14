function [ corrRepAngs ] = remAngDisconts( angles )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%remAngDisconts - removes angular discontinuities from the passed data
%   This function repairs discontinuities in the passed angular data by
%   checking for the directionality of angular movement, and continuing the
%   movement to suit.
%
%   Here are the rough notes about the general idea.
%   The function takes in an array of angular motion data
%   By default, thanks to atan2, our value ranges will be 0->pi and 0->-pi
%   Step 1 --> correct the data such that our range is 0->2pi
%   This results in another discontinuity when the motion is from the first
%   quadrant to the fourth (90->0->-90 becomes 90->0->270)
%   Step 2 --> correct this new discontinuity by detecting regions with crazy
%   large slopes by using first derivative, find the bordered regions, and
%   subtract 2pi from them, returning them to their original uncorrected
%   value
%   Step 3 --> convert all this stuff to degrees.
%
%Author: Wayne Manselle - June 2014
%
%INPUTS - angles - the array of angular data to be corrected
%OUTPUTS - corrRepAngs - the array of "repaired", corrected and filtered angular data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Get inflection points of angles

%Use directionality of movement to determine how to approach situation

repAngs = zeros(size(angles));

%Step 1 --> Convert range from 0->2pi
%Coming in, the angles are represented as 0-180 degrees, and -181 to -359
%degrees.  We multiply the latter set of angles by negative 1 to produce a
%continuous unit circle of 0 to 359 degrees.
for dtPt=1:size(angles,1)
    repAngs(dtPt) = ift(sign(angles(dtPt))<0,-1*angles(dtPt),angles(dtPt));
end

%Step 2 --> Reference the entire set of angles to the angular position of
%the subject in the first frame of the trail
startAngPos = repAngs(1);
for dtPt=1:size(angles,1)
    repAngs(dtPt) = repAngs(dtPt) - startAngPos;
end

%Step 2 --> Correct Quadrant I-IV motion discontinuties introduced

%Indicator of correction Mode. 
%+1 Means we've observed an upward discontinuity -- this is indicative that
%we've moved from 0 radians downward %to 2pi-1
%-1 Means we've observed a downward discontinuity -- this is indicative 
%that we've moved from 2pi-1 radians %upward to 0.
corrMode = 0;
corrRepAngs = zeros(size(repAngs));
corrRepAngs(1) = repAngs(1);

%The general idea here -- Take a single swipe through the given set of 
%angles.  With every discontinuity encountered, we'll move into a 
%correction state.  When the object's angular movement has the opposite 
%discontinuity, we'll move out of that correction state.
%
%i.e. The head moves below 0 radians, we enter the -1 correction state until the head comes back up from below 0 %radians.
for pdl = 2:size(repAngs,1)
    %disp('Current Difference Between Points')
    curDiff = repAngs(pdl) - repAngs(pdl-1);
    if(abs(curDiff) > 3.5)
        corrMode = corrMode + sign(curDiff);        
    end
    
    %Correct the discontinuity by adding or subtracting 2pi based on the correction mode
    corrRepAngs(pdl) = repAngs(pdl) - (2*pi*corrMode);
end

%Convert the angles from Radians to Degrees
corrRepAngs=corrRepAngs*57.2957795;

%Filter the data with a 4th Order Butterworth Filter at 6Hz.
nyquist = 84/2;
[b,a]=butter(4,(6/nyquist));
corrRepAngs = filtfilt(b,a,corrRepAngs);
end
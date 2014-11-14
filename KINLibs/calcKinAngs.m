function [ hdC7Angs, tkCBOSAngs ] = calcKinAngs(kinEventData)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CALCKINANGS Calculates Angular Displacement for the Kinematic Event
%   This function operates on a given set of Event-Related Kinematic Data,
%   and its associated subject Base of Support data to return a set of
%   angles between both the subject's Head and C7, and C7 and Base of
%   Support.
%
%AUTHOR: Wayne Manselle -- December 2012
%
%CHANGELOG:  
%01.22.2014 -- Discovery of double-using CBOS subtraction
%inappropriately.  BOS no longer needed as an input to function, and thus,
%removed.
%
%INPUTS: kinEventData - The Event-Related Kinematic Data to be Processed
%
%OUTPUTS: hdC7Angs - The angular displacement of the Head Marker from the
%                    C7 Marker
%         c7CBOSAngs - The angular displacement of the c7 Marker from the
%                      Center of the Base of support
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%cbos = bosData(3,7:9);

%For calculating our four new angular measures.
%Head COM from C7 X:  HdCOM_X - C7_X / HdCOM_Z - C7_Z
%Head COM from C7 Y:  HdCOM_X - C7_Y / HdCOM_Z - C7_Z
%C7 from CBOS X:  C7_X - CBOS_X / C7_Z - CBOS_Z
%C7 from CBOS Y:  C7_Y - CBOS_Y / C7_Z - CBOS_Z

%Reminder: everything has been centered according to the center of base of
%support, so for calculating the angles, we do not need to subtract it
%again.  
%Second Reminder: all variables that are called C7 uses the TrunkCOM data.
hdCOMTkCOMX = kinEventData(:,4)-kinEventData(:,10);
hdCOMTkCOMY = kinEventData(:,5)-kinEventData(:,11);
hdCOMTkCOMZ = kinEventData(:,6)-kinEventData(:,12);
tkCOMCBOSX = kinEventData(:,10);
tkCOMCBOSY = kinEventData(:,11);
tkCOMCBOSZ = kinEventData(:,12);
 
%Preallocate the matrix for the head Angle Data
%Also preallocate matrices for the angles associated with HeadCOM to C7
%angles, and C7 to the CBOS angles.
%Row 1 -- X data
%Row 2 -- Y data
hdC7Angs=zeros(length(hdCOMTkCOMX),2);
tkCBOSAngs=zeros(length(hdCOMTkCOMX),2);
 
%Actually calculate the head angles
for n=1:(length(hdCOMTkCOMX))
    %Angles between HeadCOM and C7 done dynamically
    hdC7Angs(n,1)=(atan(hdCOMTkCOMX(n)/hdCOMTkCOMZ(n)))*57.325;
    hdC7Angs(n,2)=(atan(hdCOMTkCOMY(n)/hdCOMTkCOMZ(n)))*57.325;
    %Angles between C7 and the Center of the Base of Support done
    %dynamically
    tkCBOSAngs(n,1)=(atan(tkCOMCBOSX(n)/tkCOMCBOSZ(n)))*57.325;
    tkCBOSAngs(n,2)=(atan(tkCOMCBOSY(n)/tkCOMCBOSZ(n)))*57.325;
end

end
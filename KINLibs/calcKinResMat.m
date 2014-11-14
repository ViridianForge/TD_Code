function [ resDiffMat, resPosMat ] = calcKinResMat( kinEventData )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CALCKINRESMAT Calculates the resultant matrix of the given kinematics.
%   Function assumes that user wants a resultant calculated based on the,
%   x, y, and z axises of the data.  Function also assumes that the data is
%   arranged in such a fashion that the columns are arranged such that
%   every three columns represent x,y, and z of a given data collection
%   channel.
%
%   Author -- Wayne Manselle - January 2013
%
%   INPUTS -- kinEventData -- the Kinematic Data to be worked against.
%   OUTPUTS -- resDiffMat -- the resultant position differences of kinEventData.
%              resPosMat -- the resultant positions of kinEventData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

resPosMat = zeros(length(kinEventData),5);
resDiffMat = zeros(length(kinEventData)-1,5);

for i=1:5
    %Resultant positions
    for j=1:length(kinEventData)
        resPosMat(j,i) = sqrt((kinEventData(j,3*i+1))^2 + ...
            (kinEventData(j,3*i+2))^2 + (kinEventData(j,3*i+3))^2);
    end
    %Resultant differences
    for j=2:length(kinEventData)
        resDiffMat(j-1,i) = sqrt((kinEventData(j,3*i+1)-kinEventData(j-1,3*i+1))^2 + ...
            (kinEventData(j,3*i+2)-kinEventData(j-1,3*i+2))^2 + ...
            (kinEventData(j,3*i+3)-kinEventData(j-1,3*i+3))^2);
    end
end

end
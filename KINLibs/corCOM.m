function [ corKinEventData ] = corCOM( kinEventData, hdPosData, tkPosData )
%TODO -- Comment this Wayne!
%CORCOM Summary of this function goes here
%   Detailed explanation goes here

corKinEventData = kinEventData;

hdOrigin = (hdPosData(3,:) + hdPosData(4,:))/2;
tkOrigin = (tkPosData(4,:) + tkPosData(2,:))/2;

vectorHd = [(tkOrigin(1)-tkPosData(1,1)) (tkOrigin(2) - tkPosData(1,2)) 0];

vectorTk = tkOrigin - tkPosData(2,:);

%Now, update the relevant columns in the KinEventData

corKinEventData(:,5:7) = kinEventData(:,2:4) + repmat(vectorHd,size(kinEventData,1),1);
corKinEventData(:,11:13) = kinEventData(:,8:10) + repmat(vectorTk,size(kinEventData,1),1);
end
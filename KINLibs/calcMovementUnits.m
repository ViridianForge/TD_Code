%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CALCMOVEMENTUNITS -- This function determines the number of movement units
%(acceleration and deceleration phases within a velocity profile as defined
%by Gronqvist, Brodd, and von Hofsten in their paper "Reaching Strategies 
%of Very Preterm Infants at 8 months Corrected Age"contained within a 
%given velocity profile.
%
%Author -- Wayne Manselle -- July 5th 2012
%
%Changelog --   12/12/2013 -- Begin Adding List of MU beginnings and ends 
%                             in DP to the output.
%
%INPUTS -- velData -- The velocity data to examine
%
%OUTPUTS -- numMvUnits -- The Number of Movement Units in the Velocity
%                         Profile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [numMvUnits] = calcMovementUnits(velData,timeData)
    %Step 0 -- Smooth the Velocity Profile as per Hofsten's Methodology,
    %with a 10Hz lowpass Butterworth Filter.
    %nyquist = 84/2; %Nyquist frequency of 84hz collection rate
    %[b,a]=butter(4,(10/nyquist));
    %velData = filtfilt(b,a,velData);
    
    muTimePoints = [];
 
    %Step 1 -- Identify the local minima of the velocity profile.
    accData = diff(velData,1,1)./0.0119;
    localMinima = [];
    for minCnt = 2:(length(accData)-1)
        %Checking for local minima.  These points will either be where the
        %acceleration changes from negative to positive, or where the
        %acceleration is zero between a transition from negative to
        %positive.
        if((accData(minCnt) > 0 && accData(minCnt-1) < 0) || ...
                (accData(minCnt) == 0 && accData(minCnt-1) < 0 && accData(minCnt+1) > 0))
            localMinima = cat(2,localMinima,minCnt);
        end
    end
    %Step 2 -- First criteria pass.  Ensure that MUs are sufficiently
    %distinct by checking to see if the difference between a velocity peak
    %and the highest minima of an adjacent MU is greater than 8 cm/s.
    firstCut = [];
    %Seed the criteria pass with the first candidate MU.
    if(length(localMinima)>2)
        %Seed the addresses in the local minima array.
        curLEnd = 1;
        curREnd = 2;
        cmpREnd = 3;
        %Seed The First Cut array with the starting Minima-Value
        firstCut = cat(2,firstCut,localMinima(curLEnd));
        while cmpREnd<=length(localMinima)
            maxMinima = max(velData(localMinima(curLEnd)),velData(localMinima(curREnd)));
            cmpPkVel = max(velData(localMinima(curREnd):localMinima(cmpREnd)));
            if(abs(cmpPkVel-maxMinima)<8)
                %Replace the current Right End of the Candidate MU
                curREnd = cmpREnd;
                cmpREnd = cmpREnd+1;
                if(cmpREnd>length(localMinima))
                    firstCut = cat(2,firstCut,localMinima(curREnd));
                end
            else
                %Add the new MU to the list.
                firstCut = cat(2,firstCut,localMinima(curREnd));
                curLEnd=curREnd;
                curREnd=curREnd+1;
                cmpREnd=cmpREnd+1;
                %Wrap up condition
                if(curREnd==length(localMinima))
                    firstCut = cat(2,firstCut,localMinima(curREnd));
                end
            end
        end
    else
        firstCut = localMinima;
    end
    %Step 3 -- Second criteria pass.  Ensure that the velocity peaks between
    %all potential MUs are 2.3 cm/s greater than either of their minima.
    %Each one that does increments the number of movement units.
    numMvUnits=1;
    secondCut = [];
    for candCnt = 1:length(firstCut)-1
        leftEnd = firstCut(candCnt);
        rightEnd = firstCut(candCnt+1);
        peakVel = max(velData(leftEnd:rightEnd));
        leftDiff = peakVel - velData(leftEnd);
        rightDiff = peakVel - velData(rightEnd);
        if(leftDiff > 2.3 && rightDiff > 2.3)
            if(isempty(secondCut))
                secondCut = cat(2,secondCut,firstCut(candCnt));
            end
            secondCut = cat(2,secondCut,firstCut(candCnt+1));
            numMvUnits=numMvUnits+1;
        end
    end
end
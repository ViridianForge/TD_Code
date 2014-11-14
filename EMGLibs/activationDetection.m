function [ activationPairs, verification, evaluations ] = ...
    activationDetection( normData, reachData, preEventLength, binSize,...
    actSize, deactSize, pkAmps, chanNames, normFactors, gTitle, verify )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ACTIVATIONDETECTION Detection and verification of EMG Activations
%   This function, given a set of EMG data that has been normalized as per
%   the methodology set out by Rachwani and Santamaria, attempts to
%   automatically detect all muscle activation periods. This is followed
%   up with a graphical presentation of the EMG that allows an end user to
%   correct any discrepencies they find with the activations.
%
%Author - Wayne Manselle - April 2014
%
%INPUTS - normData - the channels of normalized EMG Data to be explored
%         reachData - the channels of filtered EMG Data to be compared to
%         preEventLength - The number of ms used for baseline and APA
%         analysis before the EMG event onset
%         binSize - how large the bins of IEMG data are in ms
%         actSize - how much data constitutes an activation in ms
%         deactSize - how much data constitutes a deactivation in ms
%         chanNames - the labels of the EMG channels in the data
%         gTitle - the title to give the graphs presented by guiActVerifier
%         verify - a boolean flag indicating whether to graphically
%         evaluate the automated onset picker.
%OUTPUTS - activationPairs - the onset and offsets times of muscle
%                            activation decided upon by the user.
%          verification - The verification status of the graphical review
%                         system represented as the percent of correct
%                         judgements by the algorithm as reviewed by a
%                         human.
%          evaluation - the Channel by Channel evaluation of the GUI
%                       verifier represented as a binary array.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Automated Calculation of the Activation
%startTime = tic();
activationPairs = cell((size(normData,2)-2),1);
%testActivationPairs = cell((size(normData,2)-2),1);

for chan=1:size(normData,2)
    %naive version to start
    binCnt=0;
    actState=0;
    chanActs=[];
    testChanActs=[];
    actPair=zeros(1,2);
    
    %Step 1 -- Convert the Normalized Data into a Logical Array 
    %Step 2 -- Add a 0 to the beginning and end of the logical array to
    %detect muscles that start activated, or do not deactivate.
    %Step 3 -- Calculate the first differential.  This turns muscle
    %activations into 1s, and deactivations into -1s.
    
    %Replace activations and deactivations not followed by a sufficient
    %time in that state with zeros.
        
    for bin=1:size(normData,1)
        %Hunting for an onset.
        if(actState==0)
            if(normData(bin,chan)>=1)
                binCnt=binCnt+1;
            else
                binCnt=0;
            end
            if(binCnt>=actSize/binSize)
                actPair(1)=bin-((actSize/binSize)-1);
                actState=1;
                binCnt=0;
            end
        else
            %Hunting for an offset
            if(normData(bin,chan)<1)
                binCnt=binCnt+1;
            else
                binCnt=0;
            end
            if(binCnt>=deactSize/binSize || bin==size(normData,1))
                %Here's our muscle is on through the end of the data case.
                %If it is, we say the muscle offset at the boundary between
                %the last bin, and what would be the beginning of the next,
                %if there were more data.
                if(bin==size(normData,1))
                    actPair(2)=bin+1;
                else
                    actPair(2)=bin-((deactSize/binSize)-1);
                end
                chanActs=vertcat(chanActs,actPair);
                actPair=zeros(1,2);
                actState=0;
                binCnt=0;
            end
        end
    end
    activationPairs{chan}=chanActs;
end

%Generate Graphical Chooser and return the percentage of correct
%verifications.
if(verify)
    [verification, evaluations] = ...
        guiActVerifier(activationPairs, normData,reachData, ...
        preEventLength, binSize, pkAmps, chanNames, normFactors, gTitle);
else
    verification = 1;
    evaluations = 1;
end

end
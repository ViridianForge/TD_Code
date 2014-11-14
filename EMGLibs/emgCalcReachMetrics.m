function [ metrics ] = emgCalcReachMetrics( normData, activationPairs,...
    binSize, preEventTime, bslnLim)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%EMGCALCREACHMETRICS Calculates Metrics for a given Reach Event
%   This function calculates the evaluative metrics of EMG as defined by 
%   Gonzalez and Rachwani for their TD and CP studies.  
%
%Author: Wayne Manselle - April 2014
%
%Current Metrics (Version 4)
%1 -- Total Number of Activations
%2 -- Number of bursts originating in Baseline Stage
%3 -- Number of bursts originating in APA Stage
%4 -- Number of bursts originating in CPA Stage
%5 -- Onset Time of first Baseline Centric Burst
%6 -- Offset Time of final Baseline Centric Burst
%7 -- Onset Time of first APA Centric Bursts
%8 -- Offset Time of final APA Centric Bursts
%9 -- Onset Time of first CPA Centric Bursts
%10 -- Offset Time of final CPA Centric Bursts
%11 -- Total Activation Time in APA Stage
%12 -- Total Activation Time in CPA Stage
%13 -- Total IEMG of all Baseline Bursts
%14 -- Total IEMG of all APA Bursts
%15 -- Total IEMG of all CPA Bursts
%16 -- Final Offset time of Reach
%17 -- Was Muscle wholly activated?
%
%INPUTS: normData - the Normalized EMG Data
%        activationPairs - the onset and offsets of muscle activations
%        binSize - the number of milliseconds in a bin
%        preEventTime - the length, in ms, of the period preceding the EMG
%        event used for baseline and APA regions
%        bslnLim - the point of time in ms, before the onset of the EMG,
%        prior to which is considered a baseline EMG region.
%
%OUTPUTS: metrics - the compiled set of metrics for the dataset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Set up the output container
metrics = nan(size(normData,2),17);
%Calculate the end points of the total reach for use in the evaluation
reachOnset = -preEventTime;
reachOffset = (size(normData,1)*binSize)-preEventTime;

for muscAct=1:size(activationPairs,1)
    curActSet = activationPairs{muscAct};

    if(~isempty(curActSet))
        metrics(muscAct,1) = size(curActSet,1);
        for acts = 1:size(curActSet,1)
            
            curAct = curActSet(acts,:);
            
            %Convert the Bins given into Onset and Offset times (ms)
            %Subtract one from the first bin to get the "left side" of the
            %bin in ms time.
            curOnset = ((curAct(1)-1)*binSize-preEventTime);
            curOffset = ((curAct(2)-1)*binSize-preEventTime);
            
            %1 -- Number of Activations should we break this up by APA and CPA?
            %Piggy back on this to set the APA/CPA-Centric onset and offset
            %times as well
            if(curOnset < bslnLim)
                metrics(muscAct,2) = ift(isnan(metrics(muscAct,2)),0,metrics(muscAct,2)) + 1;
                
                %Set the Baseline onset and offset time
                metrics(muscAct,5) = ift(isnan(metrics(muscAct,5)),curOnset,metrics(muscAct,5));
                metrics(muscAct,6) = curOffset;
            elseif(curOnset<0)
                metrics(muscAct,3) = ift(isnan(metrics(muscAct,3)),0,metrics(muscAct,3))...
                                     + 1;
                %Set the APA onset and offset time
                metrics(muscAct,7) = ift(isnan(metrics(muscAct,7)),curOnset,metrics(muscAct,7));
                metrics(muscAct,8) = curOffset;
                
            else
                metrics(muscAct,4) = ift(isnan(metrics(muscAct,4)),0,metrics(muscAct,4))...
                                     + 1;
                %Set the CPA onset and offset time
                metrics(muscAct,9) = ift(isnan(metrics(muscAct,9)),curOnset,metrics(muscAct,9));
                metrics(muscAct,10) = curOffset;       
            end                 
            
            %Baseline Region Logic
            
            %It has been requested the IEMG of the Baseline Region always
            %be calculated.
                
            %Set the total IEMG for the baseline
            %Have to use binTime versions of calc on and calc off
            %The Baseline Limit is expressed as a number of milliseconds
            %before the reaching onset to consider APA.  Any time before
            %that is baseline.  Thereofre, by combining the total pre event
            %length with it, we arrive at the amount of ms from the
            %beginning of the data segment to consider baseline.
            
            metrics(muscAct,13) =...
                sum(normData(1:(preEventTime + bslnLim)/binSize,muscAct)); 
            
            if(curOnset < bslnLim)
                calcOn = curOnset;
                calcOff = curOffset;
                if(curOffset >= bslnLim)
                    calcOff = bslnLim;
                    curOnset = bslnLim;
                end               
            end
            
            %APA Region Logic
            if(curOnset < 0)
                calcOn = curOnset;
                calcOff = curOffset;
                if(curOffset >= 0)
                    calcOff = 0;
                    curOnset = 0;
                end
                
                binCalcOn = ((calcOn + preEventTime))/binSize+1;
                binCalcOff = ((calcOff + preEventTime))/binSize+1;
                
                %Add the length of this region to the total APA activation
                %time.
                metrics(muscAct,11) = ift(isnan(metrics(muscAct,11)),0,metrics(muscAct,11))...
                                     + abs(calcOn-calcOff);
                %Add the amount of IEMG in this region to the amount of APA
                %IEMG.
                metrics(muscAct,14) = ift(isnan(metrics(muscAct,14)),0,metrics(muscAct,14))...
                                     + sum(normData(binCalcOn:binCalcOff,muscAct));
            end
            
            %CPA Region Logic
            if(curOnset >= 0)
                calcOn = curOnset;
                calcOff = curOffset;
                
                binCalcOn = ((calcOn + preEventTime))/binSize+1;
                binCalcOff = ((calcOff + preEventTime))/binSize;
                %Add the length of this region to the total APA activation
                %time.
                metrics(muscAct,12) = ift(isnan(metrics(muscAct,12)),0,metrics(muscAct,12))...
                                     + abs(calcOn-calcOff);
                metrics(muscAct,15) = ift(isnan(metrics(muscAct,15)),0,metrics(muscAct,15))...
                                     + sum(normData(binCalcOn:binCalcOff,muscAct));
            end
            
            metrics(muscAct,16) = reachOffset;
            metrics(muscAct,17) = ...
                ift((metrics(muscAct,5) == reachOnset) && (metrics(muscAct,6)== reachOffset),1,0);
        end
    else
         metrics(muscAct,1:4)=0;
    end
end

end
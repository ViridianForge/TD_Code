function [ quietAvgIEMG, quietSDIEMG, quietSegLims ] = ...
    detQuietSeg( emgDatasets, binSize, winSize)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%DETQUIETSEG Returns the quietest region of data in the datasets
%   This function determines the quietest n millisecond region of activity
%   across all datasets given, where n is determined by the passed
%   variable.  The quietness of this segment is expressed as the average
%   integrated EMG activity across 100 consecutive 20ms bins of data.
%
%
%   Author: Wayne Manselle - March 2014
%           Altered functionality to merge multiple stages of processing
%           and take iEMGs in account with everything.
%
%INPUTS: emgDatasets - a cell array containing all datasets to be analyzed
%        binSize - the bin length to be examined in ms.
%        windowSize - the amount of data to examine to determine the quiet
%        segment IEMG.
%OUTPUTS: quietAvgIEMG - the resulting quietest segment of data for each
%                     channel of EMG by Level of Collection.
%         quietSDIEMG - the resulting SD upper limit for the corresponding
%                     quiet EMG Segment by Channel for determining onset
%                     thresholds.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Set up storage for quietest aIEMG by channel across levels, ignoring the
%HB and trigger channels
quietAvgIEMG = nan(size(emgDatasets{1},2)-2,1);
quietSDIEMG = nan(size(emgDatasets{1},2)-2,1);
quietSegLims = nan(size(emgDatasets{1},2)-2,3);

%For all levels of EMG

for dLoc=1:size(emgDatasets,1)
    curData=emgDatasets{dLoc};
    %Again, ignore the HB and trigger channels
    for chan=1:size(curData,2)-2
        %Get current channel
        curChan = curData(:,chan);
        %Reduce Channel into 20ms averages
        redChan = zeros(floor(size(curChan,1)/binSize),1);
        binInd=1;
        curQIEMG = quietAvgIEMG(chan);
        curQIEMGSD = quietSDIEMG(chan);
        for binEdge=1:binSize:size(curChan,1)
            %Check to make sure we have enough data to make another bin.
            if((size(curChan,1)-binEdge)>binSize)
                redChan(binInd)=trapz(curChan(binEdge:binEdge+(binSize-1)));
                %Once we have a large enough window of binned data, start checking windows
                %of activity.  Using strict equality here ensures that we
                %get at least 50 datapoints at all times.
                if(binInd>(winSize/binSize))
                    %Check the activity level of the quiet segments
                    %Debug mode!
                    candQIEMG = mean(redChan(binInd-((winSize/binSize)):binInd));
                    %candQIEMGSD = std(redChan(binInd-(winSize-1):binInd));
                    candQIEMGSD = (std(redChan(binInd-((winSize/binSize)):binInd)))/sqrt((winSize/binSize));
                    if(candQIEMG<curQIEMG || isnan(curQIEMG))
                        %disp(['Current window edges: ' num2str(binInd-((winSize/binSize))) ' : ' num2str(binInd)])
                        %disp(['Current Candidate Quiet Segment Average IEMG: ' num2str(candQIEMG)])
                        %disp(['Current Best Quiet Segment Average IEMG: ' num2str(curQIEMG)])
                        quietSegLims(chan,1) = (binInd-(winSize/binSize))*binSize;
                        quietSegLims(chan,2) = binInd*binSize;
                        quietSegLims(chan,3) = dLoc;
                        curQIEMG=candQIEMG;
                        curQIEMGSD=candQIEMGSD;
                    end
                end
                binInd=binInd+1;
            end
        end
        %disp(['This channel has quiet window edges of: ' num2str(quietSegLims(chan,1)) ' : ' num2str(quietSegLims(chan,2))])
        quietAvgIEMG(chan)=curQIEMG;
        quietSDIEMG(chan)=curQIEMGSD;
    end
end
end
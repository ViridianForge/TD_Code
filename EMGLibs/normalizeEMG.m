function [normEMG, procReachData] = ...
    normalizeEMG(emgDatasets,timingData,quietAIEMG,normFactor, quietSDIEMG,...
                 binSize)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%NORMALIZEEMG Normalizes EMG data according to Victor and Jennifer's design
%
%  This function normalizes the emg data across the levels in emgDatasets
%  within the reaching regions defined by timingData.  The normalization is
%  based on the following algorithm:
%
%   Divide the reach region of EMG into binSize bins, dropping excess data at
%   the end of the reach if there isn't enough for a final full bin.
%
%   For each bin:
%       normEMG_bin = (Integral(emgData_bin)-quietAIEMG)/quietAIEMG
%
%   Append the result to the final amount of output
%
%AUTHOR: Wayne Manselle -- March 2014
%
%INPUTS: emgDatasets -- The EMG Datasets to be Normalized.
%        timingData -- The locations of reaches to normalize.
%        quietAIEMG -- The quiet region of EMG to normalize against
%        sdThreshold -- the number of Standard Deviations to use to
%                       determine an activation
%        quietSDIEMG -- 
%        binSize -- the size in ms of a bin of data
%
%OUTPUTS: normEMG -- The Normalized EMG Data, formatted as a cell array
%organized by level of support and reach
%         procReachData -- The Unnormalized EMG data divided up by reach.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

normEMG = cell(size(emgDatasets,1),1);
procReachData = cell(size(emgDatasets,1),1);

for dataSet = 1:size(emgDatasets,1)
    curTimingData = timingData{dataSet};
    curEMGData = emgDatasets{dataSet};
    normEMGLevel = cell(size(curTimingData,1),1);
    procReachLevel = cell(size(curTimingData,1),1);
    for reachEv = 1:size(curTimingData,1)
        %Test to see if there's enough extra data to encapture a full extra
        %bin, or whether we should drop it.
        %disp(['Event ' num2str(curTimingData{reachEv,1}) ' is a ' curTimingData{reachEv,5} ' handed reach of type: ' curTimingData{reachEv,6}])
        %disp(['Current EMG Region starts at: ' num2str(curTimingData{reachEv,2}) ' and ends at: ' num2str(curTimingData{reachEv,4})])
        
        setLength = round(curTimingData{reachEv,4})-round(curTimingData{reachEv,2});
        compLen=(binSize-mod(setLength,binSize));
        if(curTimingData{reachEv,4}+compLen<=(size(curEMGData,1)))
            emgProcessRegion = ...
                curEMGData(round(curTimingData{reachEv,2}):round(curTimingData{reachEv,4})+compLen,:);
        else
            emgProcessRegion = ...
                curEMGData(round(curTimingData{reachEv,2}):round(curTimingData{reachEv,4}),:);
        end
        procReachLevel{reachEv} = emgProcessRegion;
        normReach = zeros(floor(size(emgProcessRegion,1)/binSize),size(emgProcessRegion,2));
        for chan=1:size(emgProcessRegion,2)-2
            curChan = emgProcessRegion(:,chan);
            binInd=1;
            for binEdge=1:binSize:size(emgProcessRegion,1)
                if(binEdge+(binSize-1)<size(curChan,1))
                    iEMGReach = trapz(curChan(binEdge:binEdge+(binSize-1)));
                    %normMod = (normFactor*quietSDIEMG(chan)+quietAIEMG(chan));
                    %This methodological test change is an attempt to get
                    %the algorithm to work for subject muscles that have
                    %very quiet quiet segments and a small SD of quiet
                    %activity.
                    normMod = (normFactor*quietAIEMG(chan));
                    normReach(binInd,chan) = (iEMGReach-normMod)/normMod;
                end
                binInd=binInd+1;
            end
        end
        normEMGLevel{reachEv} = normReach;
    end
    procReachData{dataSet}=procReachLevel;
    normEMG{dataSet}=normEMGLevel;
end

end
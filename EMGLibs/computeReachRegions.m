function [ reachRegions ] = computeReachRegions( fileList, trigChans )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%COMPUTEREACHREGIONS This function returns Reach Regions for EMG processing
%   This function uses the OpenSHAPA files and Reach Files for each level
%   of data collection to create a list of time regions to check in the EMG
%   data.
%
%AUTHOR:  Wayne Manselle - March 2014
%
%INPUTS: fileList - the files associated with the subject being processed
%        trigChans - the synchronization channel from the EMG
%
%OUTPUTS: reachRegions - the EMG time referenced reach regions for the
%         subject.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%The reach regions output will be a cell array with a number of cells equal
%to the number of levels of support this subject experienced.  Each cell
%will be a table consisting of each reach that subject did at that level of
%support.
%Each table will have the following columns
%C1 -- Trial Number
%C2 -- PreReach Start
%C3 -- Reach Start
%C4 -- Reach End
%C5 -- Handedness of Reach
%C6 -- Reach Classification Code
reachRegions=cell(size(fileList,1),1);

for level=1:size(fileList,1)
    %First order of business determine the onset times of the trigger
    %channel.
    curTrigChan = trigChans{level};
    %2000mv seems an appropriate measure that the trigger has fully taken
    %effect.  The +1 here is to ensure time points properly match up
    %post-differentiation with the times in the EMG file.
    %figure
    %plot(curTrigChan)
    %onsetsEMGT = find(diff(curTrigChan)>2000)+1
    
    %The differention method was vulnerable to timing issues
    onsetsEMGT=[];
    trigHunt=true;
    for pt=1:size(curTrigChan,1)
        if(curTrigChan(pt)>2000)
            if(trigHunt)
                onsetsEMGT = horzcat(onsetsEMGT,pt);
                trigHunt=false;
            end
        else
            trigHunt=true;
        end
    end
    %size(onsetsEMGT)
    %find(diff(curTrigChan)>1000)+1
    %onsetsEMGT
    
    %Load trial times
    handData = readtext2(fileList{level,1},',','','','');
    timeData = readtext2(fileList{level,2},',','','','');
    lHandCodes = handData(2:end,10);
    rHandCodes = handData(2:end,5);
    %Load each reach file that exists, and do time math
    if(~isempty(fileList{level,3}))
        lReaches = readtext2(fileList{level,3},',','','','');
        for rRow = 2:size(lReaches,1)
            if(lReaches{rRow,1} ~= 0)
                newRow = cell(1,7);
                trialOnset = timeData{lReaches{rRow,1}+1,2};
                newRow{1}=lReaches{rRow,5};
                newRow{2}=lReaches{rRow,2}+onsetsEMGT(lReaches{rRow,1});
                newRow{3}=lReaches{rRow,3}+onsetsEMGT(lReaches{rRow,1});
                newRow{4}=lReaches{rRow,4}+onsetsEMGT(lReaches{rRow,1});
                newRow{5}='Left';
                newRow{6}=lHandCodes{lReaches{rRow,5}};
                newRow{7}=lReaches{rRow,1};
                reachRegions{level} = vertcat(reachRegions{level}, newRow);
            end
        end
    end
    if(~isempty(fileList{level,4}))
        rReaches = readtext2(fileList{level,4},',','','','');
        for rRow = 2:size(rReaches,1)
            if(rReaches{rRow,1} ~= 0)
                newRow = cell(1,7);
                trialOnset = timeData{rReaches{rRow,1}+1,2};
                newRow{1}=rReaches{rRow,5};
                newRow{2}=rReaches{rRow,2}+onsetsEMGT(rReaches{rRow,1});
                newRow{3}=rReaches{rRow,3}+onsetsEMGT(rReaches{rRow,1});
                newRow{4}=rReaches{rRow,4}+onsetsEMGT(rReaches{rRow,1});
                newRow{5}='Right';
                newRow{6}=rHandCodes{rReaches{rRow,5}};
                newRow{7}=rReaches{rRow,1};
                reachRegions{level} = vertcat(reachRegions{level}, newRow);
            end
        end
    end
end
end
function [ rReachData,lReachData] = ...
    InterpretOSHAPA( openSHAPAFile, trialTimingFile, curSubj )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%InterpretOSHAPA A function to interpret and convert OpenSHAPA reach data.
%   Given a file consisting of the Hand Data from OpenSHAPA output, this
%   function will return two cell structures containing reach and grasp
%   segments for both hands.
%
%   Author -- Wayne Manselle
%   Creation Date -- November 2012
%
%   INPUT -- openSHAPAFile -- The path and file string of the file
%   containing the Hand Data to be interpreted.
%   trialTimingFile -- The path and file string of the file containing the
%   start time of each trial, in ms, referenced to the beginning of data
%   collection.
%   curSubj -- The Current Subject for Group Identification
%
%   OUTPUTS -- 4 Matrices that are Nx5, where N is the number of
%   observations in the openSHAPA data that belong in that given matrix.
%   The columns are event number, observation onset, observation offset,
%   trial number and observation classification code.
%
%   The 4 Matrices are:
%   rReachData -- Observations pertaining to right handed reaches
%   lReachData -- Observations pertaining to left handed reaches
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Ensure that any needed libraries are on the path.
%This line may be removable when not testing the function
setupPath();
%Read in the data from the hand output file.
handData = readtext2(openSHAPAFile,',','','','');
timeData = readtext2(trialTimingFile,',','','','');
[hDataRows, hDataCols] = size(handData);
[numTrials, tDataCols] = size(timeData);
%Create the output arrays.
rReachData = cell(hDataRows-1,5);
lReachData = rReachData;
rGraspData = rReachData;
lGraspData = rReachData;

%Set up our acceptible reach and grasp codes.

switch curSubj(1:2);
    %Adult Reaching Group
    case 'AR'
        goodReaches = {'UU','US','BDS','BNDS','BDU','BNDU'};
    %Typically Developing Infant Group
    case 'TD'
        %Verified with Jennifer Rachwani - 04/25/2014
        goodReaches = {'UU','US','UUG','USG','BDS','BDSG','BDU','BDUG','PR','QS'};
    %Cerebral Palsy Study Group
    case 'CP'
        goodReaches = {'US','CBDSR','UDSR','BDSR','RUS','LUS','MUS','QS'};
    %The Subject didn't have a group ID we're familiar with
    otherwise
        warning(['Subject Identifier is invalid.  Please review: ' openSHAPAFile])
        return;
end

%Looping over to properly organize the data.
%Hand -- 1 is Right Hand Data, and 2 is Left Hand Data.
%This is a leftover from Sandy's original design, where Right Handed
%data came out first (therefore being on the left side of the file).
for hand=1:2
    %disp(['Current Hand:' num2str(hand)])
    for dataLine = 2:hDataRows
        curRow = handData(dataLine,(1+(5*(hand-1))):(5*hand));
        %The Observation Code is the last element in the Row of Data.
        obCode = curRow{5};
        %Ignore any data lines that are due to the right and left hands not
        %having the same number of reaches.
        if(~isempty(obCode) && obCode(1)~='"')
            %We need to compare the known onset time of the event to the
            %onset time of the trials to determine which trial the event
            %belongs in.
            trialNumber=1;
            %The plus one here is to accommodate the header row in the
            %timing data.
            %The order of these tests are important.  We need to check if
            %we're about to go off the end of the number of trials before
            %we check to see if there's data in the next section of the
            %array.
            while((trialNumber<numTrials) && (timeData{trialNumber+1,2}<=curRow{2}))
                trialNumber=trialNumber+1;
            end          
            
            %We then do a match of the trial number to the corresponding
            %trial in the time data in order to rereference the start of
            %the reach to the start of the trial.
            curRow{2} = curRow{2} - timeData{trialNumber,2};
            %Potential trouble-maker catch for edge cases here.  If our
            %onset time is '0', set it to 1 so it starts on the first
            %datapoint of the reach-region.
            if(curRow{2}==0)
                curRow{2}=1;
            end
            %Grab the offset time.
            curRow{3} = curRow{3} - timeData{trialNumber,2};
            
            %Finally, we record the trial number.
            curRow{4}=trialNumber-1;
            %obCode
            %strcmp(obCode,goodReaches)
            %strcmp(obCode,goodGrasps)
            if(any(strcmp(obCode,goodReaches)))
                %Observation is a Reach
                if(hand==1)
                    rReachData(dataLine-1,:) = curRow;
                else
                    lReachData(dataLine-1,:) = curRow;
                end
            end
        end
    end
end

%Finally, clear out all blank rows in the data
rReachData(all(cellfun('isempty',rReachData),2),:)=[];
lReachData(all(cellfun('isempty',lReachData),2),:)=[];
end
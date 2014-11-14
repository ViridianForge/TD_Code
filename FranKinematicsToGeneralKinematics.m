%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%FRANKINEMATICSTOGENERALKINEMATICS.M
%
%Script to automate the process of converting data collected using the
%Minibird Control programs used in Francine's, Staci's, and Victor and
%Jennifer's studies into the linearized "General Kinematic" format.
%
%The general idea here is to be able to select a bulk amount of .txt files
%
%
%Author -- Wayne Manselle
%Date -- November 2014
%CHANGELOG -- 11.12.2014 -- Initial Creation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%Stage 0 -- Library and Constant Setup%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%See setupPath.m to ensure all paths are correctly set.
setupPath()

%Select all folders of subject data to process kinematic stats for --
%returns 0 on a cancelled selection
filesToProcess = uipickfiles();

outputFolder = uigetdir;

%As datasets collected during these experiments always had 4 MiniBirds, we
%can set the number of sensors to 4.
numSensors=4;

%Collection Description String.  First line of the Generalized Kinematic
%Format.
descriptiveString = 'Position / Matrix';

%Header String.  Second line of the Generalized Kinematic Format.
fileHeader = {'X1','Y1','Z1','M(1,1,1)','M(1,2,1)','M(1,3,1)','M(2,1,1)',...
    'M(2,2,1)','M(2,3,1)','M(3,1,1)','M(3,2,1)','M(3,3,1)','X2','Y2','Z2',...
    'M(1,1,2)','M(1,2,2)','M(1,3,2)','M(2,1,2)','M(2,2,2)','M(2,3,2)',...
    'M(3,1,2)','M(3,2,2)','M(3,3,2)','X3','Y3','Z3','M(1,1,3)','M(1,2,3)',...
    'M(1,3,3)','M(2,1,3)','M(2,2,3)','M(2,3,3)','M(3,1,3)','M(3,2,3)',...
    'M(3,3,3)','X4','Y4','Z4','M(1,1,4)','M(1,2,4)','M(1,3,4)','M(2,1,4)',...
    'M(2,2,4)','M(2,3,4)','M(3,1,4)','M(3,2,4)','M(3,3,4)','Mark','Pause',...
    'Trial','Timestamp'};

%Process those subjects.  Specifically, retrieve the kinematic data file
%from the subject's folder for processing.
if(iscell(filesToProcess))
    for procFile=1:size(filesToProcess,2)
        
        %Isolate Filename for saving purposes
        [pathstr,fileName,ext] = fileparts(filesToProcess{procFile});
        
        disp(['Beginning Conversion of ' fileName ' kinematic data.'])
        
        %Load File
        birdFID = fopen(filesToProcess{procFile});
        birdData=textscan(birdFID, '%s', 'delimiter', '\n');
        fclose(birdFID);
        %This step is to pull the BirdData from its nested cell array.
        birdData = birdData{1};
        
        %Mark Data, number of Marks, line locations
        markCount = 0;
        markFlag = 0;
        
        %Pause Counter
        pauseCount = 0;
        
        %Trial Data, number of trials, begin and end locations
        trialCount = 0;
        trialFlag = 0;
        
        %First DataLine Over time for verification
        fDataLineOverTime={};
        
        %Prepare Output Location
        convDataSet = [];
        
        %Scan line by line, starting at the third line to avoid the
        %descriptive text and header
        dataLine = 3;
        curDataLine=birdData(dataLine,:);
        while isempty((strfind(curDataLine{1},'QUIT')))
            newConvLine = zeros(1,numSensors*12+4);
            if(ischar(curDataLine{1}))
                %If Mark Notation Observed, increment the mark count and
                %activate the Mark flag
                if(strfind(curDataLine{1},'MARK'))
                    markCount = markCount + 1;
                    markFlag = 1;
                    dataLine = dataLine+2;
                %If Paused Observed, Note Pause as line of 0s plus a pause
                %marker.
                elseif(strfind(curDataLine{1},'PAUSE'))
                    pauseCount = pauseCount + 1;
                    newConvLine(end-3)=pauseCount;
                    convDataSet = vertcat(convDataSet,newConvLine);
                    dataLine = dataLine+2;
                %If trial beginning is observed, note trial number.    
                elseif(strfind(curDataLine{1},'BEGIN'))
                    trialCount = trialCount + 1;
                    trialFlag = 1;
                    dataLine = dataLine+2;
                %If trial ending is observed, note trial number.    
                elseif(strfind(curDataLine{1},'END'))
                    trialFlag = 0;
                    dataLine = dataLine+2;
                elseif(strcmp(curDataLine{1},''))
                    dataLine = dataLine+1;
                %Otherwise, line of data.  Get to chunking!
                else
                    %Grab the Three Lines of Data for the data point.
                    %Using the franEraDataLineGather to prevent any data
                    %gaps.
                    [firstDataLine,secondDataLine,thirdDataLine,newInd] = ...
                        franEraDataLineGatherer(birdData,dataLine);
                    
                    dataLine=newInd;
                    
                    %Flop the data lines so that they're in row formatting.
                    firstDataLine = firstDataLine{1}';
                    secondDataLine = secondDataLine{1}';
                    thirdDataLine = thirdDataLine{1}';
                    
                    %populate the new data line
                    newConvLine(1:numSensors*12) = ...
                        [
                        %First Sensor - Columns - 2:7
                        str2double(firstDataLine{2}), str2double(firstDataLine{3}), str2double(firstDataLine{4}),...
                        str2double(firstDataLine{5}), str2double(firstDataLine{6}), str2double(firstDataLine{7}),...
                        str2double(secondDataLine{5}), str2double(secondDataLine{6}), str2double(secondDataLine{7}),...
                        str2double(thirdDataLine{5}), str2double(thirdDataLine{6}), str2double(thirdDataLine{7}),...
                        %Second Sensor - Columns - 10:15
                        str2double(firstDataLine{10}), str2double(firstDataLine{11}), str2double(firstDataLine{12}),...
                        str2double(firstDataLine{13}), str2double(firstDataLine{14}), str2double(firstDataLine{15}),...
                        str2double(secondDataLine{13}), str2double(secondDataLine{14}), str2double(secondDataLine{15}),...
                        str2double(thirdDataLine{13}), str2double(thirdDataLine{14}), str2double(thirdDataLine{15}),...
                        %Third Sensor - Columns - 18:23
                        str2double(firstDataLine{18}), str2double(firstDataLine{19}), str2double(firstDataLine{20}),...
                        str2double(firstDataLine{21}), str2double(firstDataLine{22}), str2double(firstDataLine{23}),...
                        str2double(secondDataLine{21}), str2double(secondDataLine{22}), str2double(secondDataLine{23}),...
                        str2double(thirdDataLine{21}), str2double(thirdDataLine{22}), str2double(thirdDataLine{23}),...
                        %Fourth Sensor - Columns - 26:31
                        str2double(firstDataLine{26}), str2double(firstDataLine{27}), str2double(firstDataLine{28}),...
                        str2double(firstDataLine{29}), str2double(firstDataLine{30}), str2double(firstDataLine{31}),...
                        str2double(secondDataLine{29}), str2double(secondDataLine{30}), str2double(secondDataLine{31}),...
                        str2double(thirdDataLine{29}), str2double(thirdDataLine{30}), str2double(thirdDataLine{31})];
                    
                    %Note the mark number if the mark flag is present.
                    %Deactive the mark flag after, as only the first data
                    %point after a mark is relevant to the mark.
                    if(markFlag)
                        newConvLine(end-3) = markCount;
                        markFlag = 0;
                    end
                    
                    %Note the trial number if the trial flag is present.
                    if(trialFlag)
                        newConvLine(end-1) = trialCount;
                    end
                    
                    %Record the timestamp
                    newConvLine(end) = str2double(thirdDataLine{34});
                    
                    %Append the new line to the output
                    convDataSet = vertcat(convDataSet,newConvLine);
                    
                    %Increment the counter to skip the blank line
                    dataLine = dataLine+1;
                end
            end
            %Increment the current data line to test for loop continuance.
            curDataLine=birdData(dataLine,:);
        end      
        
        %File Conversion Complete.  Assemble the converted data together
        %with the header information and save to file.
        startSave = tic;
        cellOutput = cell(2,numSensors*12+4);
        cellOutput{1,1} = descriptiveString;
        cellOutput(2,:) = fileHeader;
        cellOutput = vertcat(cellOutput,num2cell(convDataSet));
        
        cell2csv([outputFolder filesep fileName '.gkf'],cellOutput);
                
        %Clear CellOutput with every file printed to keep memory for
        %getting blasted huge.
        clear cellOutput
    end
end
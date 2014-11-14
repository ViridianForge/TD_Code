%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ConvBigVolData.m
%
%This script asks the user for a file that is filled with "raw" Bird data.
%The script will then read the file, line by line, and multiply each
%positional value by 2 to convert it from half-inches to inches.
%
%IMPORTANT: Only use this script with files generated by the version of the
%bird code designed to run with a 72" magnetic volume.
%
%Author: Wayne Manselle -- March 2014
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
setupPath();

[rawDataFile,rawDataPath] = uigetfile('*.txt','Select the raw Bird Data to Convert');

outDataFile = ['Conv_' rawDataFile];

%Begin by reading data through a raw IO channel and closing the channel.
if(exist([rawDataPath rawDataFile],'file'))
    birdFID = fopen([rawDataPath rawDataFile]);
    birdData=textscan(birdFID, '%s', 'delimiter', '\n');
    fclose(birdFID);
    %This step is to pull the BirdData from its nested cell array.
    birdData = birdData{1};
    newData = cell(size(birdData));
    for dataLine=1:1:length(birdData);
        if(~strcmp(birdData{dataLine},''))
            data = textscan(cell2mat(birdData(dataLine,:)),'%s','delimiter',',');
            data = data{1}';
            if(strcmp(data{1},'1'))
                %Convert head position data
                data{2}=num2str(str2double(data{2})*2);
                data{3}=num2str(str2double(data{3})*2);
                data{4}=num2str(str2double(data{4})*2);
                %Convert c7 position data
                data{10}=num2str(str2double(data{10})*2);
                data{11}=num2str(str2double(data{11})*2);
                data{12}=num2str(str2double(data{12})*2);
                %Convert left hand position data
                data{18}=num2str(str2double(data{18})*2);
                data{19}=num2str(str2double(data{19})*2);
                data{20}=num2str(str2double(data{20})*2);
                %Convert right hand position data
                data{26}=num2str(str2double(data{26})*2);
                data{27}=num2str(str2double(data{27})*2);
                data{28}=num2str(str2double(data{28})*2);
            end
            newData{dataLine} = strjoin(data,',');
        else
            newData{dataLine} = '';
        end
        
    end
    cell2csv([rawDataPath outDataFile],newData);
else
    disp('Invalid or non-existant file chosen.')
end
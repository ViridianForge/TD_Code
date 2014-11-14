function [firstDataLine,secondDataLine,thirdDataLine,dataLine] = ...
    franEraDataLineGatherer(birdData,dataLine)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%franEraDataLineGatherer -- Looks at the next possible data point from a
%Francine-era kinematic file, removes any possible problem lines, and
%returns possible problems lines for future review.
%
%Author -- Wayne Manselle - June 2013
%
%INPUTS:  birdData -- the primary dataset to pull from.
%         dataLine -- where to start searching for the next datapoint from
%
%OUTPUTS: firstDataLine -- the first line of data from the data point
%         secondDataLine -- the second line of data from the data point
%         thirdDataLine -- the third line of data from the data point
%         problems -- any dataLine locations where there were gaps
%         dataLine -- the new dataLine location to continue the search
%         from.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i=1:3 
    while(strcmp(birdData(dataLine,:),''))
        disp(['Extraneous blank line found in data file at: ' num2str(dataLine) '.'])
        disp('Syncing to next line of data.')
        dataLine=dataLine+1;
    end
    switch(i)
        case 1
            firstDataLine = ...
                textscan(cell2mat(birdData(dataLine,:)),'%s','delimiter',',');
        case 2
            secondDataLine = ...
                textscan(cell2mat(birdData(dataLine,:)),'%s','delimiter',',');
        case 3
            thirdDataLine = ...
                textscan(cell2mat(birdData(dataLine,:)),'%s','delimiter',',');
        otherwise
            error('The for loop has exceeded its possible index.  This is weird.')
    end
    dataLine=dataLine+1;
end
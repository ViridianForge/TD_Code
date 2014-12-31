%%
%This script is meant to pass over all the EMG files in a subject
%population, and if their first line contains string characters, delete
%that header line.
%
%This script was written specifically with Victor Santamaria-Gonzalez's CP 
%data collections in mind.  Using this with other data may result in 
%unintended side effects.
%
%Author: Wayne Manselle - June 2014
%%

%Add any necessary library files here

%Collect base directory
topDir = uigetdir('C:\','Select the Subject Population whose EMG needs cleaning.');

levels = {'\Axillae\','\Pelvic\','\Thoracic\'};

for subj=dir(topDir).name
    for supp=1:size(levels,1)
        if(exist([topDir subj levels{supp}],'dir'))
            %Read the 4th line of the file
            try
                csvread(file,4,0);
            catch
            end
            %If the 4th line is not numeric, delete it
        end
    end
end

function buildOutputDirectories( topDir, levelText )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%BUILDOUTPUTDIRECTORIES -Builds the output directory structure for a given
%subject being processed by the ProcessSubjectData script.
%
%Author:  Wayne Manselle - Feb 2013
%Changelog:  1 - March 2014 - Adapted to serve new TD+CP processing
%                             methodology - WM
%
%INPUTS:    topDir - the topLevel directory to build all output directories
%                    under.
%           levelText - textual representation of the levels this subject
%                       has in their data directory.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Preparing Data Output Locations')
eventTypes={'Right_Reach\','Left_Reach\'};
dataTypes={'\Kinematics\','\EMG\'};
%Check for the output dir
if(~exist([topDir '\Output\'], 'dir'))
    mkdir([topDir '\Output\']);
end
%Visit all directories and make sure they're there.
for type=1:length(dataTypes)
    %Create the two types of data directories
    if(~exist([topDir '\Output' dataTypes{type}], 'dir'))
        mkdir([topDir '\Output' dataTypes{type}]);
    end
    if(~exist([topDir '\Output' dataTypes{type} 'Stats\'],'dir'))
        mkdir([topDir '\Output' dataTypes{type} 'Stats\']);
    end
    if(~exist([topDir '\Output' dataTypes{type} 'Graphs\'],'dir'))
       mkdir([topDir '\Output' dataTypes{type} 'Graphs\']); 
    end
    for level=1:length(levelText)
        %Output the applies for entire levels.
        if(~exist([topDir '\Output' dataTypes{type} levelText{level}], 'dir'))
            mkdir([topDir '\Output' dataTypes{type} levelText{level}]);
        end
        if(~exist([topDir '\Output' dataTypes{type} levelText{level} 'FullTrials\'],'dir'))
            mkdir([topDir '\Output' dataTypes{type} levelText{level} 'FullTrials\']);
        end
        if(~exist([topDir '\Output' dataTypes{type} levelText{level} 'ReachTrials\'],'dir'))
            mkdir([topDir '\Output' dataTypes{type} levelText{level} 'ReachTrials\']);
        end
        for evT=1:length(eventTypes)
            if(~exist([topDir '\Output' dataTypes{type} levelText{level} 'ReachTrials\' eventTypes{evT}],'dir'))
                mkdir([topDir '\Output' dataTypes{type} levelText{level} 'ReachTrials\' eventTypes{evT}]);
            end
        end
    end
end
end
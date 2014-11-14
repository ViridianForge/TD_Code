function [ preEventTime, emgHeader, keyMuscChans, mergeMuscChans,...
    mergeBack, aChans, muscGroupings, kinSampRate] = groupSpecificSetup( curSubj )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%GROUPSPECIFICSETUP Subject processing setup specific to the group the
%subject belongs in.
%   This function is specifically for any processing setup that needs to be
%   done that depends on the group designation of the given subject.
%
%Author -- Wayne Manselle - Jan 2013
%
%INPUT -- curSubj - The Subject about to be processed.
%OUPUTS -- preEventTime - the amount of time, in milliseconds, pre-reach
%                            to include for analysis.
%             emgKinHeaders - the headers to use for the subject's emgKin
%                             Files.
%             keyMuscChans - the Muscle Channels most relevant for the
%             subject group.
%             mergeMuscChans - A list of EMG column pairs to be merged if
%             emg merging is requested.
%             mergeBack - A boolean to indicate whether a subject's back
%             muscles should be merged.
%             aChans - Channels of Data to be analyzed depending on the
%             dominant hand of the reach, the dominant hand determining
%             which group of muscles are selected for deeper analysis in
%             the reach.
%             muscGroupings - Groupings of muscles to examine for
%             coActivations.
%             kinSampRate - The collection rate of kinematics for group   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Classifying Subject by Group.')

%If the subject is valid, select the appropriate values to be returned to
%the calling function.
%Suggested new structure
switch curSubj(1:2)
    case 'AR'
        disp('Subject in Adult Reaching group.')
        preEventTime = 500;
        emgHeader = {'domBi','domTri','domAD',...
            'rCer','lCer','rThr','lThr','rLum','lLum','HB','trig'};
        keyMuscChans = [];
        mergeMuscChans = [4 6 8 ; 5 7 9];
        mergeBack = 0;
        aChans = [1 2 3 4 5 6 7 8 9];
        muscGroupings={[1;3],[1;5],[3;5],[1;3;5],[2;4],[2;6],[4;6],[2;4;6],[7;8]};
        kinSampRate = 84;
    case 'TD'
        disp('Subject in Typically Developing Infant Group.')
        preEventTime = 500;
        emgHeader = {'rBi','lBi','rTri','lTri','rAD','lAD',...
            'rThr','lThr','rLum','lLum','HB','trig'};
        keyMuscChans = [1 2 3 4 5 6];
        mergeMuscChans = [7 9 ; 8 10];
        mergeBack = 1;
        aChans = [1 3 5 7 8; 2 4 6 7 8];
        muscGroupings={[1;3],[1;5],[3;5],[1;3;5],[2;4],[2;6],[4;6],[2;4;6],[7;8]};
        kinSampRate = 84;
    case 'CP'
        disp('Subject in Children with CP Group.')
        preEventTime = 500;
        emgHeader = {'rBi','lBi','rTri','lTri','rAD','lAD'...
            'rCer','lCer','rThr','lThr','rLum','lLum','HB','trig'};
        keyMuscChans = [1 2 3 4 5 6];
        mergeMuscChans = [7 9 11 ; 8 10 12];
        mergeBack = 1;
        aChans = [1 3 5 7 8 9 ; 2 4 6 7 8 9];
        muscGroupings={[1;3],[1;5],[3;5],[1;3;5],[2;4],[2;6],[4;6],[2;4;6],[7;8],[7;9],[8;9],[7;8;9]};
        kinSampRate = 84;
    %In order to add new Subject Groups, starting above this line, begin
    %adding a copy of one of the previously established case statements,
    %using the new Subject Group's two letter identifier code in place of
    %the existing identifier.  Then proceed to populate the subject group
    %specific variables with the values appropriate to the group.
    otherwise
        disp('Invalid Subject Identifier detected.')
        preEventTime = NaN;
        [emgHeader,keyMuscChans,mergeMuscChans,aChans]=deal([]);
        mergeBack = 0;
        kinSampRate = 0;
        muscGroupings={};
end
end
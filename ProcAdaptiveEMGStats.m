%%%%Stage 0 -- Library and Constant Setup%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%See setupPath.m to ensure all paths are correctly set.
setupPath();

%Okay, let's lay this out.

%First, load the file
emgData = readtext2('C:\TestConversion\Adult_Data_EMG_AllReaches.csv',',','','');

%Important Column Addresses -- before and after
%Subject Number -- 1 -- 1
%Muscle Number -- 2 -- 2
%Level of Support -- 4 -- 3
%Reach Number -- 5 -- 4
%APAIEMG -- 24 -- 5
%CPAIEMG -- 25 -- 6

%Isolate the region of the file that matter for our calculations
emgData = cell2mat(emgData(2:end,[1 2 4 5 24 25]));

%Number of Rows -- 15 Subjects, 2 levels of support, 9 muscles -- 270.
%Number of Columns -- 2 measures -- 2
pelvicOutput = zeros(135,2);
thoracicOutput = zeros(135,2);

%Second, create two sub-documents, based on level of support.
for level=1:2
    curLevelData = emgData(emgData(:,3)==level,:);
    for subj=1:15
        curSubjData = curLevelData(curLevelData(:,1) == subj,:);
        for muscle=1:9
            curMuscData = curSubjData(curSubjData(:,2)==muscle,:); 
            %New Approach
            if(level==1)
                pelvicOutput(9*(subj-1)+muscle,1) = nanmean(curMuscData(end-1:end,5)) - nanmean(curMuscData(1:2,5));
                pelvicOutput(9*(subj-1)+muscle,2) = nanmean(curMuscData(end-1:end,6)) - nanmean(curMuscData(1:2,6));
            else
                thoracicOutput(9*(subj-1)+muscle,1) = nanmean(curMuscData(end-1:end,5)) - nanmean(curMuscData(1:2,5));
                thoracicOutput(9*(subj-1)+muscle,2) = nanmean(curMuscData(end-1:end,6)) - nanmean(curMuscData(1:2,6));
            end
        end
    end
end

%For final output, we need to interleave the two level of support's output
%files to match the formatting in the averaged file.
finalOutput = [];
for line=1:9:size(pelvicOutput,1)
    finalOutput = vertcat(finalOutput,pelvicOutput(line:line+8,:),thoracicOutput(line:line+8,:));
end

%Open Averages File, append this to the right hand side, save back out
emgAverages = readtext2('C:\TestConversion\Adult_Data_AverageEMG.csv',',','','');

newHeaders = {'ApativeAPA','AdaptiveCPA'};
newAverages = horzcat(emgAverages,vertcat(newHeaders,num2cell(finalOutput)));

cell2csv('C:\TestConversion\Adult_Data_AverageEMGWithAdaptiveMeasures.csv',newAverages);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CoActTotals.M
%
%Script that loads the EMGReachByLevel.csv file for the selected subjects
%
%
%Author -- Wayne Manselle
%Date -- September 2014
%CHANGELOG -- 09.30.2014 -- Initial Creation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%Stage 0 -- Library and Constant Setup%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%See setupPath.m to ensure all paths are correctly set.
setupPath();

%New additional headers
colHeads = {'','APA Total','APA Percentage','CPA Total','CPA Percentage','Total Across','Percentage Across','Num Reaches'};

%Select all folders of subject data to process kinematic stats for --
%returns 0 on a cancelled selection
foldersToProcess = uipickfiles();

%Iterate over the subjects picked
if(iscell(foldersToProcess))
    for procFolder=1:size(foldersToProcess,2)
        disp(['Currently Processing: ' foldersToProcess{procFolder}])
        %This actually isn't terribly relevant to the functionality of this
        %script, but is the function we have to classify the grouping of
        %the current subject and what levels of support they have
        %available.
        [fileList, levelText, topDir, curSubj] = ...
            CollectEMGFiles(foldersToProcess{procFolder});
        
        %Code to identify subject group and set segment offset and row
        %labels.
        if(strncmp(curSubj,'CP',2))
            rowHeads = {'Bi+Tri';'Bi+AD';'Tri+AD';'Bi+Tri+AD';'mergCer+mergThr';'mergCer+mergLum';'mergThr+mergLum';'mergCer+mergThr+mergLum'};
            preDOff = 13;
            %CombLines -- the first matrix are the first muscles to add
            %             the second matrix are the second muscles to add
            %             the third matrix is where the sum is placed in
            %             the output
            %PresLines -- the first matrix are the muscles to preserve
            %             the second matrix is where to place them in the
            %             output
            %Important, if adding a new subject group, remember to add one
            %to the placement matrix locations to account for the header
            %line in the output.
            combLines = [[2,3,4,5];[6,7,8,9];[2,3,4,5]];
            presLines = [[10,11,12,13];[6,7,8,9]];
        else if(strncmp(curSubj,'TD',2))
                rowHeads = {'Bi+Tri';'Bi+AD';'Tri+AD';'Bi+Tri+AD';'mergThr+mergLum'};
                preDOff = 10;
                combLines = [[2,3,4,5];[6,7,8,9];[2,3,4,5]];
                presLines = [10;6];
            else if(strncmp(curSubj,'AR',2))
                rowHeads = {'Bi+Tri';'Bi+AD';'Tri+AD';'Bi+Tri+AD';'Cer+Thr';'Cer+Lum';'Thr+Lum','Cer+Thr+Lum';};
                preDOff = 10;
                combLines = [[4,5,6];[7,8,9];[5,6,7]];
                presLines = [[1,2,3];[2,3,4]];
                else
                    disp(['Unrecognized Subject Group Identifier.  Expected a string starting with CP, TR, or AR.  Saw: ' curSubj])
                    return
                end
            end
        end
            
              
        %Temporary until this can be hacked to work for ALL subject types
        postProcOut = {};
        %Add the additional columns to postProcData
        
        %Get subject's EMG Level file
        preProcData = readtext2([foldersToProcess{procFolder} '\Output\EMG\Stats\EMGMetricsByLevel.csv'],',','','','');
        
        %For each Level
        for level=1:size(levelText,2)
            %Row Heads is a columnar matrix, hence denoting by 1 instead of
            %2.
            postProcData = cell(size(rowHeads,1)+1,size(colHeads,2));
            curPreOff = preDOff * (level-1);
            %Place column and row headers
            postProcData(1,:) = colHeads;
            %Note level of support in header
            postProcData{1,1} = levelText{level};
            postProcData(2:end,1) = rowHeads;
            %Get Total number of reaches
            numReaches = max(cell2mat(preProcData(2+curPreOff:13+curPreOff,4)));
            %Parens are Rows from start of level segment
            
            %Code to do metrics from muscle combinations that need to be
            %combined from the original file.
            for combs=1:size(combLines,2)
                combFirst = combLines(1,combs);
                combSecond = combLines(2,combs);
                place = combLines(3,combs);
                postProcData{place,2} = preProcData{combFirst+curPreOff,2} + preProcData{combSecond+curPreOff,2};
                postProcData{place,3} = ((postProcData{place,2})/numReaches)*100;
                postProcData{place,4} = preProcData{combFirst+curPreOff,3} + preProcData{combSecond+curPreOff,3};
                postProcData{place,5} = ((postProcData{place,4})/numReaches)*100;
                postProcData{place,6} = postProcData{place,2} + postProcData{place,4};
                postProcData{place,7} = ((postProcData{place,6})/numReaches)*100;
                postProcData{place,8} = numReaches;
            end
            
            %Code to do metrics from muscle combinations that need to be
            %presrved from the original file
            for combs=1:size(presLines,2)
                presFirst = presLines(1,combs);
                place = presLines(2,combs);
                postProcData{place,2} = preProcData{presFirst+curPreOff,2};
                postProcData{place,3} = ((postProcData{place,2})/numReaches)*100;
                postProcData{place,4} = preProcData{presFirst+curPreOff,3};
                postProcData{place,5} = ((postProcData{place,4})/numReaches)*100;
                postProcData{place,6} = postProcData{place,2} + postProcData{place,4};
                postProcData{place,7} = ((postProcData{place,6})/numReaches)*100;
                postProcData{place,8} = numReaches;
            end
            
            postProcOut = vertcat(postProcOut,postProcData);
        end
        cell2csv([foldersToProcess{procFolder} '\Output\EMG\Stats\EMGMetricsByLevelWithTotals.csv'],postProcOut)
    end
end
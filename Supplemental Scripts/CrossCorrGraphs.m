%Purpose of this script:
%
%Let's generate the cross correlations between trunk and arm resultant
%position for every data collection, and see, in general, which lag values
%have the highest correlation.
%
%For reference, the cross correlation function will be considering the
%cross correlation between the resultant position of the trunk and the
%resultant position of the reaching arm over time.
%
%If my understanding is correct, if the maximum correlation occurs at a
%negative lag, that would indicate that the greatest coupling of trunk and
%arm 


%%%%Stage 0 -- Library and Constant Setup%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%See setupPath.m to ensure all paths are correctly set.
setupPath()

%Select all folders of subject data to process kinematic stats for --
%returns 0 on a cancelled selection
foldersToProcess = uipickfiles();

%Process those subjects
if(iscell(foldersToProcess))
    for procFolder=1:size(foldersToProcess,2)
        
        %Need to get the ResPosMat for this session
        resPosMat = [];
        
        %Calc Cross Corrs
        [CC,LAG,bounds1] = crosscorr(resPosMat(:,2),resPosMat(:,reachHand));
        [ll1,maxCC] = max(abs(CC));
        disp(LAG(maxCC))

        %Generate Graph
        figure,stem(LAG1,CC1);hold on, plot(LAG1,bounds1(1),'r'),plot(LAG1,bounds1(2),'r')
        xlabel('lag'),ylabel('crosscorr'),title('good')
    end
end
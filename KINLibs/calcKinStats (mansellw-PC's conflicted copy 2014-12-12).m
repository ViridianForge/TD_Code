function [ reachKinStats ] = calcKinStats( kinEventData, reachHand, ...
    trialDur, hdTkAngs, tkCBOSAngs )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CALCKINSTATS Function that calculates relevant statistics for a given
%reach's data.
%   This function serves to calculate all the relevant statistics from a
%   given reaches Kinematic data.
%
%   Author -- Wayne Manselle
%   Creation Date -- January 2013
%   See -- reachStatProcessor.m from Staci Wood's Honors Thesis Project
%
%   INPUTS -- kinEventData -- the Kinematic Data from the reach/grasp event
%   to be analyzed.
%          -- reachHand -- the numerical designation of the hand that is
%             reaching.  4 is Left, 5 is Right.  Numbering is legacy from
%             older implementations of these statistics.
%          -- trialDur -- Duration of the trial in seconds.  Used to
%          calculate velocities.
%          -- hdTkAngs -- Array of angles between Head COM and Trunk COM
%          over time
%          -- tkCBOSAngs -- Array of angles between Trunk COM and CBOS over
%          time
%   OUTPUTS -- reachKinStats -- the table of statistics gleaned from thie
%   given kinematic data.
%           -- resPosMat -- Matrix of the x,y,z resultant position of the
%           kinematic markers.  Largely will be used for graph purposes.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   reachKinStats Table Organization
%   Col 1 -- Path Length Reaching Hand
%   Col 2 -- Path Speed of Reaching Hand
%   Col 3 -- Peak Velocity of the Reaching Hand
%   Col 4 -- Peak Velocity Onset Time as Percentage of Total Reach Time
%   Col 5 -- Straightness scores of Reaching Hand
%   Col 6 -- Number of movement units of Reaching Hand
%   Col 7 -- Avg ML headTrunkCOM Angle -- degrees
%   Col 8 -- StDev ML headTrunkCOM Angle -- degrees
%   Col 9 -- Min ML headTrunkCOM Angle -- degrees
%   Col 10 -- Max ML headTrunkCOM Angle -- degrees
%   Col 11 -- Abs. Avg ML headTrunkCOM Angular Velocity -- degrees/sec
%   Col 12 -- Avg ML headTrunkCOM Angular Velocity -- degrees/sec
%   Col 13 -- Std ML headTrunkCOM Angular Velocity -- degrees/sec
%   Col 14 -- Total ML headTrunkCOM Angular Displacement -- degrees
%   Col 15 -- Avg AP headTrunkCOM Angle -- degrees
%   Col 16 -- StDev AP headTrunkCOM Angle -- Degrees
%   Col 17 -- Min AP headTrunkCOM Angle -- degrees
%   Col 18 -- Max AP headTrunkCOM Angle -- degrees
%   Col 19 -- Abs. Avg AP headTrunkCOM Angular Velocity -- degrees/sec
%   Col 20 -- Avg AP headTrunkCOM Angular Velocity -- degrees/sec
%   Col 21 -- Std AP headTrunkCOM Angular Velocity -- degrees/sec
%   Col 22 -- Total AP headTrunkCOM Angular Displacement -- degrees
%   Col 23 -- Avg Resultant headTrunkCOM Speed --  degrees/sec
%   Col 24 -- Total Resultant headTrunkCOM Angular Displacement -- degrees/sec
%   Col 25 -- Avg ML TrunkCOMCBOS Angle -- degrees
%   Col 26 -- StDev ML TrunkCOMCBOS Angle -- degrees
%   Col 27 -- Min ML TrunkCOMCBOS Angle -- degrees
%   Col 28 -- Max ML TrunkCOMCBOS Angle -- degrees
%   Col 29 -- Abs. Avg ML TrunkCOMCBOS Angular Velocity -- degrees/sec
%   Col 30 -- Avg ML TrunkCOMCBOS Angular Velocity -- degrees/sec
%   Col 31 -- Std ML TrunkCOMCBOS Angular Velocity -- degrees/sec
%   Col 32 -- Total ML TrunkCOMCBOS Angular Displacement -- degrees
%   Col 33 -- Avg AP TrunkCOMCBOS Angle -- degrees
%   Col 34 -- StDev AP TrunkCOMCBOS Angle -- degrees
%   Col 35 -- Min AP TrunkCOMCBOS Angle -- degrees
%   Col 36 -- Max AP TrunkCOMCBOS Angle -- degrees
%   Col 37 -- Abs. Avg AP TrunkCOMCBOS Angular Velocity -- degrees/sec
%   Col 38 -- Avg AP TrunkCOMCBOS Angular Velocity -- degrees/sec
%   Col 39 -- Std AP TrunkCOMCBOS Angular Velocity -- degrees/sec
%   Col 40 -- Total AP TrunkCOMCBOS Angular Displacement -- degrees
%   Col 41 -- Avg Resultant TrunkCOMCBOS Speed --  degrees/sec
%   Col 42 -- Total Resultant TrunkCOMCBOS Angular Displacement -- degrees/sec
%   Col 43 -- Normalized Jerk Squared -- Hz (inverse seconds)
%   Col 44 -- Total Path Length in AP Axis of Reaching Hand -- cm
%   Col 45 -- Total Path Length in AP Axis of TrunkCOM -- cm
%   Col 46 -- Trunk Coupling of Reach Motion -- cm
%   Col 47 -- Mean Curvature of the Reach -- Unitless
%   Col 48 -- Standard Deviation of Curvature of the Reach -- Unitless
%   Col 49 -- Cross Correlation between trunk and arm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Storage array for all stats from this reach.
reachKinStats = zeros(1,49);

%A chunk of code to create the timeline to graph motion in various planes
%against.  Grabbing the length of one of the matrix columns, as they're all
%the same length in the end.
timeLine = zeros(1,length(kinEventData(:,4)));
for i=1:length(kinEventData(:,4))
    timeLine(i) = i*0.0119;
end

%Calculate resultant Position, Velocity, and Acceleration Data
%Equation learned by Jennifer in Li-Shan Chou's Biomechanics course.  
resPosMat = zeros(size(kinEventData,1),5);
resPosDiffMat = zeros(size(kinEventData,1)-1,5);
sScoreResMat = zeros(1,5);
for i=1:5
    resPosMat(1,i) = sqrt(kinEventData(1,3*i+1)^2 + ...
            kinEventData(1,3*i+2)^2 + kinEventData(1,3*i+3)^2);
    for j=2:size(kinEventData,1)
        resPosDiffMat(j-1,i) = sqrt((kinEventData(j,3*i+1)-kinEventData(j-1,3*i+1))^2 + ...
            (kinEventData(j,3*i+2)-kinEventData(j-1,3*i+2))^2 + ...
            (kinEventData(j,3*i+3)-kinEventData(j-1,3*i+3))^2);
        resPosMat(j-1,i) = sqrt(kinEventData(j,3*i+1)^2 + ...
            kinEventData(j,3*i+2)^2 + kinEventData(j,3*i+3)^2);
    end
    sScoreResMat(i) = sqrt((kinEventData(end,3*i+1)-kinEventData(1,3*i+1))^2 + ...
        (kinEventData(end,3*i+2)-kinEventData(1,3*i+2))^2 + ...
        (kinEventData(end,3*i+3)-kinEventData(1,3*i+3))^2);
end

%Perform Cross Correlation Analysis between the trunk and arm to determine
%whether or not the movement is coupled.

%Temporary Code, whip out some of those graphs that Pablo put together.
[CC1,LAG1,bounds1] = crosscorr(resPosMat(:,2),resPosMat(:,reachHand));
[ll1,maxCC1] = max(abs(CC1));
disp('Lag Value for this reach');
disp(LAG1(maxCC1))

figure,stem(LAG1,CC1);hold on, plot(LAG1,bounds1(1),'r'),plot(LAG1,bounds1(2),'r')
xlabel('lag'),ylabel('crosscorr'),title('No Title')


reachKinStats(49) = max(abs(crosscorr(resPosMat(:,2),resPosMat(:,reachHand))));

%Calculate Component Velocities and Accelerations
%Using MATLAB's built in differentiation function, which specifically is
%calculating the nth difference along dimension x.  (i.e. the 1st
%difference along dimension 1 in the velocity calculation)
resVelMat = resPosDiffMat./0.0119;
resAccMat = diff(resPosDiffMat,1,1)./0.0119;

%Separating out the Velocity and Acceleration of the x,y,z components of
%the reaching hand for Curvature calculations
reachHandVel = diff(kinEventData(:,reachHand:reachHand+2))./0.0119;
reachHandAcc = diff(reachHandVel)./0.0119;

reachHandVel = reachHandVel(1:end-1,:);

%Calculate the Mean-Squared Jerk and log
njs = normalizedJerkSquared(resPosDiffMat(:,reachHand),11.9);
reachKinStats(43) = njs;

curv=zeros(size(reachHandAcc,1),1);

%Calculate the Curvature of the Reach
for curvCnt=1:size(reachHandAcc,1)
    curv(curvCnt) = (sqrt((reachHandAcc(curvCnt,3)*reachHandVel(curvCnt,2)-reachHandAcc(curvCnt,2)*reachHandAcc(curvCnt,3))^2+...
        (reachHandAcc(curvCnt,1)*reachHandVel(curvCnt,2)-reachHandAcc(curvCnt,3)*reachHandVel(curvCnt,1))^2+...
        (reachHandAcc(curvCnt,2)*reachHandVel(curvCnt,1)-reachHandAcc(curvCnt,1)*reachHandVel(curvCnt,2))^2))...
        /((reachHandVel(curvCnt,1)^2+reachHandVel(curvCnt,2)^2+reachHandVel(curvCnt,3)^2)^(3/2));
end

reachKinStats(47) = mean(curv);
reachKinStats(48) = std(curv);

%Calculate Path Lengths
%Built-in summation method, sums matrix along columns.
pathLens = sum(resPosDiffMat);

%Set Path Length and Speed of the reaching Hand.
reachKinStats(1) = pathLens(reachHand);
%Convert Trial Duration to Seconds to get pathLength Speed per second
reachKinStats(2) = pathLens(reachHand)/trialDur;

%Calculate Straightness Scores
sScores = zeros(1,5);
for sCnt = 1:length(sScores)
    sScores(sCnt) = pathLens(sCnt)/sScoreResMat(sCnt);
end

%Set Straightness Score
reachKinStats(5) = sScores(reachHand);

%Calculate Movement Units
mvUnits = zeros(1,5);
for mvCnt = 1:length(mvUnits)
    mvUnits(mvCnt) = calcMovementUnits(resVelMat(:,mvCnt),timeLine(2:end));
end

%Set Movement Units
reachKinStats(6) = mvUnits(reachHand);

%Calculate Peak Velocity, Acceleration, and their Times (in % of total
%movement duration).
peakVels = zeros(1,5);
peakVelTimes = zeros(1,5);
peakAccs = zeros(1,5);
peakAccTimes = zeros(1,5);
for i=1:5
    [peakVels(i),peakVelTimes(i)] = max(resVelMat(:,i));
    [peakAccs(i),peakAccTimes(i)] = max(resAccMat(:,i));
    %Calculation here is done by dividing the location in datapoints the
    %peak velocity/acceleration occurs by the number of
    %velocity/acceleration datapoints there are to get a percentage into
    %the reach that the peak occurs.
    peakVelTimes(i) = peakVelTimes(i)/(size(resVelMat,1));
    peakAccTimes(i) = peakAccTimes(i)/(size(resAccMat,1));
end

%Set Peak Velocities and Peak Velocity Times of the Reaching hand
reachKinStats(3) = peakVels(reachHand);
reachKinStats(4) = peakVelTimes(reachHand);

%Begin work on the angular stats for the stat matrix.
[angRows, angCols] = size(hdTkAngs);

%Matrix for storing angular displacement in both planes.
hdTkAngDispMat = zeros(angRows-1,2);
tkCBOSAngDispMat = zeros(angRows-1,2);

%Calculate the angular displacements in the ML and AP planes.  This is done
%by calculating how far 
for dispCalcs=2:angRows
    hdTkAngDispMat(dispCalcs-1,1)=hdTkAngs(dispCalcs,1)-hdTkAngs(dispCalcs-1,1);
    hdTkAngDispMat(dispCalcs-1,2)=hdTkAngs(dispCalcs,2)-hdTkAngs(dispCalcs-1,2);
    tkCBOSAngDispMat(dispCalcs-1,1)=tkCBOSAngs(dispCalcs,1)-tkCBOSAngs(dispCalcs-1,1);
    tkCBOSAngDispMat(dispCalcs-1,2)=tkCBOSAngs(dispCalcs,2)-tkCBOSAngs(dispCalcs-1,2);
end

%Matrix for storing the resultant of the angular displacements
hdTkAngResDispMat = sqrt(hdTkAngDispMat(:,1).^2+hdTkAngDispMat(:,2).^2);
tkCBOSAngResDispMat = sqrt(tkCBOSAngDispMat(:,1).^2+tkCBOSAngDispMat(:,2).^2);

%Calculate and Properly Place the primary angular statistics we care about.
outOffsets = [6,24];
for angType=1:2
    %Assign each group to our passthrough arrays as we need them.
    outAng = zeros(angRows-1,2);
    if(angType==1)
        outAng = hdTkAngs;
        outAngDispMat = hdTkAngDispMat;
        outAngResDisp = hdTkAngResDispMat;
    else
        outAng = tkCBOSAngs;
        outAngDispMat = tkCBOSAngDispMat;
        outAngResDisp = tkCBOSAngResDispMat;
    end
    %Place the angular displacements and other stats.
    %Output array addressing is determined algorithmically here.
    %hdC7 arrays go in 7-20
    %c7CBOS arrays go in 21-33
    reachKinStats(1+outOffsets(angType)) = mean(outAng(:,1));%7,25  ML Mean
    reachKinStats(2+outOffsets(angType)) = std(outAng(:,1));%8,26  ML StDev
    reachKinStats(3+outOffsets(angType)) = kinExtentFlexExt(outAng(:,1), 0); %9,27%Change to Jennifer's Special ML Min
    reachKinStats(4+outOffsets(angType)) = kinExtentFlexExt(outAng(:,1), 1); %10,28%Change to Jennifer's Special ML Max
    %NOTE -- Calculation alteration 02/07/2014 by Victor and Wayne
    %Angular Velocity = Total Angular Displacement / Length of Trial
    %(Degrees/Sec)
    reachKinStats(5+outOffsets(angType)) = (sum(abs(outAngDispMat(:,1))))./trialDur;%11,29 Abs. Avg ML Velocity
    reachKinStats(6+outOffsets(angType)) = mean(outAngDispMat(:,1)./0.0119); %12,30 Avg. ML Velocity
    reachKinStats(7+outOffsets(angType)) = std(outAngDispMat(:,1)./0.0119); %13,31 Std. ML Velocity
    reachKinStats(8+outOffsets(angType)) = sum(abs(outAngDispMat(:,1)));%14,32 ML Path Length
    reachKinStats(9+outOffsets(angType)) = mean(outAng(:,2));%15,33 AP Mean
    reachKinStats(10+outOffsets(angType)) = std(outAng(:,2));%16,34 AP STD
    
    reachKinStats(11+outOffsets(angType)) = kinExtentFlexExt(outAng(:,2), 0);%17,35 Change to Jennifer's Special AP Min
    reachKinStats(12+outOffsets(angType)) = kinExtentFlexExt(outAng(:,2), 1);%18,36 Change to Jennifer's Special AP Max
    %NOTE -- Calculation alteration 02/07/2014 by Victor and Wayne
    %Angular Velocity = Total Angular Displacement / Length of Trial
    %(Degrees/Sec)
    reachKinStats(13+outOffsets(angType)) = (sum(abs(outAngDispMat(:,2))))./trialDur;%19,37 Abs. Avg AP Velocity
    reachKinStats(14+outOffsets(angType)) = mean(outAngDispMat(:,2)./0.0119);%20,38 Avg AP Velocity
    reachKinStats(15+outOffsets(angType)) = std(outAngDispMat(:,2)./0.0119);%21,39 Avg AP Velocity
    reachKinStats(16+outOffsets(angType)) = sum(abs(outAngDispMat(:,2)));%22,40 AP Path Length
    reachKinStats(17+outOffsets(angType)) = mean(outAngResDisp)./0.0119;%23,41 Mean Result Velocity
    reachKinStats(18+outOffsets(angType)) = sum(outAngResDisp);%24,42 Total Resultant Path length
end

%Calculate the total 
totPLYReach = 0;
totPLYTrunk = 0;
for ind=2:size(kinEventData,1)
    totPLYReach=totPLYReach+(abs(kinEventData(ind,(3*reachHand)+2)-kinEventData(ind-1,(3*reachHand)+2)));
    totPLYTrunk=totPLYTrunk+(abs(kinEventData(ind,11)-kinEventData(ind-1,11)));
end

%Total Y Axis Path Length for the Reaching Hand
reachKinStats(44)=totPLYReach;
%Total Y Axis Path Length for the Trunk COM -- This should be column 11
reachKinStats(45)=totPLYTrunk;
%Total Reach Coupling - This is determined by calculating the percentage of
%the reaching hand's Y excursion that can be derived from the trunk's Y
%excursion.
reachKinStats(46)=(totPLYTrunk/totPLYReach)*100;
end
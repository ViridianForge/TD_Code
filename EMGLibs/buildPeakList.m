function [ peakList, edgeLens ] = buildPeakList( HBC, threshold )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%BUILDPEAKLIST Builds list of peak locations for EKG analysis
%   This function examines a set of EMG data, looking for EKG peaks
%   breaking the threshold for EKG activity.  A list of potential peaks and
%   their surrounding candidate locations are returned.
%
%AUTHOR:  Wayne Manselle -- Februrary 2014
%
%INPUTS:  HBC - The Heartbeat Channel of EMG information
%         Threshold - The Threshold of potential EKG activity
%
%OUTPUTS: peakList - the list of peaks as time points in the EMG.
%         edgeLens - the locations of edge centering for the EKG events
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Set up an array to store data locations of RPeaks and the QRS Lengths
QMin=7;
edgeLens=[];
peakList = [];
peakCount=1;

%Set up a variable for the heart beat channel, pulled from the demeaned
%Heart Beat EMG electrode.  Currently, we're multiplying by -1 in order
%to do calculations with an inverse QRS wave.
%Currently permanently set to 1 for dual threshold analysis
polarity=sign(threshold);
cThresh=threshold*polarity;
HBC=HBC.*polarity;

while(peakCount<length(HBC)-40)
    count=0;
    %Test if the current data point is above the threshold
    pks=peakCount;
    if(HBC(pks) >= cThresh)
        %Positive Threshold matched, check the area for QRS wave
        %Check forward in the data array, counting the number of points
        %above the threshold
        while(HBC(pks) >= cThresh)
            count = count + 1;
            pks = pks+1;
        end
        %If the number of points counted is greater than QMin, this is a 
        %QRS Record the max point from i to j as the R-Peak.
        if(count >= QMin)
            [C,I]=max(HBC(peakCount:pks));%maximum value from QRS wave,
            %having found the R Peak, assemble the distances for the PQRST
            %form
            QMem = (peakCount+I);
            QTest = (peakCount+I) - 1;
            SMem = (peakCount+I);
            STest = (peakCount+I) + 1;
            %Place Holders for QRS locations
            QLoc = 0;
            RLoc = 0;
            SLoc = 0;
            %while our current potential Q or S point is greater than a possible
            %Q or S point, make the possible potential the current
            %potential.
            %The 30 here prevents us from picking a Q in the HBC that would
            %possibly put us over the beginning point of the data.
            %Positive Threshold, starting our Search from the R
            if(polarity>=0)
                RLoc = (peakCount+I)-1;
                while(HBC(QMem) >= HBC(QTest))&&(HBC(QMem) >=30)
                    QMem = QTest;
                    QTest = QTest-1;
                end
                QLoc = QMem;
                while(HBC(SMem) >= HBC(STest))
                    SMem = STest;
                    STest = STest+1;
                end
                SLoc = SMem;
            else
                %Not Actually Q S Search, R S search
                %Will refactor when its working
                QLoc = (peakCount+I)-1;
                while(HBC(SMem) >= HBC(STest))&&(HBC(SMem) >=30)
                    SMem = STest;
                    STest = STest+1;
                end
                RLoc = SMem;
                while(HBC(SMem) <= HBC(STest))
                    SMem = STest;
                    STest = STest+1;
                end
                SLoc = SMem;
            end
            edgeLen = (SLoc - QLoc);
            %Finally Assemble the RPeakList and Distance Lists
            peakList = [peakList,RLoc];
            edgeLens = [edgeLens, edgeLen];
            %Update J to reflect stepping past the T point
            pks=(SMem+10);
        end
    end
    %Set the main counter forward 1 data point beyond T to avoid
    %overlapping PQRST waveforms as much as possible
    peakCount=pks+1;
end
end
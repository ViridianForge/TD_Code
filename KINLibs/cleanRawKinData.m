function [ procKinTrialData ] = cleanRawKinData(kinTrialData, bosData, kinSampRate)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CLEANRAWKINDATA -- Runs each Kinematic Trial File through its basic
%centering and filtration steps.
%   The purpose of this function is to run the kinematic trial data through
%   each stage of its processing, and return processed trial data for the
%   primary data processing stages, thus facilitating the upper stages of
%   Victor and Jennifer's Longitudinal Study Data Analysis.
%
%   Author:  Wayne Manselle
%   Creation Data: January 2013
%
%   INPUTS -- kinTrialData -- kinematic data that has not be yet centered
%   around the base of support or converter into metric.
%          -- markData -- the data table related to the marks collected at
%                         the beginning of the kinematic data collection.
%          -- rpiData -- the rpiData, whatever rpi ever meant.
%          -- bosData -- the Base of Support Data
%          -- kinSampRate -- The rate of kinematic data sampling
%
%   OUTPUTS -- procKinTrialData -- the processed Kinematic Data from the
%                                  trial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Zero all the data to the Center of Base of Support.
[nRows, nCols] = size(kinTrialData);
centeredTrialData = kinTrialData;

%Isolate the Center of Base of Support Data.  -- temp for mental acuity.
%cbos = bosData(3,7:9);

%Subtract each component of the center of base of support from the relevant
%components of the raw kinematic data.  This will center each data point
%around the center of base of support in the data collection.

%Convert all data from Imperial into CM
centeredTrialData(:,2:end) = centeredTrialData(:,2:end) .* 2.54;

%Set up storage for the filtered data.
procKinTrialData = zeros(size(centeredTrialData));

%Also filter the data with a 4Hz Low-Pass 4th order Butterworth
%(suggested by Sandy) to smooth the data, the 10Hz is in line with
%Hofsten's methodology.
nyquist = kinSampRate/2; %Nyquist frequency of 84hz collection rate
[b,a]=butter(4,(4/nyquist));
for i=1:nCols
    procKinTrialData(:,i) = filtfilt(b,a,centeredTrialData(:,i));
end

end
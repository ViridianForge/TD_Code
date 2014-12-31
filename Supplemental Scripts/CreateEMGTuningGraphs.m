%Goal, create compass-styled "tuning" graphs of EMG data.

%Load Normalized EMG and Angular Position files for the subject
angularData = csvread('C:\Users\mansellw\Desktop\TD01\11 SESSION 04 03 2013\Output\Kinematics\Pelvic\reachAngData\compiledAngularData_1_US_1.csv',1,0);
emgData = csvread('C:\Users\mansellw\Desktop\TD01\11 SESSION 04 03 2013\Output\EMG\Pelvic\ReachTrials\emgTrial1.csv',1,0);

%Likely have to downsample the EMG to match with the Kinematic Data

%Once the datasets match up, begin 
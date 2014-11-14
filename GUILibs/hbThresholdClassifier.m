function [ threshold ] = hbThresholdClassifier( hbChan )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%HBCLASSIFER - Allows User to Visually Classify Threshold and Polarity of
%a Heart Beat.
%   
%   This function presents the user a GUI.  That GUI presents the user with
%   the entirety of a EKG signal, and asks them to identify both the amplitude
%   threshold identifying a QRS waveform and the polarity of the signal.
%
%   Author - Wayne Manselle - February 2014
%
%   INPUTS - hbChan - the EKG data to presented to the user
%   OUTPUTS - posThreshold - the positive polarity amplitude threshold 
%           selected by the user.
%           - negThreshold - the negative polarity amplitude threshold
%           selected by the user.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Create a timeline to plot the EMG against.
time=.001:.001:(size(hbChan,1)/1000);

%Population the polarity and threshold values.
%Use nan for ease of checking of completeness.
threshold = nan;

%Create the uiPanel that's going to hold all this stuff.
emgPane = figure('units','normalized','outerposition',[0 0 1 1]);
%Create the selection buttons that will go to the left of the graphs
btnGrp = uibuttongroup('visible','off','Position',[0 0 .2 1],'parent',emgPane);

%Buttons we need.  One to select Threshold.

posThreshBtn = uicontrol('Style','pushbutton','String','Choose Threshold',...
    'Units','Normalized','pos',[0.2 0.7 0.5 0.05],'parent',btnGrp,...
    'HandleVisibility','off');

%Add labels for threshold levels?

endBtn = uicontrol('Style','pushbutton','String','Accept and Close',...
    'Units','Normalized','pos',[0.2 0.1 0.5 0.05],'parent',btnGrp,...
    'HandleVisibility','off');

%Graph the HB Channel for viewing.

%Separate uiPanel to isolate the plot.
plotPane = uipanel('visible','off','Parent',emgPane,'Position',[.2 0 .8 1]);
%Plot the EKG signal
hbHandle = plot(time,hbChan,'b');
hold on
threshHandle = plot([time(1) time(end)],[0 0],'r-','Visible','off');
hold on

%Label the plot
title('Heart Beat Channel')
xlabel('Time (s)')
ylabel('Amplitude (V)')

%Make the current axes parent the plot pane.
set(gca,'Parent',plotPane)

%Final settings.  Set the callback functions, that no radio button is
%selected, and that everything is visible.
set(gca,'XLim',[min(time)-1,max(time)+1])
set(posThreshBtn,'Callback',{@selectThreshold,threshHandle});
set(endBtn,'Callback',{@completeProcessing});
set(btnGrp,'Visible','on');
set(plotPane,'Visible','on');
uiwait()

    %Locally defined callback function.
    %Destroys the previously selected onset, and prompts the user to select a
    %new one.
    %hObject -- handle of the boundObject
    %eventData -- eventData coming along for the ride.
    function selectThreshold(hObject,eventData, onsetHandle)
        %We need a new onset, get to work!
        set(onsetHandle,'Visible','off')
        %The very act of clicking on the axis will make that the
        %current axis, so the nested figures above shouldn't give us
        %too much trouble.
        [x,threshold] = ginput(1);
        %The onset time coming out here will be based on the contents
        %of the X axis, which should be from -PreEvent Time to End of
        %Event time.  Adjustments may have to be made on output to get
        %that back to datapoints.
        set(onsetHandle,'YData',[threshold threshold])
        set(onsetHandle,'Visible','on')
    end

    function completeProcessing(hObject,eventdata)
        if(~isnan(threshold))
            %Verified done.  Exit.
            uiresume(gcbf);
            delete(emgPane)
            close(gcf)
        else
            %Some channels not selected.  Warn and return to main.
            uiwait(warndlg('Please choose a threshold before exiting.','Warning','modal'));
        end
    end
end
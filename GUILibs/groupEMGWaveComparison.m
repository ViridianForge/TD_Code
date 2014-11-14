function [ chosenEMG ] = groupEMGWaveComparison( adjEMGData, subHBEMG,...
    subWaveForm, chanTitles )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%GROUPEMGWAVECOMPARISON
%   This function displays to the user a side-by-side comparison of each
%   EMG channel from both the demeaned EMG data, and the EMG data that has
%   had its calculated HB component removed.
%
%   Author -- Wayne Manselle -- March 2013
%
%   INPUTS -- demeanedEMGData - the previously demeaned EMG data
%          -- subHBEMG - the demeaned EMG with the avg HB removed.
%          -- subWaveForm - the HB data subtracted from the EMG.
%          -- chanTitles - Titles to be appended to Plot Titles.
%   OUTPUTS -- chosenEMG - the EMG channels that are kept during the
%   decision process.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Set up the looping variables based on the data available.
[nmRows, nmChans] = size(adjEMGData);

%Create storage for the mashup of the EMG.
chosenEMG = zeros(nmRows, nmChans);

%Create a timeline to plot the EMG again.
time=.001:.001:(nmRows/1000);

%The heart beat and trigger channels need to go along for the ride, so we
%pass them on manually from the adjusted EMG data.  Technically, between
%both types of EMG, these channels are identical.
chosenEMG(:,nmChans-1) = adjEMGData(:,nmChans-1);
chosenEMG(:,nmChans) = adjEMGData(:,nmChans);

%Loop over all the muscular channels to build the highlighted listbox text.
lbStrings = cell(1,(length(chanTitles)-2));
lbStrings{1} = cell2mat(lbHighlighter(chanTitles(1),2));
%Minus 2 is here so we don't add HB and Trig channels to the decider
%unnecessarily.
for chanT=2:length(chanTitles)-2
    lbStrings{chanT} = cell2mat(lbHighlighter(chanTitles(chanT),3));
end

%Chosen Channel Settings for button selection
chosenChans = zeros(1,length(chanTitles)-2);

%Create the uiPanel that's going to hold all this stuff.
emgPane = figure('units','normalized','outerposition',[0 0 1 1]);
%Create the selection buttons that will go to the left of the graphs
btnGrp = uibuttongroup('visible','off','Position',[0 0 .2 1],'parent',emgPane);
%Channel Selecting List Box,Two Radio Buttons, one for the Demeaned Data,
%one of HB Subtracted Data
eCCLabel = uicontrol('Style','text','Units','Normalized',...
    'pos',[0.25 0.85 0.5 0.05],'string','EMG Channels',...
    'parent',btnGrp,'HandleVisibility','off','FontWeight','bold',...
    'FontSize',16);
eChChoose = uicontrol('Style','listbox','Units','Normalized',...
    'pos',[0.25 0.6 0.5 0.25],'string',lbStrings, ...
    'parent',btnGrp,'HandleVisibility','off');
btnOne = uicontrol('Style','radiobutton','String','Unaltered EMG',...
    'Units','Normalized','pos',[0.25 0.5 0.5 0.05],'parent',btnGrp,'HandleVisibility','off');
btnTwo = uicontrol('Style','radiobutton','String','HB Subtracted EMG',...
    'Units','Normalized','pos',[0.25 0.45 0.5 0.05],'parent',btnGrp,'HandleVisibility','off');
repickBtn = uicontrol('Style','pushbutton','String','Reprocess HB Channel',...
    'Units','Normalized','pos',[0.25 0.3 0.5 0.05],'parent',btnGrp,'HandleVisibility','off');
endBtn = uicontrol('Style','pushbutton','String','Accept and Close',...
    'Units','Normalized','pos',[0.25 0.2 0.5 0.05],'parent',btnGrp,'HandleVisibility','off');
saveGraph = uicontrol('Style','pushbutton','String','Export Graph',...
    'Units','normalized','pos',[0.25,0.1,0.5,0.05],'parent',btnGrp,...
    'HandleVisibility','off');
%Trying a separating uiPanel to isolate the plots.
plotPane = uipanel('visible','off','Parent',emgPane,'Position',[.2 0 .8 1]);
%Now Let's make us some plots.
subplot(3,1,1,'parent',plotPane);
adjEMGPlot = plot(time,adjEMGData(:,1),'b');
title('Unaltered EMG Waveform')
set(gca,'XLim',[min(time)-1,max(time)+1])
%Plot the average HB for this channel for visual comparison
subplot(3,1,2,'parent',plotPane);
subAHBPlot = plot(time,subWaveForm(:,1),'g');
%Set the Y axis limits to match the EMG channels for comparison
set(gca,'XLim',[min(time)-1,max(time)+1])
set(gca,'YLim',[min(adjEMGData(:,1)),max(adjEMGData(:,1))])
title('Average HB Waveform')
subplot(3,1,3,'parent',plotPane);
subEMGPlot = plot(time,subHBEMG(:,1),'r');
title('Demeaned EMG Waveform with Average HB Signal Subtracted')
%Final settings.  Set the callback functions, that no radio button is
%selected, and that everything is visible.
set(gca,'XLim',[min(time)-1,max(time)+1])
set(btnGrp,'SelectedObject',[]);
set(eChChoose,'CallBack',{@drawEMGData,adjEMGPlot,subAHBPlot,subEMGPlot});
%set(confBtn,'Callback',{@selectPlot,eChChoose});
set(btnOne,'Callback',{@selectPlot,eChChoose});
set(btnTwo,'Callback',{@selectPlot,eChChoose});
set(repickBtn,'Callback',{@repickHB});
set(endBtn,'Callback',{@completeProcessing});
set(saveGraph,'Callback',{@exportGraph,eChChoose});
set(btnGrp,'Visible','on');
set(plotPane,'Visible','on');
uiwait()

%Locally Defined Listbox Callback Function
%hObject -- the handle of the bound object
%eventdata -- unused, required by callback template.
%adjAx -- Axes of the plot of adjusted EMG data.
%subAx -- Axes of the plot of subtracted EMG data.
    function drawEMGData(hObject,eventdata,adjAx,aHBAx,subAx)
        selChan = get(hObject,'Value');
        set(adjAx,'YData',adjEMGData(:,selChan))
        set(aHBAx,'YData',subWaveForm(:,selChan))
        set(get(aHBAx,'Parent'),'YLim',[min(adjEMGData(:,selChan)),max(adjEMGData(:,selChan))])
        set(subAx,'YData',subHBEMG(:,selChan))
        if(chosenChans(selChan)==0)
            selButton = [];
        elseif(chosenChans(selChan)==1)
            selButton = btnOne;
        else
            selButton = btnTwo;
        end
        set(btnGrp,'SelectedObject',selButton);
        %Set the color of the label to reflect visitation
        if(chosenChans(selChan)==0)
            lbStrings{get(hObject,'Value')} = ...
                cell2mat(lbHighlighter(chanTitles(get(hObject,'Value')),2));
        else
            lbStrings{get(hObject,'Value')} = ...
                cell2mat(lbHighlighter(chanTitles(get(hObject,'Value')),1));
        end
        set(hObject,'string',lbStrings)
    end

%Locally Defined Pushbutton Callback Function
%hObject -- the handle of the bound object.
%eventdata -- unused, required by callback template.
%compare -- the listbox handle, used to get which channel number
%currently being compared.
    function selectPlot(hObject,eventdata,compare)
        %Get the channel value.
        selChan = get(compare,'Value');
        %Get the string
        compareString = get(hObject,'String');
        %Three cases, one of two options selected, or nothing selected.
        if(strcmp(compareString,'Unaltered EMG'))
            %Proceed with Unaltered EMG
            chosenEMG(:,selChan) = adjEMGData(:,selChan);
            chosenChans(selChan) = 1;
        elseif(strcmp(compareString,'HB Subtracted EMG'))
            %Proceed with Subtracted
            chosenEMG(:,selChan) = subHBEMG(:,selChan);
            chosenChans(selChan) = 2;
        else
            warndlg('No Waveform Selected.  Please select a waveform before clicking "Accept"');
            %Nothing Selected, Do Nothing
        end
        %If the user chose a value, update the coloration to reflect this.
        if(chosenChans(selChan)==1 || chosenChans(selChan)==2)
            lbStrings{get(compare,'Value')} = ...
                cell2mat(lbHighlighter(chanTitles(get(compare,'Value')),1));
            set(eChChoose,'string',lbStrings)
        end
    end

    function repickHB(hObject,eventdata)
        faReview = questdlg('Would you like to choose a different HB Threshold?','Re-examine HB Channel?','Yes','No','Yes');
        if(strcmp(faReview,'Yes'))
            chosenEMG=-1;
            uiresume(gcbf);
            delete(emgPane)
            close(gcf)
        end
    end

    function completeProcessing(hObject,eventdata)
        if(isempty(find(chosenChans == 0,1)))
            %Verified done.  Exit.
            uiresume(gcbf);
            delete(emgPane)
            close(gcf)
        else
            %Some channels not selected.  Warn and return to main.
            uiwait(warndlg('Not all channels have been assigned.  Please assign all channels before exiting.','Warning','modal'));
        end
    end

%Exports the currently selected set of subplots to a graph type of the
%user's choosing.
    function exportGraph(hObject,eventData,chanList)
        filtSpec = {'*.jpg','JPEG Image';'*.png','PNG Image';...
            '*.pdf','PDF Document';'*.fig','Matlab Figure'};
        %Get the filename to export to.
        [graphFile, graphPath] = ...
            uiputfile(filtSpec,'Export Graph As...','visComparison.jpg');
        %Build a temporary output figure for saving purposes.
        selIndex = (get(chanList,'Value'));
        image = figure('Visible','off');
        %Generate a copy of the currently existing plot in a new figure for
        %saving purposes.  Delete the figure once the data is saved.
        subplot(3,1,1);
        adjEMGPlot = plot(time,adjEMGData(:,selIndex),'b');
        title('Unaltered EMG Waveform')
        set(gca,'XLim',[min(time)-1,max(time)+1])
        %Plot the average HB for this channel for visual comparison
        subplot(3,1,2);
        subAHBPlot = plot(time,subWaveForm(:,selIndex),'g');
        %Set the Y axis limits to match the EMG channels for comparison
        set(gca,'XLim',[min(time)-1,max(time)+1])
        set(gca,'YLim',[min(adjEMGData(:,selIndex)),max(adjEMGData(:,selIndex))])
        title('Average HB Waveform')
        subplot(3,1,3);
        subEMGPlot = plot(time,subHBEMG(:,selIndex),'r');
        title('Demeaned EMG Waveform with Average HB Signal Subtracted')
        %Final settings.  Set the callback functions, that no radio button is
        %selected, and that everything is visible.
        set(gca,'XLim',[min(time)-1,max(time)+1])
        saveas(image, [graphPath graphFile]);
        delete(image)
        msgbox('Graph Export Complete!','Success','help','modal');
    end
end
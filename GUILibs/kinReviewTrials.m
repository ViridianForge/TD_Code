function [ acceptableKin ] = kinReviewTrials( trialData, bosData )
%KINREVIEWTRIALS Graphically review trial data, and approve correctness.
%   This function is a reworking of previous EMG multi-graphical
%   presentation code in order to allow the user to review all kinematic
%   reach trials to verify the acceptability of those trials.
%
%AUTHOR: Wayne Manselle -- January 2014
%
%CHANGELOG: 01.22.2014 -- Initial Creation
%
%INPUTS: trialData -- the collection of kinematic trials to plot
%        bosData -- the level's base of support data use in plotting the
%        base of support circle
%
%OUTPUTS: acceptableKin -- the array containing the evaluations of the
%kinematic trials

%Build the Trial Strings
trialStrings = cell(1,(size(trialData,1)));
for trialNum=1:size(trialData,1)
    trialStrings{trialNum} = ['Kinematic Trial ' num2str(trialNum)];
end
lbStrings = trialStrings;
lbStrings{1} = cell2mat(lbHighlighter(trialStrings(1),1));

%Set up output array
acceptableKin = nan(size(trialData,1),1);

%Create the uiPanel that's going to hold all this stuff.
kinPane = figure('units','normalized','outerposition',[0 0 1 1]);
%Create the selection buttons that will go to the left of the graphs
btnGrp = uibuttongroup('visible','off','Position',[0 0 .2 1],'parent',kinPane);
%Channel Selecting List Box,Two Radio Buttons, one for the Demeaned Data,
%one of HB Subtracted Data
kinTCLabel = uicontrol('Style','text','Units','Normalized',...
    'pos',[0.25 0.9 0.5 0.05],'string','Kinematic Trials',...
    'parent',btnGrp,'HandleVisibility','off','FontWeight','bold',...
    'FontSize',16);
kinChoose = uicontrol('Style','listbox','Units','Normalized',...
    'pos',[0.25 0.6 0.5 0.25],'string',lbStrings, ...
    'parent',btnGrp,'HandleVisibility','off');
btnOne = uicontrol('Style','radiobutton','String','Bad Kinematcs',...
    'Units','Normalized','pos',[0.25 0.4 0.5 0.05],'parent',btnGrp,'HandleVisibility','off');
btnTwo = uicontrol('Style','radiobutton','String','Good Kinematics',...
    'Units','Normalized','pos',[0.25 0.35 0.5 0.05],'parent',btnGrp,'HandleVisibility','off');
endBtn = uicontrol('Style','pushbutton','String','Accept and Close',...
    'Units','Normalized','pos',[0.25 0.3 0.5 0.05],'parent',btnGrp,'HandleVisibility','off');
saveGraph = uicontrol('Style','pushbutton','String','Export Graph',...
    'Units','normalized','pos',[0.25,0.1,0.5,0.05],'parent',btnGrp,...
    'HandleVisibility','off');
%Trying a separating uiPanel to isolate the plots.
plotPane = uipanel('visible','off','Parent',kinPane,'Position',[.2 0 .8 1]);
plotAxes = axes('Parent',plotPane);
%Plot the first trial of data as a seed
acceptableKin(1) = 1;
trialMatrix = trialData{1};
axes(plotAxes);
[bosX,bosY]=ellipse((bosData(1,1)-bosData(3,7)),(bosData(2,2)-bosData(3,8)),0,0,0,'b');
bosE=line(bosX,bosY);
set(bosE,'Color','b','LineWidth',1,'LineStyle','-')
hold on
axis([-15 15 -25 25])
hold on
%Plot the Head
headPlot=plot(trialMatrix(:,5),trialMatrix(:,6), 'r.');
hold on
%Plot C7
c7Plot=plot(trialMatrix(:,8),trialMatrix(:,9), 'y.');
hold on
%Plot Left Hand
lHandPlot=plot(-trialMatrix(:,14),trialMatrix(:,15), 'm.');
hold on
%Plot Right Hand
rHandPlot=plot(-trialMatrix(:,17),trialMatrix(:,18), 'g.');
hold on
xlabel('Motion in ML plane (in)')
ylabel('Motion in AP plane (in)')
title('2D Kinematic Trial Data')
%Populate Button Callbacks
set(btnGrp,'SelectedObject',btnTwo);
set(kinChoose,'CallBack',{@drawKinData,trialData,bosData});
set(btnOne,'Callback',{@selectPlot,kinChoose});
set(btnTwo,'Callback',{@selectPlot,kinChoose});
set(endBtn,'Callback',{@completeProcessing});
set(saveGraph,'Callback',{@exportGraph,kinChoose});
set(btnGrp,'Visible','on');
set(plotPane,'Visible','on');
%set(emgPane,'CloseRequestFcn','')
uiwait()

%Locally Defined Listbox Callback Function
%hObject -- the handle of the bound object
%eventdata -- unused, required by callback template.
%plotData -- the collection of Kinematic Data to plot from
%bosData -- The Base of Support data to draw from for adjusting plot
    function drawKinData(hObject,eventdata,plotData,bosData)
        selTrial = get(hObject,'Value');
        if(isnan(acceptableKin(selTrial)))
            acceptableKin(selTrial) = 1;
        end
        %Plot the data
        trialMatrix = plotData{selTrial};
        set(headPlot,'XData',trialMatrix(:,5),'YData',trialMatrix(:,6))
        set(c7Plot,'XData',trialMatrix(:,8),'YData',trialMatrix(:,9))
        set(lHandPlot,'XData',-trialMatrix(:,14),'YData',trialMatrix(:,15))
        set(rHandPlot,'XData',-trialMatrix(:,17),'YData',trialMatrix(:,18))
        if(acceptableKin(selTrial))
            selButton = btnTwo;
        else
            selButton = btnOne;
        end
        set(btnGrp,'SelectedObject',selButton);
        %Set the color of the label to reflect visitation
        lbStrings{get(hObject,'Value')} = ...
                cell2mat(lbHighlighter(lbStrings(get(hObject,'Value')),...
                2-acceptableKin(selTrial)));
        set(hObject,'string',lbStrings)
    end

%Locally Defined Pushbutton Callback Function
%hObject -- the handle of the bound object.
%eventdata -- unused, required by callback template.
%compare -- the listbox handle, used to get which channel number
%currently being compared.
    function selectPlot(hObject,eventdata,compare)
        %Get the channel value.
        selTrial = get(compare,'Value');
        %Get the string
        compareString = get(hObject,'String');
        %Three cases, one of two options selected, or nothing selected.
        if(strcmp(compareString,'Bad Kinematcs'))
            %Mark this Kinematic Data for ignoring
            acceptableKin(selTrial) = 0;
        elseif(strcmp(compareString,'Good Kinematics'))
            %Mark this Kinematic Data for being good to use
            acceptableKin(selTrial) = 1;
        else
            %Nothing Selected -- Impossible so render a weird value
            acceptableKin(selTrial) = -1;
        end
        %If the user chose a value, update the coloration to reflect this.
        %1 -- Green -- Good trial
        %2 -- Yellow -- Not a good Trial
        %3 -- Red -- 
        colorCode=2-acceptableKin(selTrial);
        lbStrings{selTrial} = ...
            cell2mat(lbHighlighter(trialStrings(selTrial),colorCode));        
        set(kinChoose,'string',lbStrings)
    end

%Button to accept current set of evaluations, check if any trial hasn't
%been looked over, if all are good, continue on.
    function completeProcessing(hObject,eventdata)
        if(isempty(find(isnan(acceptableKin),1)))
            %Verified done.  Exit.
            uiresume(gcbf);
            delete(kinPane)
            close(gcf)
        else
            %Some channels not selected.  Warn and return to main.
            uiwait(warndlg('Not all channels have been assigned.  Please assign all channels before exiting.','Warning','modal'));
        end
    end

%Exports the currently selected set of subplots to a graph type of the
%user's choosing.
    function exportGraph(hObject,eventData,trialList)
        filtSpec = {'*.jpg','JPEG Image';'*.png','PNG Image';...
            '*.pdf','PDF Document';'*.fig','Matlab Figure'};
        %Get the filename to export to.
        [graphFile, graphPath] = ...
            uiputfile(filtSpec,'Export Graph As...','visComparison.jpg');
        %Build a temporary output figure for saving purposes.
        selIndex = (get(trialList,'Value'));
        image = figure('Visible','off');
        %Generate a copy of the currently existing plot in a new figure for
        %saving purposes.  Delete the figure once the data is saved.
        bosE=line(bosX,bosY);
        set(bosE,'Color','b','LineWidth',1,'LineStyle','-')
        axis([-15 15 -25 25])
        hold on
        title(['Trial ' num2str(selIndex)])
        %Plot the Head
        plot(-trialMatrix(:,5),trialMatrix(:,6), 'r.');
        hold on
        %Plot C7
        plot(-trialMatrix(:,8),trialMatrix(:,9), 'y.');
        hold on
        %Plot Left Hand
        plot(-trialMatrix(:,11)*2.54,trialMatrix(:,12), 'm.');
        hold on
        %Plot Right Hand
        plot(-trialMatrix(:,14),trialMatrix(:,15), 'g.');
        hold on
        xlabel('Motion in ML plane (in)')
        ylabel('Motion in AP plane (in)')
        title('2D Kinematic Trial Data')
        %Final settings.  Set the callback functions, that no radio button is
        %selected, and that everything is visible.
        saveas(image, [graphPath graphFile]);
        delete(image)
        msgbox('Graph Export Complete!','Success','help','modal');
    end
end
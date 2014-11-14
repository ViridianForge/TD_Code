function visualComparison(dataset1, dataset2, data1String, data2String, titles, ...
    specXData,xlab,ylab,gxlim,gxtick,gylim,gytick)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%VISUALCOMPARISON GUI for easy comparison of signal based datasets.
%   This functional allows for a user to select between channels of data,
%   and compare those channels between two different data sets.
%   This was written with the intent of allow researchers working on the
%   Gonzalez-Rachwani Postural Control study to examine EMG before and
%   after specific processing methodologies.
%
%Author: Wayne Manselle - March 2013
%
%INPUTS: dataset1 - The first dataset
%        dataset2 - The second dataset
%        data1String - Descriptive text for the first dataset
%        data2String - Descriptive text for the second dataset
%        titles - Shared channel titles between datasets
%        specXData - Specific X Data to plot y data against (OPTIONAL)
%        xlab - X Axis Label (OPTIONAL)
%        ylab - Y Axis Label (OPTIONAL)
%        gxlim - Limits of Graph 1 X axis (OPTIONAL)
%        gylim - Limits of Graph 1 Y axis (OPTIONAL)
%        gxtick - Tick Marks of Graph 1 X axis (OPTIONAL)
%        gytick - Tick Marks of Graph 1 Y axis (OPTIONAL)
%
%NOTES:  This function as it stands will only work on two datasets with an
%identical number of channels.  This function may be useful to future
%researchers if its robustness were improved.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Input tests for function.  If there is anything less than the total number
%of input arguments (for now), set all the graph implementation to default.
useDefaultXData = 1;
useDefaultLabels = 1;
useGraphXDefaults = 1;
useGraphYDefaults = 1;

if(nargin >= 6)
    useDefaultXData = 0;
end

if(nargin >= 8)
    useDefaultLabels = 0;
end

if(nargin >= 10)
    useGraphXDefaults = 0;
end

if(nargin >= 12)
    useGraphYDefaults = 0;
end

%Set up the main container for the control figure
visualReviewPane = figure('units','normalized','outerposition',[0 0 1 1]);

%Set up the buttons we need to interact with the system.  Currently, I
%think we just need one button to tell the system to pick a new onset, and
%a second to accept that onset.

btnGrp = uibuttongroup('visible','off','Position',[0 0 .2 1],'parent',visualReviewPane);

eCCLabel = uicontrol('Style','text','Units','normalized',...
    'pos',[0.25,0.9,0.5,0.05],'string','EMG Channels',...
    'parent',btnGrp,'HandleVisibility','off','FontWeight','bold',...
    'FontSize',16);

eChChoose = uicontrol('Style','listbox','Units','normalized',...
    'pos',[0.25,0.65,0.5,0.25],'string',titles, ...
    'parent',btnGrp,'HandleVisibility','off');

finishBtn = uicontrol('Style','pushbutton','String','Done Reviewing',...
    'Units','normalized','pos',[0.25,0.5,0.5,0.05],'parent',btnGrp,...
    'HandleVisibility','off');

saveGraph = uicontrol('Style','pushbutton','String','Export Graph',...
    'Units','normalized','pos',[0.25,0.1,0.5,0.05],'parent',btnGrp,...
    'HandleVisibility','off');

%Pane for the Subplot component of our visual comparison system.
plotPane = uipanel('visible','off','Parent',visualReviewPane,'Position',[.2 0 .8 1]);

%Seed the analysis module with base data.
subplot(2,1,1, 'Parent',plotPane)
if(~useDefaultXData)
    plot(specXData,dataset1(:,1),'b')
else
    plot(dataset1(:,1),'b')
end
title([titles{1} data1String])

if(~useDefaultLabels)
    xlabel(xlab)
    ylabel(ylab)
end
if(~useGraphXDefaults)
    set(gca,'XLim',gxlim)
    set(gca,'xticklabel',gxtick)
end
if(~useGraphYDefaults)
    set(gca,'YLim',gylim)
    set(gca,'yticklabel',gytick)
end

%Second Plot
subplot(2,1,2,'Parent',plotPane)
if(~useDefaultXData)
    plot(specXData,dataset2(:,1),'r')
else
    plot(dataset2(:,1),'r')
end
if(~useDefaultLabels)
    xlabel(xlab)
    ylabel(ylab)
end
if(~useGraphXDefaults)
    set(gca,'XLim',gxlim)
    set(gca,'xticklabel',gxtick)
end

if(~useGraphYDefaults)
    set(gca,'YLim',gylim)
    set(gca,'yticklabel',gytick)
end
title([titles{1} data2String])

%Set up callback functions.
set(eChChoose,'CallBack',{@updateComparison,eChChoose});
set(finishBtn,'Callback',{@finishReview,visualReviewPane});
set(saveGraph,'Callback',{@exportGraph,eChChoose});
%Make things visible
set(btnGrp,'Visible','on')
set(plotPane,'Visible','on')
%This code prevents the window from being closed by the little 'X' in the
%corner.  Workaround for possible User Error.
%set(visualReviewPane,'CloseRequestFcn','')
%Keep the Display Active until we've finished.
uiwait()

%Updates the channels presented in the subplots that are being
%compared.
    function updateComparison(hObject,eventData,chanList)
        %Retrieve the index of the currently selected muscle channel.
        selIndex = (get(chanList,'Value'));
        %Update the Plots
        subplot(2,1,1,'Replace','Parent',plotPane)
        if(~useDefaultXData)
            plot(specXData,dataset1(:,selIndex),'b')
        else
            plot(dataset1(:,selIndex),'b')
        end
        if(~useDefaultLabels)
            xlabel(xlab)
            ylabel(ylab)
        end
        if(~useGraphXDefaults)
            set(gca,'XLim',gxlim)
            set(gca,'xticklabel',gxtick)
        end
        if(~useGraphYDefaults)
            set(gca,'YLim',gylim)
            set(gca,'yticklabel',gytick)
        end
        title([titles{selIndex} data1String])
        subplot(2,1,2,'Replace','Parent',plotPane)
        if(~useDefaultXData)
            plot(specXData,dataset2(:,selIndex),'r')
        else
            plot(dataset2(:,selIndex),'r')
        end
        if(~useDefaultLabels)
            xlabel(xlab)
            ylabel(ylab)
        end
        if(~useGraphXDefaults)
            set(gca,'XLim',gxlim)
            set(gca,'xticklabel',gxtick)
        end
        if(~useGraphYDefaults)
            set(gca,'YLim',gylim)
            set(gca,'yticklabel',gytick)
        end
        title([titles{selIndex} data2String])
    end

%Dismisses the channel review UI.
    function finishReview(hObject,eventData,uiPane)
        uiresume(gcbf)
        delete(visualReviewPane)
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
        %Update the Plots
        subplot(2,1,1,'Replace','Parent',plotPane)
        plot(specXData,dataset1(:,selIndex),'b')
        if(~useDefaultLabels)
            xlabel(xlab)
            ylabel(ylab)
        end
        if(~useGraphXDefaults)
            set(gca,'XLim',gxlim)
            set(gca,'xticklabel',gxtick)
        end
        if(~useGraphYDefaults)
            set(gca,'YLim',gylim)
            set(gca,'yticklabel',gytick)
        end
        title([titles{selIndex} data1String])
        subplot(2,1,2,'Replace','Parent',plotPane)
        plot(specXData,dataset2(:,selIndex),'r')
        if(~useDefaultLabels)
            xlabel(xlab)
            ylabel(ylab)
        end
        if(~useGraphXDefaults)
            set(gca,'XLim',gxlim)
            set(gca,'xticklabel',gxtick)
        end
        if(~useGraphYDefaults)
            set(gca,'YLim',gylim)
            set(gca,'yticklabel',gytick)
        end
        title([titles{selIndex} data2String])
        saveas(image, [graphPath graphFile]);
        delete(image)
        msgbox('Graph Export Complete!','Success','help','modal');
    end
end
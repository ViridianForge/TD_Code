function visMultChans( xVisData, yVisData, titles, xLabelText, yLabelText, titleText, xTicks, yTicks )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Wayne, you need to write documentation for this function

%VISMULTCHANS Summary of this function goes here
%   Detailed explanation goes here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Constants
plotAxis=0;
useDefaultXTicks = 1;
useDefaultYTicks = 1;

if(nargin >= 7)
    useDefaultXTicks = 0;
end

if(nargin >= 8)
    useDefaultYTicks = 0;
end

%Create the uiPanel that's going to hold all this stuff.
emgPane = figure('units','normalized','outerposition',[0 0 1 1]);

btnGrp = uibuttongroup('visible','off','Position',[0 0 .2 1],'parent',emgPane);


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


%Graph the HB Channel for viewing.

%Separate uiPanel to isolate the plot.
plotPane = uipanel('visible','off','Parent',emgPane,'Position',[.2 0 .8 1]);
updateComparison(eChChoose,0)

%Make the current axes parent the plot pane.
set(gca,'Parent',plotPane)

%Final settings.  Set the callback functions and make components visible.
set(eChChoose,'CallBack',{@updateComparison});
set(finishBtn,'Callback',{@completeProcessing});
set(saveGraph,'Callback',{@exportGraph,eChChoose});
set(btnGrp,'Visible','on');
set(plotPane,'Visible','on');
uiwait()

%Locally defined callback function.
%Destroys the previously selected onset, and prompts the user to select a
%new one.
%hObject -- handle of the boundObject
%eventData -- eventData coming along for the ride.
    function updateComparison(hObject,eventData)
        %Retrieve the index of the currently selected muscle channel.
        selIndex = (get(hObject,'Value'));
        %Begin by creating the construct axes that we'll be plotting into in.  Our
        %methods will use these handles to update the plotted data.
        if(plotAxis==0)
            subplot(1,1,1, 'Parent', plotPane)
            plot(xVisData(:,selIndex),yVisData(:,selIndex)); grid on
            
            plotAxis=1;
        else
            subplot(1,1,1,'Replace','Parent', plotPane)
            plot(xVisData(:,selIndex),yVisData(:,selIndex)); grid on
        end
        %Labelling the Graph
        xlabel(xLabelText)
        ylabel(yLabelText)
        title(titleText)
        if(~useDefaultXTicks)
            set(gca,'XLim',[min(xTicks) max(xTicks)])
            set(gca,'XTick',xTicks)
        end
        if(~useDefaultYTicks)
            set(gca,'YLim',[min(yTicks) max(yTicks)])
            set(gca,'YTick',yTicks)
        end
    end

    function completeProcessing(hObject,eventdata)
        %Verified done.  Exit.
        uiresume(gcbf);
        delete(emgPane)
        close(gcf)
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
        subplot(1,1,1,'Replace','Parent',plotPane)
        plot(xVisData(:,selIndex),yVisData(:,selIndex)); grid on
        xlabel(xLabelText)
        ylabel(yLabelText)
        title(titleText)
        if(~useDefaultXTicks)
            set(gca,'XLim',[min(xTicks) max(xTicks)])
            set(gca,'XTick',xTicks)
        end
        if(~useDefaultYTicks)
            set(gca,'YLim',[min(yTicks) max(yTicks)])
            set(gca,'YTick',yTicks)
        end
        saveas(image, [graphPath graphFile]);
        delete(image)
        msgbox('Graph Export Complete!','Success','help','modal');
    end
end
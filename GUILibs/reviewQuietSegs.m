function reviewQuietSegs( procEMG, quietSegLims, emgTitles )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%REVIEWQUIETSEGS Plots Quiet Segment Information for Review
%   A customized version of the multi-channel visualization tool, allowing
%   for plotting an arbitrary number of levels of data collection at once
%
%Author - Wayne Manselle - May 2014
%
%Inputs - procEMG - All channels of EMG across levels
%         quietSegLims - The locations where quiet segments of data were
%         detected
%         emgTitles - the names of EMG channels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Set up the main container for the control figure
visualReviewPane = figure('units','normalized','outerposition',[0 0 1 1]);

%Globals for indicating need to initialize object, and to hold on to a
%handle for plot exportation.
plotAxis=0;

%Set up the buttons we need to interact with the system.  Currently, I
%think we just need one button to tell the system to pick a new onset, and
%a second to accept that onset.

btnGrp = uibuttongroup('visible','off','Position',[0 0 .2 1],'parent',visualReviewPane);

eCCLabel = uicontrol('Style','text','Units','normalized',...
    'pos',[0.25,0.9,0.5,0.05],'string','EMG Channels',...
    'parent',btnGrp,'HandleVisibility','off','FontWeight','bold',...
    'FontSize',16);

eChChoose = uicontrol('Style','listbox','Units','normalized',...
    'pos',[0.25,0.65,0.5,0.25],'string',emgTitles, ...
    'parent',btnGrp,'HandleVisibility','off');

finishBtn = uicontrol('Style','pushbutton','String','Done Reviewing',...
    'Units','normalized','pos',[0.25,0.5,0.5,0.05],'parent',btnGrp,...
    'HandleVisibility','off');

saveGraph = uicontrol('Style','pushbutton','String','Export Graph',...
    'Units','normalized','pos',[0.25,0.1,0.5,0.05],'parent',btnGrp,...
    'HandleVisibility','off');

%Pane for the Subplot component of our visual comparison system.
plotPane = uipanel('visible','off','Parent',visualReviewPane,'Position',[.2 0 .8 1]);

updateComparison(eChChoose,0)

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
            for sGraph=1:size(procEMG,1)
                tempData = procEMG{sGraph};
                subplot(size(procEMG,1),1,sGraph, 'Parent', plotPane)
                plot(tempData(:,selIndex),'Color',[0.25 0.25 0.25])
                hold on
                %Check to see if this is the appropriate graph to place the
                %Quiet Onset Markers
                if(sGraph==quietSegLims(selIndex,3))
                    line([quietSegLims(selIndex,1) quietSegLims(selIndex,1)],[-2 max(tempData(:,selIndex))+2],'Color',[1 0.41 0.71])
                    hold on
                    line([quietSegLims(selIndex,2) quietSegLims(selIndex,2)],[-2 max(tempData(:,selIndex))+2],'Color',[1 0.41 0.71])
                    hold on
                    %Replot the subsection of quiet data, so it stands out
                    %starkly.
                    plot(quietSegLims(selIndex,1):quietSegLims(selIndex,2),tempData(quietSegLims(selIndex,1):quietSegLims(selIndex,2),selIndex),'b')
                    hold on
                end
                xlim([0 size(tempData,1)])
                ylim([-2 max(tempData(:,selIndex))+2])
                title(['Level: ' num2str(sGraph)])
            end
            plotAxis=1;
        else
            for sGraph=1:size(procEMG,1)
                tempData = procEMG{sGraph};
                subplot(size(procEMG,1),1,sGraph,'Replace','Parent', plotPane)
                plot(tempData(:,selIndex),'Color',[0.25 0.25 0.25])
                if(sGraph==quietSegLims(selIndex,3))
                    line([quietSegLims(selIndex,1) quietSegLims(selIndex,1)],[-2 max(tempData(:,selIndex))+2],'Color',[1 0.41 0.71])
                    hold on
                    line([quietSegLims(selIndex,2) quietSegLims(selIndex,2)],[-2 max(tempData(:,selIndex))+2],'Color',[1 0.41 0.71])
                    hold on
                    %Replot the subsection of quiet data, so it stands out
                    %starkly.
                    plot(quietSegLims(selIndex,1):quietSegLims(selIndex,2),tempData(quietSegLims(selIndex,1):quietSegLims(selIndex,2),selIndex),'b')
                    hold on
                end
                xlim([0 size(tempData,1)])
                ylim([-2 max(tempData(:,selIndex))+2])
                title(['Level: ' num2str(sGraph)])
            end
        end
    end

    function completeProcessing(hObject,eventdata)
        %Verified done.  Exit.
        uiresume(gcbf);
        delete(visualReviewPane)
        close(gcf)
    end

%Exports the currently selected set of subplots to a graph type of the
%user's choosing.
    function exportGraph(hObject,eventData,chanList)
        %Get the filename to export to.
        [graphFile, graphPath] = ...
            uiputfile({'*.jpg;*.tif;*.png;*.gif','All Image Files';'*.*','All Files'},'Save Image','quietSegs.png');
        plotOut=getframe(gcf);
        imwrite(plotOut.cdata,[graphPath graphFile]);
        msgbox('Graph Export Complete!','Success','help','modal');
    end


end
function [ verification, binEvals ] = guiActVerifier( activationPairs, normData, ...
                                reachData, preEventLength, binSize, pkAmps, ...
                                chanNames,normFactors, gTitle )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%GUIACTVERIFIER A graphical tool to evaluate the effacicy of the bin alg
%   This tool enables a user to evaluate the effacicy of the muscle onset
%   and offset auto picking algorthm.
%
%Author: Wayne Manselle - April 2014
%
%INPUTS: acitvationPairs - the automatically picked onset and offset times
%                          in a the given muscle channel.
%        normData - the IEMG of the bins of EMG activity
%        reachData - the processed EMG belonging to each reach
%        preEventLength - the amount of time, in ms, used for the baseline
%                         and APA region of the EMG event data
%        binSize - the length of each bin of EMG used for iEMG
%                  calculations, in ms
%        pkAmps - variable used to pass in peak amplitudes across leves if
%                 scaling the EMG visualized to these values is ever desired
%        chanNames - the names of the EMG channels used in this data
%                    collection
%        normFactors - The value in mV/ms of 1.0 on the normalized IEMG
%                      scale, for visual verifications
%        gTitle - the title to give the graphs
%OUTPUTS: verification - the percentage of correct picks by the alg
%         binEvals - the channel by channel performance evaluation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Prep the output containers
verification=0;

%We've defaulted to the alg being correct unless manipulated, so start
%everything in the arrays at 1.
binEvals=ones(size(reachData,2),1);

%Generate the label strings
%This might be unnecessary
lbStrings = cell(1,size(chanNames,2));
visited=zeros(size(lbStrings));
for label=1:size(lbStrings,2)
    lbStrings{label} = lbHighlighter(chanNames{label},3);
    visited(label) = 0;
end

%Trim the raw data to be the same width as the bin data
if(size(normData,1)*binSize ~= size(reachData,1))
    if(size(normData,1)*binSize > size(reachData,1))
        reachData = vertcat(reachData, nan((size(normData,1)*binSize-size(reachData,1)),size(reachData,2)));
    else
        reachData(end-(size(reachData,1)-size(normData,1)*binSize)+1:end,:) = [];
    end
end

%Code to ensure the EMG can be easily plotted against the IEMG bins and to
%ensure the IEMG bins can be plotted against the Signal
cmpNormData=zeros(size(reachData));

for chan=1:size(normData,2)
    cmpNormData(:,chan)=iemgPlotGenerator(normData(:,chan),binSize);
end

%Generate time references and Rereference to the beginning of the reach.
timeLine = 0:1:size(reachData,1)-1;

timeLine = timeLine-preEventLength;

%Generate a set of Tick marks at 100ms accuracy.
xTicks=min(timeLine):100:max(timeLine);

%Set up the main container for the control figure
onsetPane = figure('units','normalized','outerposition',[0 0 1 1]);

%Set up other graphical constants

plotAxis=0;
iEMGHandle=0;
emgHandle=0;
reachOnset=0;

%Set up the buttons we need to interact with the system.  Currently, I
%think we just need one button to tell the system to pick a new onset, and
%a second to accept that onset.

btnGrp = uibuttongroup('visible','off','Position',[0 0 .2 1],'parent',onsetPane);

eCCLabel = uicontrol('Style','text','Units','normalized',...
    'pos',[0.25,0.9,0.5,0.05],'string','EMG Channels',...
    'parent',btnGrp,'HandleVisibility','off','FontWeight','bold',...
    'FontSize',16);

eChChoose = uicontrol('Style','listbox','Units','normalized',...
    'pos',[0.25,0.65,0.5,0.25],'string',lbStrings, ...
    'parent',btnGrp,'HandleVisibility','off');

normLabel = uicontrol('Style','text','Units','normalized',...
    'pos',[0.2,0.5,0.75,0.05],'string','Norm Factor Here',...
    'parent',btnGrp,'HandleVisibility','off','FontWeight','bold',...
    'FontSize',14);

btnOne = uicontrol('Style','radiobutton','String','Algorithm Correct',...
    'Units','Normalized','pos',[0.25 0.4 0.5 0.05],'parent',btnGrp,'HandleVisibility','off');
btnTwo = uicontrol('Style','radiobutton','String','Algorithm Incorrect',...
    'Units','Normalized','pos',[0.25 0.35 0.5 0.05],'parent',btnGrp,'HandleVisibility','off');

acceptBtn = uicontrol('Style','pushbutton','String','Accept Burst Boundaries',...
    'Units','normalized','pos',[0.25,0.1,0.5,0.05],'parent',btnGrp,...
    'HandleVisibility','off');

saveGraph = uicontrol('Style','pushbutton','String','Export Current Plot',...
    'Units','normalized','pos',[0.25,0.2,0.5,0.05],'parent',btnGrp,...
    'HandleVisibility','off');

%Pane for the PlotYY component of onset selection to occupy.
plotPane = uipanel('visible','off','Parent',onsetPane,'Position',[.2 0 .8 1]);

drawScreen(eChChoose,0);

%Set Callbacks
set(eChChoose,'CallBack',{@drawScreen});
set(acceptBtn,'Callback',{@acceptOnset});
set(saveGraph,'Callback',{@exportGraph});
set(btnOne,'Callback',{@evalBinning, eChChoose})
set(btnTwo,'Callback',{@evalBinning, eChChoose})
%set(saveGraph,'Callback',{@exportGraph,eventBarBottom,eventBarTop,eChChoose});
%Make things visible
set(btnGrp,'Visible','on')
set(plotPane,'Visible','on')

uiwait()

    function drawScreen(hObject,eventData)
        %Plot the Data Portion of the Figure
        drawInd = get(hObject,'Value');
        
        %Clear previous onset and offset lines

        binMarks = findall(plotAxis, 'type', 'line', 'LineStyle','-.');
        delete(binMarks);
        
        %Update the Normalization Factor Text
        %The character code 10 here represents a newline character
        set(normLabel,'string',{'1.0 Norm. IEMG is: ', [num2str(normFactors(drawInd)) ' mv per bin']})
        
        %Set the Selection buttons correctly
        if(binEvals(get(hObject,'Value')))
            set(btnGrp,'SelectedObject',btnOne);
        else
            set(btnGrp,'SelectedObject',btnTwo);
        end
        
        %Note that this channel has been visited, color the channel name to
        %note.
        lbStrings{drawInd} = lbHighlighter(chanNames{drawInd},1);
        visited(drawInd)=1;
        set(hObject,'string',lbStrings)
        
        %I'm setting a specified top end limit for the Normalized axis
        %here.  This is because if, somehow, a muscle is largely inhibited
        %and has a normalized value rounds up to 0, the dvision throws
        %everything off.  I figured 2 was a decent upper bound, just to
        %keep the 1 line in view.
        normTop = max(ceil(max(cmpNormData(:,drawInd))),2);
        
        yTicksNorm = floor(min(cmpNormData(:,drawInd))):normTop/10:normTop;
        yTicksReach = floor(min(reachData(:,drawInd))):ceil(max(reachData(:,drawInd)))/10:ceil(max(reachData(:,drawInd)));
        
        
        %Begin by creating the construct axes that we'll be plotting into in.  Our
        %methods will use these handles to update the plotted data.
        if(plotAxis==0)
            [plotAxis, iEMGHandle, emgHandle] = plotyy(timeLine,cmpNormData(:,drawInd),timeLine,reachData(:,drawInd));
            %Set parents
            set(plotAxis(1),'Parent',plotPane)
            set(plotAxis(2),'Parent',plotPane)
            %Set the new X Ticks for each of the two plotyy axises.
            set(plotAxis(1),'XTick',xTicks);
            set(plotAxis(2),'XTick',xTicks);
            %Set Y Ticks for each plot to give an even 10 point listing
            %along the axises
            
            set(plotAxis(1),'YTick',yTicksNorm);
            set(plotAxis(2),'YTick',yTicksReach);
            %Set tick mode to manual so they are actually respected.
            set(plotAxis(1),'XTickMode','manual');
            set(plotAxis(2),'XTickMode','manual');
            set(plotAxis(1),'YTickMode','manual');
            set(plotAxis(2),'YTickMode','manual');
            %Labelling the Graph
            set(get(plotAxis(1),'Ylabel'),'String','Normalized Binned EMG Activity')
            set(get(plotAxis(2),'Ylabel'),'String','EMG Activity (mV)')
            xlabel('Time (ms)')
        else
            set(iEMGHandle,'YData',cmpNormData(:,drawInd))
            set(emgHandle,'YData',reachData(:,drawInd))
            %set(plotAxis(1),'YTick',floor(min(cmpNormData(:,drawInd))):10:ceil(max(cmpNormData(:,drawInd))));
            %set(plotAxis(2),'YTick',floor(min(reachData(:,drawInd))):10:ceil(max(reachData(:,drawInd))));
        end
       
        %Set Limits and Tick Mark locations for both sides of the graph
        %IEMG Axis Limits
        iEMGLowerLim=min(0,(round(min(cmpNormData(:,drawInd)))-1));
        set(plotAxis(1),'XLim',[min(timeLine) max(timeLine)],...
            'YLim', [floor(min(cmpNormData(:,drawInd))) normTop], ...
            'YTick',yTicksNorm)
        
        %EMG Axis Limits
        set(plotAxis(2),'XLim',[min(timeLine) max(timeLine)],...
            'YLim', [floor(min(reachData(:,drawInd))) ceil(max(reachData(:,drawInd)))], ...
            'YTick', yTicksReach)
        
        %Increase the Thickness of the Bin Line
        set(iEMGHandle,'LineWidth',2)
        hold on
        
        title(gTitle,'interpreter','none')
        
        %Define the limits of our event marking bars.
        eventBarBottom = 0;
        testBottom = min(min(reachData(:,get(eChChoose,'Value'))),...
                         min(cmpNormData(:,get(eChChoose,'Value'))));
        testTop = max(max(reachData(:,get(eChChoose,'Value'))),...
                         max(cmpNormData(:,get(eChChoose,'Value'))));
                     
        if(testBottom-1<eventBarBottom)
            eventBarBottom = round(testBottom)-1;
        end
        eventBarTop = round(testTop);
        
        %Plot the Reach Onset
        reachOnset = line([0 0],[eventBarBottom eventBarTop], ...
            'LineStyle',':','Color',[0 0 0],'Parent',plotAxis(1), 'LineWidth',2);
        hold on
        
        %Plot the iEMG Guideline
        line([timeLine(1) timeLine(end)], [1 1], 'LineStyle','--', ...
            'Color', [1 0 0],'Parent',plotAxis(1), 'LineWidth',2);
        hold on
        
        curPairs=activationPairs{get(eChChoose,'Value')};
        
        for pair=1:size(curPairs,1)
            %Convert the Pairs into the Referenced Graph Time
            activation = ((curPairs(pair,1)-1)*binSize)-preEventLength;
            deactivation = ((curPairs(pair,2)-1)*binSize)-preEventLength;
            %Quick catch for a muscle didn't actually turn off edge case.
            if((deactivation + binSize) >= timeLine(end))
                %Place the deactivation line slightly before the end of
                %time so that it is visualized.
                deactivation = timeLine(end)-1;
            end
            %Plot the Activation Onsets and Offsets
            line([activation activation],[eventBarBottom eventBarTop],...
                'LineStyle','-.','Color',[1 0.41 0.71],'Parent',plotAxis(1),...
                'LineWidth',2);
            hold on
            line([deactivation deactivation],[eventBarBottom eventBarTop],...
                'LineStyle','-.','Color',[1 0.41 0.71],'Parent',plotAxis(1),...
                'LineWidth',2);
            hold on
            %Draw a connecting line between the two at 5% below the maximum
            %value of the iEMG values.
            horzLineLoc = max(cmpNormData(:,get(eChChoose,'Value')))-...
                0.05*(max(cmpNormData(:,get(eChChoose,'Value'))));
            line([activation deactivation],[horzLineLoc horzLineLoc],...
                'LineStyle','-.','Color',[1 0.41 0.71],'Parent',plotAxis(1),...
                'LineWidth',2);
            hold on
        end
    end
    
    function evalBinning(hObject, eventData, chanList)
        if(strcmp(get(hObject,'String'),'Algorithm Incorrect'))
            %Mark this Kinematic Data for ignoring
            binEvals(get(chanList,'Value')) = 0;
        elseif(strcmp(get(hObject,'String'),'Algorithm Correct'))
            %Mark this Kinematic Data for being good to use
            binEvals(get(chanList,'Value')) = 1;
        else
            %Nothing Selected -- Impossible so render a weird value
            binEvals(get(chanList,'Value')) = -1;
        end
    end

    function exportGraph(hObject, eventData)
        %Get the filename to export to.
        [graphFile, graphPath] = ...
            uiputfile({'*.jpg;*.tif;*.png;*.gif','All Image Files';'*.*','All Files'},'Save Image','guiVerif.png');
        %This is simplistic compared to our other graph exports, but
        %hopefully will serve its purpose until more precise code can be
        %crafted.  Essentially, this makes a copy of the entire GUI as a
        %framecap and saves it out to a file.
        plotOut=getframe(gcf);
        imwrite(plotOut.cdata,[graphPath graphFile]);
        msgbox('Graph Export Complete!','Success','help','modal');
    end

    %Locally defined callback function.
    %Calls it good on the onset.  Destroys the picker and returns to the
    %game.
    %hObject -- handle of the boundObject
    %eventData -- eventData coming along for the ride.
    function acceptOnset(hObject,eventData)
        %Make sure every channel has been checked.
        if(isempty(find(visited == 0,1)))
            uiresume(gcbf)
            delete(onsetPane)
            verification=mean(binEvals);
        else
            uiwait(warndlg('Not all onsets have been reviewed.  Please review all onsets before exiting.','Warning','modal'));
        end
    end
end
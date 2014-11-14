function [ corrReachTimesMS, corrReachTimesDP ] = ...
    reviewReachOnsets( kinDataTable, reachTimes, reachCol, eventCodes, gTit, gOut)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%REVIEWREACHONSETS Allows users to review onset times and correct them.
%   This function using the passed inputs to display all kinematic data
%   corresponding to OpenSHAPA coded reaching regions to the user.  The
%   user is then allowed to refine those onset and offset times to better
%   match the kinematic data using the resultant position and velocity
%   profiles of the reach.
%
%AUTHOR: Wayne Manselle - February 2014
%INPUTS: kinDataTable - Tables of Kinematic Trial Data
%        reachTimes - Table consisting of OpenSHAPA coded kinematic
%        pre-reach onset, reach onset, and reach offset.
%        reachCol - the column of the kinematic data corresponding to the
%        reaching hand.
%        eventCodes - the openSHAPA codes associated with trials
%        gTit - The Title for the entire graph, reference to aid user
%OUTPUTS: corrReachTimesMS - the table of user corrected Reach onsets and
%         offsets in milliseconds.
%         corrReachTimesDP - the table of user corrected Reach onsets and
%         offsets in 84Hz datapoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Create the resPos and resVel data sets for each reach set.
resPosTable = cell(size(kinDataTable,1),1);
resVelTable = cell(size(kinDataTable,1),1);
timeLineTable = cell(size(kinDataTable,1),1);
dpPreEvent = zeros(size(reachTimes,1),1);

%Here, we loop over all of the kinematic trials retained, and obtain a
%subregion of the data corresponding to 500ms before the OpenSHAPA coded
%reach onset to the OpenSHAPA coded reach offset.
for tab=1:size(kinDataTable,1)
    %Calculate the resultant matrices for plotting
    curTable = kinDataTable{tab};
    %Test to make sure we're not trying to grab a dropped reach.
    if(reachTimes(tab,1)>0)
        curReachRegion = curTable(reachTimes(tab,2):reachTimes(tab,4),:);
        [resDiff, resPos] = calcKinResMat(curReachRegion(:,2:19));
        resPosTable{tab} = num2cell(resPos(:,reachCol)');
        
        %Tacking a nan on here so the timelines match up.  Doesn't make much
        %sense to spline a single point on the end.
        resVelTable{tab} = horzcat(nan,num2cell(resDiff(:,reachCol)'./(0.0119)));
        
        %Converting from kinematic data points into reach onset centered
        %ms.
        dpPreEvent(tab) = reachTimes(tab,2);
        reachTimes(tab,2)=(((reachTimes(tab,2)-dpPreEvent(tab))/84)*1000-500);
        reachTimes(tab,3)=(((reachTimes(tab,3)-dpPreEvent(tab))/84)*1000-500);
        reachTimes(tab,4)=(((reachTimes(tab,4)-dpPreEvent(tab))/84)*1000-500);
        timeLineTable{tab} = num2cell(reachTimes(tab,2):11.9:reachTimes(tab,4));
        
        %Generate a Resultant Velocity over time Graph for this data
        %Build and save the graph of the reach
        resVelFigure = figure('Visible','off','units','normalized','outerposition',[0 0 1 1]);
        plot(cell2mat(timeLineTable{tab}),cell2mat(resVelTable{tab}), 'LineWidth',2)
        
        %Specialized TickMarks for this graph
        tickSpace=25;
        if(max(cell2mat(timeLineTable{tab})) > 1300)
            tickSpace=100;
        elseif(max(cell2mat(timeLineTable{tab})) > 500)
            tickSpace=50;
        end
        xTic=min(cell2mat(timeLineTable{tab})):tickSpace:max(cell2mat(timeLineTable{tab}));
        %Set the new Ticks for each of the two plotyy axises.
        set(gca,'XTick',xTic);
        set(gca,'XLim',[min(cell2mat(timeLineTable{tab})) max(cell2mat(timeLineTable{tab}))],'FontSize',8)
        %Set tick mode to manual so they are actually respected.
        set(gca,'XTickMode','manual');
        %set(gca,'YTick',[]);
        %NOTE:  This line set the y limit to 120 cm/s for all graphs
        %output.  Change this if you need another scaling.
        set(gca,'YLim',[0 120])
        xlabel('Time (ms)')
        ylabel('Res. Vel (cm/s)')
        title([gTit ' Velocity Profile ' num2str(tab)], 'Interpreter','none')
        print('-dmeta','-r600',[gOut gTit '_' num2str(tab) '_VelProf.emf']);
    end
end

%Build the Trial Strings
trialStrings = {};
trialLinks=[];
reachVisited = [];
for eventNum=1:size(kinDataTable,1)
    if(reachTimes(eventNum,1)>0)
        trialStrings=...
            vertcat(trialStrings,{['Trial ' num2str(reachTimes(eventNum,1)) ' ' eventCodes{eventNum}]});
        trialLinks=horzcat(trialLinks,eventNum);
        reachVisited=horzcat(reachVisited,0);
    end
end
trialStrings{1} = cell2mat(lbHighlighter(trialStrings(1),1));
reachVisited(1)=1;

%Seed the initial current reach data.
curTrial = trialLinks(1);
curReachOn = reachTimes(1,3);
curResPos = cell2mat(resPosTable{curTrial});
curResVel = cell2mat(resVelTable{curTrial});
curTimeLine = cell2mat(timeLineTable{curTrial});

%Present graphs
%Set up the main container for the control figure
onsetPane = figure('units','normalized','outerposition',[0 0 1 1]);

btnGrp = uibuttongroup('visible','off','Position',[0 0 .2 1],'parent',onsetPane);

eCCLabel = uicontrol('Style','text','Units','normalized',...
    'pos',[0.25,0.9,0.5,0.05],'string','Kin Events',...
    'parent',btnGrp,'HandleVisibility','off','FontWeight','bold',...
    'FontSize',16);

eChChoose = uicontrol('Style','listbox','Units','normalized',...
    'pos',[0.25,0.65,0.5,0.25],'string',trialStrings, ...
    'parent',btnGrp,'HandleVisibility','off');

osPkBtn = uicontrol('Style','pushbutton','String','Pick Reach Onset',...
    'Units','normalized','pos',[0.25,0.45,0.5,0.05],'parent',btnGrp,...
    'HandleVisibility','off');

onLabel = uicontrol('Style','text','Units','normalized',...
    'pos',[0.2,0.39,0.75,0.05],'string',['Reach Onset: ' num2str(curReachOn)],...
    'parent',btnGrp,'HandleVisibility','off','FontWeight','bold',...
    'FontSize',14,'ForegroundColor',[0.225 0.75 0.25]);

acceptBtn = uicontrol('Style','pushbutton','String','Accept Reach Boundaries',...
    'Units','normalized','pos',[0.25,0.1,0.5,0.05],'parent',btnGrp,...
    'HandleVisibility','off');

saveGraph = uicontrol('Style','pushbutton','String','Export Current Plot',...
    'Units','normalized','pos',[0.25,0.2,0.5,0.05],'parent',btnGrp,...
    'HandleVisibility','off');

%Pane for the PlotYY component of onset selection to occupy.
plotPane = uipanel('visible','off','Parent',onsetPane,'Position',[.2 0 .8 1]);

%Plot the Data Portion of the Figure

%Begin by creating the construct axes that we'll be plotting into in.  Our
%methods will use these handles to update the plotted data.
[AX, H1, H2] = plotyy(curTimeLine,curResPos,curTimeLine,curResVel);

%Set parents
set(AX(1),'Parent',plotPane)
set(AX(2),'Parent',plotPane)

%Generate the tick marks for the X Axis.  Use a 50 ms spacing in cases
%where the x axis isn't likely to get clogged with labels.
tSpacing=25;
if(max(curTimeLine) > 1300)
    tSpacing=100;
elseif(max(curTimeLine) > 500)
    tSpacing=50;
end
xTicks=min(curTimeLine):tSpacing:max(curTimeLine);
%Set the new Ticks for each of the two plotyy axises.
set(AX(1),'XTick',xTicks);
set(AX(2),'XTick',xTicks);
%Set tick mode to manual so they are actually respected.
set(AX(1),'XTickMode','manual');
set(AX(2),'XTickMode','manual');

hold on

%Define the limits of our event marking bars.

eventBarBottom = round(min(min(curResPos),min(curResVel)))-0.1;
eventBarTop = round(max(max(curResPos),max(curResVel)))+0.1;

%Plot the reach onset.  Should only need to be done once.
kOnHnd = line([curReachOn curReachOn],[eventBarBottom eventBarTop], ...
    'LineStyle',':','Color',[0 0 0],'Parent',AX(2));
hold on

%Add Title.
title([gTit ' Kinematic Comparison'], 'Interpreter','none')
%Labelling the Graph
set(get(AX(1),'Ylabel'),'String','Res. Position(cm)')
set(get(AX(2),'Ylabel'),'String','Res. Velocity(cm^2)')
xlabel('Time (ms)')

%Set Limits and Tick Mark locations for both sides of the graph
%EMG Axis Limits
posMin=round2(min(curResPos),0.1)-0.1;
posMax=round2(max(curResPos),0.1)+0.1;
velMin=round2(min(curResVel),0.1)-0.1;
velMax=round2(max(curResVel),0.1)+0.1;

set(AX(1),'XLim',[min(curTimeLine) max(curTimeLine)],...
    'YLim', [posMin posMax], ...
    'YTick', (posMin:(posMax-posMin)/10:posMax),...
    'FontSize',8)

set(AX(2),'XLim',[min(curTimeLine) max(curTimeLine)],...
    'YLim', [velMin velMax], ...
    'YTick', (velMin:(velMax-velMin)/10:velMax),...
    'FontSize',8)

%Set callbacks
set(eChChoose,'CallBack',{@drawReach,AX,H2,H1,kOnHnd,onLabel});
set(osPkBtn,'Callback',{@pickOnset,kOnHnd,onLabel});
set(acceptBtn,'Callback',{@acceptOnset});
set(saveGraph,'Callback',{@exportGraph,eventBarBottom,eventBarTop,eChChoose});
%Make things visible
set(btnGrp,'Visible','on')
set(plotPane,'Visible','on')
uiwait()

%Locally defined inner function.
%Draws all plot graphics to the screen, dependent on the currently
%selected ListBox channel.
    function drawReachPlot(selIndex, reachEvPlot, velH, posH,...
            onsetHandle,onsetLabel)
        %Update the muscle aspects of the YYPlot.  Nothing should change
        %between plots save the Y data of the EMGChannel and onset times.
        curTrial = trialLinks(selIndex);
        curReachOn = reachTimes(curTrial,3);
        curTimeLine = cell2mat(timeLineTable{curTrial});
        curResPos = cell2mat(resPosTable{curTrial,:});
        curResVel = cell2mat(resVelTable{curTrial,:});
        
        %Adjust all the X and Y data, both for the displayed resultants,
        %but for the lengths of the onset bars.
        
        set(posH,'XData',curTimeLine)
        set(posH,'YData',curResPos)
        set(velH,'XData',curTimeLine)
        set(velH,'YData',curResVel)
        
        %Do a comparison of the greatest max, and greatest min between the
        %maxes and mins of curResPos and curResVel to get bar lengths.
        
        eventBarBottom = round2(min(min(curResPos),min(curResVel)),0.1)-0.1;
        eventBarTop = round2(max(max(curResPos),max(curResVel)),0.1)+0.1;
        
        reachVisited(selIndex) = 1;
        
        %Set onset.  Turn off "No onset Detected Message"
        set(onsetHandle,'XData',[curReachOn curReachOn])
        set(onsetHandle,'YData',[eventBarBottom eventBarTop])
        set(onsetHandle,'Visible','on')
        set(onsetLabel,'string',['Reach Onset: ' num2str(curReachOn)])
        hold on
        
        %Labelling the Graph
        set(get(reachEvPlot(1),'Ylabel'),'String','Res. Position(cm)')
        set(get(reachEvPlot(2),'Ylabel'),'String','Res. Velocity(cm/s)')
        xlabel('Time (ms)')
        
        %Generate a new set of Tick marks at 100ms accuracy.
        tSpacing=25;
        if(max(curTimeLine) > 1250)
            tSpacing=100;
        elseif(max(curTimeLine) > 500)
            tSpacing=50;
        end
        xTicks=min(curTimeLine):tSpacing:max(curTimeLine);
        
        %Set Limits and Tick Mark locations for both sides of the graph
        %EMG Axis Limits
        posMin=round2(min(curResPos),0.1)-0.1;
        posMax=round2(max(curResPos),0.1)+0.1;
        velMin=round2(min(curResVel),0.1)-0.1;
        velMax=round2(max(curResVel),0.1)+0.1;
        
        set(reachEvPlot(1),'XLim',[min(curTimeLine) max(curTimeLine)],...
            'XTick',xTicks,...
            'YLim', [posMin posMax], ...
            'YTick', (posMin:(posMax-posMin)/10:posMax),...
            'FontSize',8)
        
        set(reachEvPlot(2),'XLim',[min(curTimeLine) max(curTimeLine)],...
            'XTick',xTicks,...
            'YLim', [velMin velMax], ...
            'YTick', (velMin:(velMax-velMin)/10:velMax),...
            'FontSize',8)
        
        %Set linestylings and color
        set(posH,'LineStyle','-','Color','b')
        set(velH,'LineStyle','-','Color',[0 0.5 0])
        set(findall(posH,'type','text'),'fontSize',8,'fontWeight','bold')
        set(findall(velH,'type','text'),'fontSize',8,'fontWeight','bold')
    end

%Locally defined callback function.
%Replaces the currently drawn EMG Channel with the one selected in the
%listbox of EMG Channels
    function drawReach(hObject,eventData,reachEvPlot,velH,posH,onsetHandle,...
            onsetText)
        %Get the muscle channel selected.
        drawReachPlot((get(hObject,'Value')),reachEvPlot,velH,posH,...
            onsetHandle,onsetText)
        %Recolor the background of the text dependent on whether or not an
        %onset exists.
        trialStrings{get(hObject,'Value')} = ...
            cell2mat(lbHighlighter(trialStrings((get(hObject,'Value'))),1));
        set(hObject,'string',trialStrings)
    end

%Locally defined callback function.
%Destroys the previously selected onset, and prompts the user to select a
%new one.
%hObject -- handle of the boundObject
%eventData -- eventData coming along for the ride.
    function pickOnset(hObject,eventData, onsetHandle, onsetText)
        selIndex = get(eChChoose,'Value');
        curTimeLine = timeLineTable{selIndex};
        curTrial=trialLinks(selIndex);
        %We'll probably need to temporarily turn off the list onset
        %functionality?
        %Ask if the muscle ever activates.
        muscActQ = questdlg('In your opinion, does the onset for this reach need to be rechosen?',...
            'Pick an Onset?','Yes','No','Yes');
        if(strcmp(muscActQ,'No'))
            %Do Nothing
        else
            %We need a new onset, get to work!
            set(onsetHandle,'Visible','off')
            set(onsetText,'string','Choosing Reach Onset...')
            
            %It is entirely possible during this process to pick an onset
            %that would be impossible to
            picking=1;
            while(picking==1)
                %The very act of clicking on the axis will make that the
                %current axis, so the nested figures above shouldn't give us
                %too much trouble.
                [reachTimes(curTrial,3),y] = ginput(1);
                %Round the time to the nearest millisecond.
                reachTimes(curTrial,3) = round2(reachTimes(curTrial,3),.001);
                %Reset the preEvent time edge to reflect 500ms before the new
                %onset.  This is for record keeping and passing back out from
                %the tool.
                reachTimes(curTrial,2) = reachTimes(curTrial,3)-500;
                
                %Maybe some sort of negativity test?
                
                %The onset time coming out here will be based on the contents
                %of the X axis, which should be from -PreEvent Time to End of
                %Event time.  Adjustments may have to be made on output to get
                %that back to datapoints.
                if((((((reachTimes(curTrial,3))+500)/1000)*84)+dpPreEvent(curTrial))>=42)
                    picking=0;
                    set(onsetHandle,'XData',[reachTimes(curTrial,3) reachTimes(curTrial,3)])
                    set(onsetHandle,'Visible','on')
                    set(onsetText,'string',['Reach Onset: ' num2str(reachTimes(curTrial,3))])
                else
                    uiwait(warndlg('Onset chosen does not have 500ms of preEvent available in trial.  Please choose another onset.','Warning','modal'));
                end
            end
        end
        %Mark channel as visited.
        trialStrings{selIndex} = cell2mat(lbHighlighter(trialStrings(selIndex),1));
        set(eChChoose,'string',trialStrings)
    end

%Locally defined callback function.
%Calls it good on the onset.  Destroys the picker and returns to the
%game.
%hObject -- handle of the boundObject
%eventData -- eventData coming along for the ride.
    function acceptOnset(hObject,eventData)
        %Make sure every channel has been checked.
        if(isempty(find(reachVisited == 0,1)))
            %Convert the chosen reach onsets and offsets back to 84/hz
            %datapoints in order to do kinematic statistics.
            for evtNum=1:size(reachTimes,1)
                if(~reachTimes(evtNum,1)==0)
                    corrReachTimesDP(evtNum,1) = reachTimes(evtNum,1);
                    corrReachTimesMS(evtNum,1) = reachTimes(evtNum,1);
                    corrReachTimesDP(evtNum,5) = reachTimes(evtNum,5);
                    corrReachTimesMS(evtNum,5) = reachTimes(evtNum,5);
                    %Revert the mS times back to 84hz dataPoints that are
                    %"trial centric"
                    corrReachTimesDP(evtNum,2:4) =...
                        round((((reachTimes(evtNum,2:4)+500)/1000)*84)+dpPreEvent(evtNum));
                    corrReachTimesMS(evtNum,2:4) = (corrReachTimesDP(evtNum,2:4)/84)*1000;
                else
                    %Trial that didn't have associated data, all zeros.
                    corrReachTimesMS(evtNum,:) = reachTimes(evtNum,:);
                    corrReachTimesDP(evtNum,:) = reachTimes(evtNum,:);
                end
            end
            uiresume(gcbf)
            delete(onsetPane)
        else
            %Some channels not visited.  Warn and return to main.
            uiwait(warndlg('Not all onsets have been reviewed.  Please review all onsets before exiting.','Warning','modal'));
        end
    end

%Locally Defined Callback Function
%Called to export the current graph to a file for future review.
    function exportGraph(hObject,eventData,barBottom,barTop,chanList)
        filtSpec = {'*.jpg','JPEG Image';'*.png','PNG Image';...
            '*.pdf','PDF Document';'*.fig','Matlab Figure'};
        %Get the filename to export to.
        [graphFile, graphPath] = ...
            uiputfile(filtSpec,'Export Graph As...','visComparison.jpg');
        %Only proceed if subject selected a file
        if(~(graphFile==0))
            %Build a temporary output figure for saving purposes.
            selIndex = (get(chanList,'Value'));
            
            expTrial = trialLinks(selIndex);
            expReachOn = reachTimes(expTrial,3);
            expTimeLine = cell2mat(timeLineTable{expTrial});
            expResPos = cell2mat(resPosTable{expTrial,:});
            expResVel = cell2mat(resVelTable{expTrial,:});
            
            image = figure('Visible','off');
            %Update the Plots
            
            xtSpacing=50;
            if(max(expTimeLine) > 1300)
                xtSpacing=100;
            elseif(max(expTimeLine) > 500)
                xtSpacing=100;
            end
            
            %Plot the Data Portion of the Figure
            
            %Begin by creating the construct axes that we'll be plotting into in.  Our
            %methods will use these handles to update the plotted data.
            [AXe, H1e, H2e] = plotyy(expTimeLine,expResPos,expTimeLine,expResVel);
            
            %Generate a new set of Tick marks at 100ms accuracy.
            expXTicks=min(expTimeLine):xtSpacing:max(expTimeLine);
            %Set the new Ticks for each of the two plotyy axises.
            set(AXe(1),'XTick',expXTicks);
            set(AXe(2),'XTick',expXTicks);
            %Set tick mode to manual so they are actually respected.
            set(AXe(1),'XTickMode','manual');
            set(AXe(2),'XTickMode','manual');
            
            hold on
            
            %Define the limits of our event marking bars.
            
            eventBarBottom = round(min(min(expResPos),min(expResVel)))-0.1;
            eventBarTop = round(max(max(expResPos),max(expResVel)))+0.1;
            
            %Plot the reach onset.  Should only need to be done once.
            kOnHnd = line([expReachOn expReachOn],[eventBarBottom eventBarTop], ...
                'LineStyle','--','Color',[0 0 0],'Parent',AXe(2));
            hold on
            
            %Add Title.
            title([gTit ' Kinematic Comparison'], 'Interpreter','none')
            %Labelling the Graph
            set(get(AXe(1),'Ylabel'),'String','Res. Position(cm)')
            set(get(AXe(2),'Ylabel'),'String','Res. Velocity(cm^2)')
            xlabel('Time (ms)')
            
            %Set Limits and Tick Mark locations for both sides of the graph
            %EMG Axis Limits
            posMin=round2(min(expResPos),0.1)-0.1;
            posMax=round2(max(expResPos),0.1)+0.1;
            velMin=round2(min(expResVel),0.1)-0.1;
            velMax=round2(max(expResVel),0.1)+0.1;
            
            set(AXe(1),'XLim',[min(expTimeLine) max(expTimeLine)],...
                'YLim', [posMin posMax], ...
                'YTick', (posMin:(posMax-posMin)/10:posMax),...
                'FontSize',8)
            
            set(AXe(2),'XLim',[min(expTimeLine) max(expTimeLine)],...
                'YLim', [velMin velMax], ...
                'YTick', (velMin:(velMax-velMin)/10:velMax),...
                'FontSize',8)
            
            saveas(image, [graphPath graphFile]);
            delete(image)
            msgbox('Graph Export Complete!','Success','help','modal');
        end
    end
%Return corrected Reach Times
end
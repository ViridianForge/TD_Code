function graphGroupEMGMVNew(cleanEMG, emgHeader,binSize,preEventLength,...
    activationTimes,pkAmps,gFold,gTitle,collectionDir)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%GRAPHPMKINMV Generates plots of PM-Centric Kinematics
%   This breakout function generates MATLAB graphs to visually compare
%   kinematic data from the given subject against EMG data in a double-y
%   format.
%
%   This version of GraphPMKin produces similar graphs to the adult paper's
%   version of GraphPMKin, but uses the pkAmps variable to indicate whether
%   to scale the graphs to the peak amplitude of the passed EMG channels
%   individually, or to a passed in set of peak amplitudes.
%
%   For our purposes, a passed in set of peak amplitudes are calculated
%   from the greatest peak activity of a muscular channel across all levels
%   of support given to a subject during a data collection.
%
%Author: Wayne Manselle -- January 2014
%
%Changes:  Code adapted to function with data input from TDCP processing
%          system.  -- May 2014
%
%INPUTS: cleanEMG -- Non-normalized EMG data used in normalization
%        emgHeader -- The EMG Channel Names
%        pmOnset -- Onset of Prime Mover Activation
%        primeMover -- Muscle Channel number of Prime Mover
%        activationTimes -- The times the muscle was activated
%        pkAmps -- The Peak Amplitude of each channel across levels, or a
%        single 0 to indicate to use a channel's individual peak.
%        gFold -- Graph type subfolder to save graphs to
%        gTitle -- The Current Reach being processed as a graph title
%        collectionDir -- Ultimate output file location for reach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%The minus 1 here is to account for the header in the Normalized EMG data.
timeLine = linspace(0,(size(cleanEMG,1)),(size(cleanEMG,1)));
timeLine = timeLine - preEventLength;

numMuscs = size(cleanEMG,2);

%Determine the limits for the non-arm channels for scaling purposes.
if(size(pkAmps,2)==1)
    pkAmps = max(cleanEMG);
end

%Subaxis approach -- Looking the best
%For the new approach, subaxis with two columns.  Left column is APA, right
%column is CPA.  Use screen coordinates to split things up.  Left column
%will be 0.25 of the screen width, and right column will be 0.75 of the
%screen width.
subax = figure('units','normalized','outerposition',[0 0 1 1],'Visible','off');

for chan=1:numMuscs
    chanLim = pkAmps(chan);
    for subset=1:2
        %Spacing and size algorithms.  Try and arrange the graphs such that
        %the channels being displayed are given as much screen real-estate
        %possible without compromising other graphs.
        %I am assuming 1/10th of the screen will be needed for title and
        %top margin
        %The other 9/10th are divided amongst muscle channels.  Of those
        %sections, 2.5/100ths of the screen are reserved for margin and
        %labelling.
        if(subset==1)
            gPosMat = [0.1 0.9-(chan-1)*(0.9/numMuscs) 0.25 (0.9/numMuscs)-0.025];
        else
            gPosMat = [0.35 0.9-(chan-1)*(0.9/numMuscs) 0.55 (0.9/numMuscs)-0.025];
        end
        %Begin by creating the plot
        subaxis(numMuscs,2,(chan*2)-(2-subset),'SpacingVert',0.005,'MR',0.25,'MT',0.05,'ML',0.25);
        
        if(subset==1)
            plot(timeLine(1:500),cleanEMG(1:500,chan),'b')
            hold on
        else
            plot(timeLine(501:end),cleanEMG(501:end,chan),'b')
            hold on
        end

        set(gca,'position',gPosMat)
        set(gca,'ylim',[-2 pkAmps(chan)+2])
        set(gca,'yTick',pkAmps(chan))
        set(gca,'yTickLabel',pkAmps(chan))
               
        %Now put in the onset-offset lines
        %We're gonna have to be crafty in this case, in the event of
        %activations that stretch between graphs
        chanActivations=activationTimes{chan};
        for activation=1:size(chanActivations,1)
            curAct=chanActivations(activation,:);
            %There is an activation present for this muscle.  Plot it.
            if(~isempty(curAct))
                %Convert Activation into ms
                curOnset = ((curAct(1)-1)*binSize-preEventLength);
                curOffset = ((curAct(2))*binSize-preEventLength);
                %Check to see if we're about to encounter an onset marker
                %that spans the reach onset.
                %If so, create set the current offset to 0, and create a
                %new onset starting at 0.
                if(subset==1)
                    if(curOffset > 0)
                        chanActivations = vertcat([0 curOffset], chanActivations);
                        curOffset = 0;
                    end
                end
                %Musc Onset Line
                line([curOnset curOnset],[-2 pkAmps(chan)+2],'LineStyle','--','Color',[0.75 0.2 0])
                hold on
                %MuscOffset Onset Line
                line([curOffset curOffset],[-2 pkAmps(chan)+2],'LineStyle','--','Color',[0.75 0.2 0])
                hold on
                %Connecting Line
                line([curOnset curOffset],[chanLim*.8,chanLim*.8],'LineStyle','--','Color',[0.75 0.2 0])
                hold on
            end
        end
        
        %Finish with labelling
        if(subset==1)
            ylabel(emgHeader{chan})
            set(gca,'xLim',[-500 0])
            if(chan==numMuscs)
                xlabel('APA')
            else
                set(gca,'xTickLabel',[])
                set(gca,'xTick',[])
            end
        end
                
        if(subset==2)
            set(gca,'yticklabel',[])
            set(gca,'xLim',[0 max(timeLine)+0.01])
            if(chan==numMuscs)
                xlabel('CPA')
            else
                set(gca,'xTickLabel',[])
                set(gca,'xTick',[])
            end
        end
    end
end
t = suptitle(gTitle);
set(t,'Interpreter','none')
%Suptitle, the function we need for a good title above the graphs, causes
%some odd behaviour for figure visibility.  Redeclaring the figure to be
%invisible restores our desired state.
set(gcf,'Visible','off')

set(findall(subax,'type','text'),'fontSize',8,'fontWeight','bold')

%However, we do check for the Prime Mover Graph folder's existence, as
%Victor and Jennifer will not have created this yet.
if(~exist([collectionDir '\' gFold],'dir'))
    mkdir([collectionDir '\' gFold])
end

%The lines below dictate the output format of the saved graphs from this
%function.  PNG format is fairly universal, but has quality loss associated
%with its screen drawing.  EMF format is a vector format that is of sharper
%quality, but has the downside of being Windows Specific.
%
%Comment out the saveas line if you do not want to save PNGs
%Comment out the print line if you do not want to save EMFs

%Save graphs as "high quality" png files.
%saveas(subax, [collectionDir '\' fileMod '\' gTitle '.png']);
%Save graphs as Windows-specific EMF files.
print('-dmeta','-r600',[collectionDir '\' gFold '\' gTitle '.emf']);
end
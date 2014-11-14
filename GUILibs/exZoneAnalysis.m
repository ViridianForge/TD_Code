function [ zoneBreakdown ] = ...
    exZoneAnalysis( tkCOMData, bosData, zLimit, genGraph, gTitle, outLoc, group)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%EXZONEANALYSIS Analyzes the given Trunk movement 
%   This function analyzes the ML and AP axis movements of the given 
%   trunk COM and categorizes that movement by what percentage of the 
%   movement belonged to each of three movement zones.  These zones are:
%   1 -- Stable Zone -- Defined as both ML and AP movement being within 
%   <zLimit> percent of the limits of the base of support.
%   2 -- Controlled Zone -- Defined as both ML and AP movement being within 
%   the limits of the base of support, but either ML or AP movement being 
%   outside of the stable zone.
%   3 -- Falling Zone -- Defined as either ML or AP being outside of the 
%   limits of the base of support.
%
%Author: Wayne Manselle -- March 2014
%
%INPUTS: tkCOMData -- the Trunk COM data to analyze.
%        bosData -- the limits of the base of support.
%        zLimit -- The limits of the stable zone, expressed as a percentage
%        of the limits of the base of support.
%        genGraph -- Generate a corresponding graph to the analysis
%        gTitle -- What title to give the graph
%        outLoc -- Where to save the file
%        group -- Group membership, used to help set appropriate axises
%
%OUTPUTS: zoneBreakdown -- Array of percentages describing the amount of
%         movement in each of the three zones.  
%         1 -- Stable Zone
%         2 -- Controlled Zone
%         3 -- Falling Zone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

zoneBreakdown = zeros(3,1);

%Generate the vectors of the ellipses to be analyzed
[xStab,yStab]=ellipse((bosData(1,1)-bosData(3,7))*zLimit,(bosData(2,2)-bosData(3,8))*zLimit,0,0,0,'r');
[xCont,yCont]=ellipse((bosData(1,1)-bosData(3,7)),(bosData(2,2)-bosData(3,8)),0,0,0,'b');

%Test all datapoints to see within which zone they fall
for dp=1:size(tkCOMData,1)
    if(inpolygon(tkCOMData(dp,1),tkCOMData(dp,2),xStab,yStab))
        zoneBreakdown(1) = zoneBreakdown(1)+1;
    elseif(inpolygon(tkCOMData(dp,1),tkCOMData(dp,2),xCont,yCont))
        zoneBreakdown(2) = zoneBreakdown(2)+1;
    else
        zoneBreakdown(3) = zoneBreakdown(3)+1;
    end
end

%Std Dev limits as suggested by Victor
%limVec = [min(tkCOMData(:,1))-abs(std(tkCOMData(:,1))),...
%          max(tkCOMData(:,1))+abs(std(tkCOMData(:,1))),...
%          min(tkCOMData(:,2))-abs(std(tkCOMData(:,2))),...
%          max(tkCOMData(:,2))+abs(std(tkCOMData(:,2)))];

%Convert the measurements to percentages
zoneBreakdown = (zoneBreakdown./size(tkCOMData,1))*100;

%Generate a graph if requested
if(genGraph)
    exZGraph=figure('Visible','off');
    %These x values, for the excursion zones AND the tk com have been
    %multiplied by negative one to change our perspective.
    %
    %The results of this will be a graph that, visually, appears to be the
    %infant's excursion from a top-down perspective from behind.
    %However, the units along the X axis will appear to be reversed, as
    %MATLAB will want to put negative values to the left, and will need be
    %edited by hand.
    inE=line(-xStab,yStab);
    set(inE,'Color','r','LineWidth',1,'LineStyle','--')
    hold on
    outE=line(-xCont,yCont);
    set(outE,'Color','b','LineWidth',1.25)
    hold on
    %Static Axis Version if we decide to go that route
    if(group==1)
        axis([-12 12 -15 15])
    else
        axis([-20 20 -25 25])
    end
    %Dynamic Axis Version adjusting by subject
    %axis(limVec)
    hold on
    plot(-tkCOMData(:,1),tkCOMData(:,2),'k.','MarkerSize',10)
    title(gTitle,'Interpreter','none')
    xlabel('ML Movement(cm)')
    ylabel('AP Movement(cm)')
    %saveas(exZGraph, [outLoc gTitle '_exZoneVis.jpg']);
    print('-dmeta','-r600',[outLoc gTitle '_ExZoneGraph.emf']);
end

end
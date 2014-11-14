function graph3DReach(reachHandMat,trunkCOMMat, gTitle, outLoc, scale)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%GRAPHPM3DREACH - Generates 3D Graphs of Subject Reach Trajectory
%   This function generates a 3D graph of the trajectory of a subject's
%   reaching hand using a segment of kinematic data that begins at the
%   activation of the Subject's Prime Mover muscle and extends through the
%   end of the reaching event.
%
%   Graphical representation of the trunk's COM was added at the request of
%   Dr. Marjorie Woollacott in late May of 2014.
%
%AUTHOR: Wayne Manselle - March 2014
%
%INPUTS: reachHandMat -- the reaching hand to be visualized
%        trunkCOMMat -- the trunk's COM to be visualized
%        gTitle -- the Title to give the graph
%        outLoc -- the location to save the generated graphs to
%        scale -- optional parameter to set scale of graph
%
%ChangeLog -- 5/21/2013 -- Added visualization of the trunk COM to the code
%base
%           - 8/1/2014 -- Added scaling factor to graphs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (nargin < 5)
    scale = 0;
end

reach3DGraph = figure;
%Invert the X-Axis so left and right have a sign corresponding with how
%left and right are represented on a cartesian plane.
reachHandMat(:,1) = -1*reachHandMat(:,1);

%If Scaling is set, also invert the X-range of scaling
if(scale ~= 0)
    newXMax = -1*scale(1);
    newXMin = -1*scale(2);
    scale(1) = newXMin;
    scale(2) = newXMax;
end
set(reach3DGraph,'Visible','off')
%Plot Reaching Hand Data
plot3(reachHandMat(:,1),reachHandMat(:,2),reachHandMat(:,3),...
    'Color',[0.298 0 0.6],'LineWidth',2)
hold on
%Plot Reaching Starting Point
plot3(reachHandMat(1,1),reachHandMat(1,2),reachHandMat(1,3),'Color',[0.298 0 0.6],...
    'Marker','O','MarkerSize',9,'MarkerFaceColor',[0.298 0 0.6])
hold on
%Plot Reaching Ending Point
plot3(reachHandMat(end,1),reachHandMat(end,2),reachHandMat(end,3),'Color',...
    [0.298 0 0.6],'Marker','d','MarkerSize',9,'MarkerFaceColor',[0.298 0 0.6])
hold on

%Set the scaling and labelling on the graph, if the optional variable is set.
if(scale ~= 0)
    axis(scale);
    set(gca,'XTick',scale(1):(scale(2)-scale(1))/5:scale(2))
    set(gca,'YTick',scale(3):(scale(4)-scale(3))/5:scale(4))
    set(gca,'ZTick',scale(5):(scale(6)-scale(5))/5:scale(6))
end

xlabel('M/L Displacement from COB(cm)','FontWeight','bold')
ylabel('A/P Displacement from COB(cm)','FontWeight','bold')
zlabel('Vertical Displacement from COB (cm)','FontWeight','bold')
title(gTitle,'interpreter', 'none')
grid off
axis square
%We'll probably need to adjust the axis dimensions, will have to remember
%that.
print('-dmeta','-r600',[outLoc gTitle '_3DReach.emf']);
end
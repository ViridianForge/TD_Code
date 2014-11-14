function graphRotMatAngs( angleSet, gTitle, fileLabel, dataLocation, scale )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%GRAPHROTMATANGS - Generates comparitive graphs of Rotational Matrix angles
%   This function generates a 3 x 1 subplot styled graph, displaying the
%   gamma, beta, and alpha angles over time of the rotational matrix angle
%   data passed.  The data may be saved and scaled using optional
%   parameters.
%
%   Author --  Wayne Manselle - July 2014
%
%   ChangeLog -- 07.30.2014 -- Initial Creation
%
%   INPUTS -- angleSet - The set of gamma, beta and alpha to graph
%             gTitle - The title of the graph
%             fileLabel - the labelling to use for the graph generated
%             dataLocation - the base output location
%             scale - optional variable to set specific scale for graph
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Test to see if scale variable set
if( nargin < 5)
    scale = 0;
end

%disp(['Current Scale Factor for ' fileLabel])
%scale

%Differentiate angle sets for easier reading
gamma = angleSet(:,1);
beta = angleSet(:,2);
alpha = angleSet(:,3);

%disp('Limits of current dataset')
%disp(['Gamma: ' num2str(min(gamma)) ' to ' num2str(max(gamma))])
%disp(['Beta: ' num2str(min(beta)) ' to ' num2str(max(beta))])
%disp(['Alpha: ' num2str(min(alpha)) ' to ' num2str(max(alpha))])

%Plots for Head v. Global Angles
figure('Visible','off')
subplot(3,1,1)
plot(gamma,'b')
ylabel('Gamma')

if(scale ~= 0)
    ylim(scale(:,1))
end
title(gTitle,'interpreter','none')
hold on

%Plots for Trunk v. Global Angles
subplot(3,1,2)
plot(beta,'g')
ylabel('Beta')

if(scale ~= 0)
    ylim(scale(:,2))
end
hold on

%Plots for Head v. Trunk Angles
subplot(3,1,3)
plot(alpha,'r')
ylabel('Alpha')

if(scale ~= 0)
    ylim(scale(:,3))
end
hold on

print('-djpeg','-r600',[dataLocation fileLabel '.jpg']);
end
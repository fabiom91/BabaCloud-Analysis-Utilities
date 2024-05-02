%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function plotBSN_h(myBSN, U, L)
% PLOTBSN Plots BSN values with uncertainty and colorization.
%
% Inputs:
%   myBSN: BSN values
%   U: Upper Boundary of BSN Uncertainty
%   L: Lower Boundary of BSN Uncertainty

threshold = 50;
PAULTOLCOLORS = [68,    119,    170;...                 % blue
    102,    204,    238;...                 % cyan
    34,    136,     51;...                 % green
    230,    230,     28;...                 % yellow
    248,    92,    99;...                 % red
    170,     51,    119;...                 % pink
    187,    187,    187]...                 % light grey
    / 255;
pal1 = [PAULTOLCOLORS(6,:);PAULTOLCOLORS(6,:); % pink
    PAULTOLCOLORS(4,:); PAULTOLCOLORS(4,:); % yellow
    PAULTOLCOLORS(3,:); PAULTOLCOLORS(3,:); % green
    PAULTOLCOLORS(2,:);PAULTOLCOLORS(2,:)]; % cyan
% Estimate Colours
for i = 1 : length(myBSN)
    Mycolour(i,:) = interp1([0;2*threshold/6;...
        4*threshold/6;5*threshold/6;...
        threshold+(1*(100-threshold)/6);threshold+(2*(100-threshold)/6);...
        threshold+(4*(100-threshold)/6); 100],pal1,myBSN(i));
end
Mycolour_smoothed = movmean(Mycolour, 15);

figure1 = figure('Position',[1,527,1120,420]);
% Create axes
axes1 = axes('Parent',figure1);
hold(axes1,'on');
time_plt = 0:length(myBSN)-1;
for iFillSpaces = 1 : length(time_plt)-1
    if ~isnan(myBSN(iFillSpaces))
        v0 = [time_plt(iFillSpaces) myBSN(iFillSpaces)-0.5;...
            time_plt(iFillSpaces) myBSN(iFillSpaces)+0.5; ...
            time_plt(iFillSpaces+1) myBSN(iFillSpaces+1)+0.5; ...
            time_plt(iFillSpaces+1) myBSN(iFillSpaces+1)-0.5];

        Cdata = Mycolour_smoothed(iFillSpaces,:);
        Cdata(Cdata > 1) = 1;
        patch('Faces',[1 2 3 4],'Vertices',v0,'EdgeColor',Cdata,'LineWidth',1.5,'FaceColor',Cdata);
    end
end
figure(1); plot(time_plt,U,':','color', 'k','Linewidth',1)
figure(1); plot(time_plt,L,':','color', 'k','Linewidth',1)
figure(1),xlim([0,max(time_plt)])
figure(1),ylim([0,100])
figure(1),xlabel('Time (h)')
figure(1),ylabel('BSN')
set(gca,'FontName','Arial','FontSize',18,'Position',[0.057 0.1214 0.932 0.8357])
hold(axes1,'off');
end

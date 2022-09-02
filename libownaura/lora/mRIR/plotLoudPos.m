% plotLoudPos

% load Loudspeaker positions
L_posr = LoudspeakersPos3D;
% parameters
R = 1.8;
facecolor = [1 1 1];
facealpha = 0.5;
edgecolor = [0 0 0];
faces3 = [1,2,23,NaN;2,3,23,NaN;4,5,24,NaN;5,6,24,NaN;7,8,25,NaN;8,9,25,NaN;9,10,26,NaN;10,11,26,NaN;12,13,27,NaN;13,14,27,NaN;15,16,28,NaN;16,1,28,NaN;1,2,17,NaN;2,3,17,NaN;4,5,18,NaN;5,6,18,NaN;7,8,19,NaN;8,9,19,NaN;9,10,20,NaN;10,11,20,NaN;12,13,21,NaN;13,14,21,NaN;15,16,22,NaN;16,1,22,NaN;1,23,28,NaN;9,25,26,NaN;1,17,22,NaN;9,19,20,NaN;23,24,29,NaN;24,25,29,NaN;25,26,29,NaN;26,27,29,NaN;27,28,29,NaN;28,23,29,NaN;3,4,24,23;6,7,25,24;11,12,27,26;14,15,28,27;3,4,18,17;6,7,19,18;11,12,21,20;14,15,22,21;];
faces3(1:34,4) = NaN;
[x,y,z] = sph2cart(L_posr(:,1),L_posr(:,2),R*ones(size(L_posr,1),1));
vertices=[x y z];

figure
set(gcf,'DefaultAxesFontName','Arial','DefaultAxesFontSize',12)
% Loudspeakers (dot markers)
plot3(x,y,z,'k.','markersize',15)
hold on
% Plot the surface (vertices + transparency)
patch('faces',faces3,'vertices',vertices,...
    'facecolor',facecolor,'facealpha',facealpha,'edgecolor',edgecolor);
hold on
% labels
for n=1:length(x)
    text(x(n),y(n),z(n),num2str(n),'HorizontalAlignment','right',...
       'VerticalAlignment','top','FontSize',12,'FontName','arial','FontWeight','bold')
end
xlabel('X [m]')
ylabel('Y [m]')
zlabel('Z [m]')
% zoom
axis equal
axis([-R R  -R R  -R R])
view([-37.5+180 30])
% title('Loudspeaker positions')
box off
% export2tex('lpos.pdf')
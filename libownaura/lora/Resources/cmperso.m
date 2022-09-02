function mycmap=cmperso(N,d)

mycmap = zeros(N,3);
if d
%     c = [[0.2 0.4 1];[0.7 0.8 1];[0.9 0.99 1]; 1 1 1;1 0.5 0 ;0.5 0 0;0.2 0 0];
    c = [0 0 1; 1 1 1; 1 0 0];
else
    c = [0 0 1;0 0.5 1; 0.9 0.9 0.9;1 0.5 0; 1 0 0];
%     c = [0 0 0.2;0 0 0.5;0 0.5 1; 1 1 1;1 0.5 0;0.5 0 0;0.2 0 0];
%     c = [0 0 0.2;0 0 0.5; 0 0.5 1; 1 1 1;1 0.5 0; 0.5 0 0;0.2 0 0];
%     c = [0 0 0; 1 1 1;0 0 0];
end
% c = [[0.2 0.4 1];[0.7 0.8 1];[0.9 0.99 1]; 1 1 1;1 0.5 0 ;0.5 0 0;0.2 0 0];
mycmap = interp1(c,linspace(1,size(c,1),N),'pchip');
% mycmap = mycmap/max(max(mycmap));
% figure,plot(mycmap)
% % B
% mycmap(:,1) = [linspace(0,1,N/2)'; c(1,1); linspace(1,1,N/2-1)'];
% % G
% mycmap(:,2) = [linspace(1/2,1,N/2)'; c(1,1); linspace(1,1/2,N/2-1)'];
% % R
% mycmap(:,3) = [linspace(1,1,N/2)'; 1; linspace(1,0,N/2-1)'];


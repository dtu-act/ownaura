function wavformplot(yDS,yER,ylate,nL,fs)

% Time vector
tDS=(1:size(yDS,1))/fs;
tER=(1:size(yER,1))/fs;
tlate=(1:size(ylate,1))/fs;
figure
set(gcf,'DefaultAxesFontName','Arial')
if nL
    plot(tlate,ylate(:,nL))
    hold on
    plot(tDS,yDS(:,nL),'r')
    hold on
    plot(tER,yER(:,nL),'color',[0 0.5 0])
else
    plot(tlate,sum(ylate,2))
    hold on
    plot(tDS,sum(yDS,2),'r')
    hold on
    plot(tER,sum(yER,2),'color',[0 0.5 0])
end
legend('Late','DS', 'ER')
xlabel('Time [s]')
if nL
    title(['Wavform - Loudspeaker: ',num2str(nL)])
else
    title('Wavform - sum of all loudspeaker')
end
xlim([ 0 tlate(end)/2])


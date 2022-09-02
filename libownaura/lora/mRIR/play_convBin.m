function ssc = play_convBin( SndName, L_ref, playDeviceID, B, L)

%   Plays the convolution of the sound in fileName with the IR from B on Playrec device
%   playDeviceID.  
% 
%   SndName         File name of the anechoic sound file
%   Lref            int: digital rms level in dB (-19.8 for Dantale II)
%   playDeviceID    playback devide ID (ex: 0 in the space lab, 3 on a desktop)
%
%   B               Matrix (samples x chan): fft of the IR 
%               or  2 Cells: containning the fft of the DS (cell 1) and the ER (cell 2) 
%   L               int: block length
%   IRgain          int: IR gain 
%               or  2 int: IRgain(1) gain for the DS; IRgain(2) gain for the ERs
%   noise           matrix (samples x chan): contain the noise to be played
%                   simultaneously with the convolved signal

nfft = size(B,1);
nchan = size(B,2);
nLR = size(B,3);
if nLR~=2
  error('size(B,3) should be two: channel L and R')
end
chanList = 1:2;

delay = 0.1; % to make sure, there is sufficient time to compute the first pages

nb = nfft-L;

pageBufCount = 10;   %number of pages of buffering


runMaxSpeed = true; %When true, the processor is used much more heavily
%(ie always at maximum), but the chance of skipping is reduced


% Load the anechoic sound file
[fileSize Fs] = wavread(SndName, 'size');
fileLength = fileSize(1);
fileChanCount = fileSize(2);
startPoint = 1;
endPoint = fileLength;



if fileChanCount ~= nchan
    error ('File must contain the same number of channel than B');
end

%Test if current initialisation is ok
if(playrec('isInitialised'))
    if(playrec('getSampleRate')~=Fs)
        fprintf('Changing playrec sample rate from %d to %d\n', playrec('getSampleRate'), Fs);
        playrec('reset');
    elseif(playrec('getPlayDevice')~=playDeviceID)
        fprintf('Changing playrec play device from %d to %d\n', playrec('getPlayDevice'), playDeviceID);
        playrec('reset');
    elseif(playrec('getPlayMaxChannel')<max(chanList))
        fprintf('Resetting playrec to configure device to use more output channels\n');
        playrec('reset');
    end
end

%Initialise if not initialised
if(~playrec('isInitialised'))
%     fprintf('Initialising playrec to use sample rate: %d, playDeviceID: %d and no record device\n', Fs, playDeviceID);
    playrec('init', Fs, playDeviceID, -1);

    % This slight delay is included because if a dialog box pops up during
    % initialisation (eg MOTU telling you there are no MOTU devices
    % attached) then without the delay Ctrl+C to stop playback sometimes
    % doesn't work.
%     pause(0.1);
end

if(~playrec('isInitialised'))
    error ('Unable to initialise playrec correctly');
elseif(playrec('getPlayMaxChannel')<max(chanList))
    error ('Selected device does not support %d output channels\n', max(chanList));
end

if(playrec('pause'))
    fprintf('Playrec was paused - clearing all previous pages and unpausing.\n');
    playrec('delPage');
    playrec('pause', 0);
end


%%
% fprintf('Playing from sample %d to sample %d with a sample rate of %d samples/sec\n', startPoint, endPoint, Fs);
% Initialisation
pageNumList = [];
pageNumList = [pageNumList playrec('play',...
        zeros(delay*Fs,length(chanList)),...
        chanList)];
% t=0;dt=[];
% 
% tic
istart = startPoint;
yrem = zeros(nb-1,2);
k = 0;
yend = 1;
B1=B(1:2:end,:,:);
% % pre-noise
% pageNumList = [pageNumList playrec('play',...
%     (noise(1:lw1,chanList).*repmat(w1(1:lw1),1,length(chanList)))*plbck_gain,...
%     chanList)];
% playrec('resetSkippedSampleCount');
% pageNumList = [pageNumList playrec('play',...
%     noise(lw1+1:lb,chanList)*plbck_gain,...
%     chanList)];

while istart <= endPoint
    k = k+1;
%     preL = yend;
    if k<1 %beginning
        
        rL=L/4;
        iend = min(istart+rL-1,endPoint);
        x = wavread(SndName, [istart iend]);
        X = fft(x*10^(-L_ref/20),nfft/2);
%         y = ifft(repmat(X,1,nchan).*B(1:2:end,:));
        y = ifft([sum(X.*B1(:,:,1),2) sum(X.*B1(:,:,2),2)]);
%         y = ifft(repmat(X,1,nchan).*B1);
    else
        rL=L;
        iend = min(istart+rL-1,endPoint);
        x = wavread(SndName, [istart iend]);
        X = fft(x*10^(-L_ref/20),nfft);
%         y = ifft(repmat(X,1,nchan,nLR).*B);
        y = ifft([sum(X.*B(:,:,1),2) sum(X.*B(:,:,2),2)]);
    end

    y(1:nb-1,:) = y(1:nb-1,:)+yrem;
    %     yend = min(iend-istart+1,L);
    if iend < endPoint
        yend = rL;
        yrem = y(yend+1:yend+nb-1,:);
    else
        yend = iend-istart+nb;
    end
%     plpage=(y(1:yend,chanList)+noise(istart+lb+1:istart+lb+yend,chanList))*plbck_gain;
    plpage=(y(1:yend,chanList));

    pageNumList = [pageNumList playrec('play',...
        plpage,...
        chanList)];

    
    if istart == startPoint;
        %This is the first time through so reset the skipped sample count
        playrec('resetSkippedSampleCount');
    end

%     
%     a=length(playrec('getPageList'));
%     t=[t toc];
%     ssc = playrec('getSkippedSampleCount');
%     dt=[dt;[ssc,floor((t(end)-t(end-1))*Fs),a]];
%     fprintf('%-5d \t',dt(end,:))
%     fprintf('\n')
%     
   
    istart = istart + rL;
    if(length(pageNumList) > pageBufCount)

        if(runMaxSpeed)
            while(playrec('isFinished', pageNumList(1)) == 0)
            end
        else
            playrec('block', pageNumList(1));
        end
        pageNumList = pageNumList(2:end);
    end
end

% inoise = fileLength+nb-1+lb+1;
% % post-noise
% pageNumList = [pageNumList playrec('play',...
%     noise(inoise:inoise+le-1-lw2,chanList)*plbck_gain,...
%     chanList)];
% pageNumList = [pageNumList playrec('play',...
%     (noise(inoise+le-lw2:inoise+le-1,chanList).*repmat(w2(lw2+1:end),1,length(chanList)))*plbck_gain,...
%     chanList)];
ssc = playrec('getSkippedSampleCount');
if ssc
    warning(['Glitches occured for ',num2str(ssc),' samples'])
end
playrec('block', pageNumList(end));


playrec('reset')


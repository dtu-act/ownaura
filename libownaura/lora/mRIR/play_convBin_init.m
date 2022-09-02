function  [B,L] = play_convBin_init( yB, playDeviceID,Fs)
%PLAY_WAV Play a wav file
%
%play_wav( fileName, playDeviceID, chanList, startPoint, endPoint )
%   Plays the file fileName on Playrec device playDeviceID.  chanList
%   specifices the channels on which speakers are connected and must be a
%   row vector.
%   SndName         File name of the anechoic sound file
%   ymRIR           multichannel room impulse response
%
%   nDS             int: Ambisonic order for the direct sound
%   nER             int: Ambisonic order for the early reflections


nchan = size(yB,2);
nB = size(yB,1);
nLR = size(yB,3);

% FFT of the IR yB
nfft = 2^nextpow2(3*nB);
yB=[yB;zeros(mod(nB,2),nchan,nLR)];

L = nfft - nB-mod(nfft - nB,4);
B = fft(yB,nfft);

% Soundcard init

%Test if current initialisation is ok
if(playrec('isInitialised'))
    if(playrec('getSampleRate')~=Fs)
        fprintf('Changing playrec sample rate from %d to %d\n', playrec('getSampleRate'), Fs);
        playrec('reset');
    elseif(playrec('getPlayDevice')~=playDeviceID)
        fprintf('Changing playrec play device from %d to %d\n', playrec('getPlayDevice'), playDeviceID);
        playrec('reset');
%     elseif(playrec('getPlayMaxChannel')<max(chanList))
%         fprintf('Resetting playrec to configure device to use more output channels\n');
%         playrec('reset');
    end
end

%Initialise if not initialised
if(~playrec('isInitialised'))
    fprintf('Initialising playrec to use sample rate: %d, playDeviceID: %d and no record device\n', Fs, playDeviceID);
    playrec('init', Fs, playDeviceID, -1);

    % This slight delay is included because if a dialog box pops up during
    % initialisation (eg MOTU telling you there are no MOTU devices
    % attached) then without the delay Ctrl+C to stop playback sometimes
    % doesn't work.
    pause(0.1);
end

if(~playrec('isInitialised'))
    error ('Unable to initialise playrec correctly');
% elseif(playrec('getPlayMaxChannel')<max(chanList))
%     error ('Selected device does not support %d output channels\n', max(chanList));
end

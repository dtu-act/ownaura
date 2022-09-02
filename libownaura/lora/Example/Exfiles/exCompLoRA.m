% exampleLoRA

% Initialisation of the LoRA Toolbox
LoRA = LoRA_startup('fs',48000,...
    'LoudSetName','LoudspeakersPos3D_AVIL',...
    'renderDS',5,...
    'renderER',5);

path = '.';
room = 'Copenhagen Central Station Array.centre_back.00001';%'Elmia RoundRobin2 detailed.Job02.00001';
%'auditorium21 at DTU.Job04.00001';

% Compute each part of the multichannel room impulse response (mRIR)
[mIRearly,ylate,Param] = LoRAmRIR(path,room,LoRA.renderDS,LoRA.renderER,LoRA);
% Add the direct sound the early reflections and the late reflections
ymRIR = AddDSERlate(mIRearly,ylate,LoRA.renderDS,LoRA.renderER);

% Power of the sum of all loudspeakers IR
ySPL=10*log10(sum(sum(ymRIR,2).^2));

% Plot the mRIR
figure,plot(ymRIR)
%% Convolution

% ConvSndSample: This function convolved an anechoic wav file with the multichannel
% impulse response. If the sound file is too long, the resulted convolution is written
% with chunks. This allows for handling very long wav files. The last argument means
% that the level of the resulted convolution is determined by the power of the IR.
ConvSndSample('adjustedCLUEsent003.wav', ymRIR, LoRA.fs, 24, 'outputsound.wav', 1, []);

% Checking RMS of convolved sound. This function return the RMS of any wav file
% without loading the whole file in Matlab memory.
rmsDig = RMSwav( 'outputsound.wav');

% Corresponding SPL
SPLconvsnd = 20*log10(rmsDig);

fprintf('SPL from the mRIR: %.1fdB \nSPL from the convoled sound: %.1fdB \n',ySPL,SPLconvsnd)

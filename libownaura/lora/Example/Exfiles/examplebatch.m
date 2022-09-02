% examplebatch

% Initialisation
LoRA_startup('fs',48000,'Session','XX',...
            'LoudSetName','LoudspeakersPos3D_AVIL',... 
            'renderDS',5,...
            'renderER',5)

% Computes mRIR for the room files in PathReadODEON and then convolve them
% with the anechoic sound sample in PathSoundSample.
batchLoRAProc()
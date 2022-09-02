clear all

LoRA_addpath % add necessary folders to the MATLAB search path

nDS = 0;  % Ambisonics order of direct sound (nDS=0 for nearest loudspeaker)
nER = 0;  % Ambisonics order of early reflections (nER=0 for nearest loudspeaker)
seed = 1; % set seed for repeatability of the calculation of the diffues RIR part

%%% Initialization of the LoRA structure
LoRA = LoRA_startup('renderDS', nDS, 'renderER',nER, 'seed', seed); % initializing LoRA

%%% Name of room scene | Hence, the following ODEON text files are needed:
%                        - [sceneName, '_EarlyReflections.Txt'], and
%                        - [sceneName, '_EnergyCurves.Txt']
sceneName = 'DByrne_fin7IR27';

%%% Name of the file (anechoic recording) to be convolved with the generated RIR
sourceName = 'IELTS material\D_142_processed_DS_RMSeq.wav';

%% Generate the multichannel RIR
sceneFileName = [LoRA.PathReadODEON, sceneName, '_'];
[ymRIR,fs] = CompmRIR(sceneFileName, LoRA.fs, LoRA.LoudSetName,...
                      LoRA.renderDS, LoRA.renderER, LoRA);

% Save the multichannel RIR to a file
RIRfname = [sceneName '_ymRIR'];
save([LoRA.PathStoreIR RIRfname], 'ymRIR')

%% Following the derivation of the ymRIR, the next 3 steps need to be considered:
%
% 1. Load the hinv.mat filter and apply the inverse voice EQ (to undo the
%    on-axis directivity). This step should be implemented if the RIRs are
%    to be used with (anechoic) recording of talkers.
% 2. Measure the loudspeakers, calculate relevant EQ and apply that to the
%    multichannel RIRs. This step should be implemented if the stimuli are
%    to be auralised inside a L/S array. Take care to use the same channel
%    numbering as used by the LoRA.LoudSetName ('LoRA.pos') setup.
% 3. Convolve the final RIRs with some anechoic recording.

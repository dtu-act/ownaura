% pathstore
%
% Must contain a valid path name for PathStoreIR, PathStoreConv, PathreadODEON
% and PathSOundSamples.
rootp = pwd;

% Path where Impulse responses are stored
PathStoreIR = ['C:\LORA\data\IR\'];

% Path where Convolved sound are stored
PathStoreConv = ['C:\LORA\sounds\convolved\']; 

%%%% manually set it to correct folder outside MATLAB section (to avoid having it backed up)
%%%  PathStoreConv = 'C:\Odeon11Combined\LoRA_Convolved_Sounds\';

% Path where room data text files are stored
PathReadODEON = ['C:\LORA\data\ODEON\'];

% Path where anechoic sound files are stored
PathSoundSamples = ['C:\LORA\sounds\anechoic\'];      

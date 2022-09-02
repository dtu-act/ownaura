% TestPlayConvBin
%
% Play multichannel file to headphone using HRTF recorded in the SpaceLab

% load hrtf recorded in the Space Lab
% load('C:\PostDocData\Data\IRrecordings\HRTF_SpaceLab\HRTF_SpaceLab.mat')
% hrtfLa=yir(2300:4348,1:29,:)*10^(-level/20);
load('C:\PostDocData\Data\IRrecordings\HRTF_SpaceLab\hSpaceLab4096.mat')

% hrtfLa = hrtfLa(70:70+256-1,:,:);

% parameters
playDeviceID = 3;
Fs = 44100;

[B,L] = play_convBin_init( hrtfLa, playDeviceID,Fs);

% SndName = 'C:\PostDocData\Data\Conv\XX\s3D-rum019-Job02-44-cello.wav';
% SndName = 'C:\PostDocData\Data\Conv\XX\s3D-Elmia -Job02-44-cello.wav';
% SndName = 'C:\PostDocData\Data\Conv\XX\s3D-Elmia -Job02-44-organ.wav';
% SndName = 'C:\PostDocData\Data\Conv\XX\s3D-Elmia -Job02-44-percu.wav';
% SndName = 'C:\PostDocData\Data\Conv\XX\s3D-rum019-Job02-44-percu.wav';
SndName = 'C:\PostDocData\Data\Conv\XX\s3D-rum019-Job02-44-Sentence006.wav';
plbck_gain = 1;
       
play_convBin( SndName, -19.8, plbck_gain, playDeviceID,B, L);
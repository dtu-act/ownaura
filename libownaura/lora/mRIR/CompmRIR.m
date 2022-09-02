% CompmRIR
%
% Compute multichannel room impulse response from ODEON data files

function [ymRIR,fs,ylate] = CompmRIR(fnameJob,fs,Loudsetup,nDS,nER,LoRA)

if nargin < 5, nER = []; end
if nargin < 4, nDS = []; end
if nargin < 3, Loudsetup = 'LoudspeakersPos3D_AVIL'; end
if nargin < 2, fs = 48000; end

[tok,remain] = strtok(fliplr(fnameJob), filesep);%fname includes entire path
room=fliplr(tok);
path=fliplr(remain);

if nargin<6
% Initialise LoRA
LoRA=LoRA_startup('fs',fs,...
    'LoudSetName',Loudsetup,...
    'renderDS',nDS,...
    'renderER',nER);
end

% Compute each part of the response (mRIR)
[mIRearly,ylate,Param] = LoRAmRIR(path,room,nDS,nER,LoRA);

% Add the direct sound the early reflections and the late reflections
if strcmp(LoRA.ReverbFlag,'DE')
    DirSnd = eval(['mIRearly.yDS' num2str(nDS)]);
    L_DS = size(DirSnd,1);
    nLS = size(DirSnd,2); % number of array loudspeakers
    if isfield(mIRearly,['yER' num2str(nER)])
        ErlRfl = eval(['mIRearly.yER' num2str(nER)]);
        L_ER = size(ErlRfl,1);
        ymRIR = [DirSnd; zeros(L_ER-L_DS,nLS)] + ErlRfl; % Only (DS+ER)...
    else
        ymRIR = DirSnd; % Only (DS)...
    end
    
elseif strcmp(LoRA.ReverbFlag,'All')
    ymRIR = AddDSERlate(mIRearly,ylate,nDS,nER); % Complete RIR (DS+ER+Late)...
else
    disp('Error!!! ReverbFlag should be either ''DE'' or ''All''')
end

roomName=room(1:end-6);


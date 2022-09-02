% fLATE
% 
% Calculate the late part response.
%
% input:
%   NRG         data structure obtained with ReadEnergyCurves.m
%   ER          data structure obtained with ReadEarlyReflections.m
%   fs          sampling frequency (Hz)
%   isprint     0:  output the late multichannel response
%               1:  output the envelope of the omnidriectionnal channel W 
%
% output:
%   if isprint = 0
%       outlate     matrix (samples,channels), late multichannel response
%   if isprint = 1
%       outlate     {late_env,Eref,resol,sresol}:
%                       late_env    ambisonic 1st order late refelctions envelopes.
%
% uses AmbDecM.m and AddNoise.m
%___________________________________
% $Revision: #1 $ 
%    - zeroing the starts of the late enveloppes (solve the substraction erros due to the 
%      dB truncature issue)
%
% $Revision: #1 $ 
%    - Initial version.
%___________________________________
%
% (c) 2007 S. Favrot

function outlate = fLATE(LoRA,NRG,ER,fs,isprint,logdest)

if nargin < 5
    isprint = 0;
end
if nargin<6
    logdest=0;
end

%%   Initialisations
%--------------------------------------------------------------------------
% data form ODEON's ASCII files[2:end 1]
Etot    =   NRG(1).data;
Idir = zeros(3,size(NRG(4).data,1),8);
for bd = 1:8
    Idir(:,:,bd)    =   NRG(4).data(:,:,bd)';
end

% IR resolution for the decay curve in ms
resol   =   2*NRG(1).t(1);
sresol  =   floor(resol/1000*fs);% number of sample per slot


% In which time slot each reflection occurs
tref_e          =  floor((ER(:,2))/resol)+1;
[G_e,GN_e]      =  grp2idx(tref_e);
theta           =  deg2rad(ER(:,13)); 
phi             =  deg2rad(ER(:,14));
[Irx,Iry,Irz]   =  sph2cart(theta*linspace(1,1,8), phi*linspace(1,1,8),...
                        10.^(ER(:,4:11)/10));
% find the starting slot of the late response (at the first reflections reaching 
% the transition order)
% lastorder       =  find(ER(:,12)==max(unique(ER(:,12))))-1;
% nslotlast       =  floor((ER(lastorder(1),2))/resol)+1;
nslotlast       =  floor((ER(1,2))/resol)+1;

%% Anaylsis 
%--------------------------------------------------------------------------
% Computation of the contribution of the ER to the total and the directional energy 

% Linear sum for each time slot where reflections are present to obtain
% the total energy produced by the early reflections
% Eref from the Early Reflections
Eref    =  zeros(4,size(Etot,1),8);
for k = 1:length(GN_e) % for each time slot (nslot) where reflections are present
    nrefl             =   find(G_e==k); % indexes of reflections present in the slot
    nslot             =   str2double(cell2mat(GN_e(k))); 
    %--- Etot from the early reflection
    Eref(1,nslot,:)   =   sum(10.^(ER(nrefl,4:11)/10),1); % linear sum

    %--- Idir from the early reflection
    Eref(2,nslot,:) =   sum(Irx(nrefl,:),1);
    Eref(3,nslot,:) =   sum(Iry(nrefl,:),1);
    Eref(4,nslot,:) =   sum(Irz(nrefl,:),1);
end
if nslot > size(Etot,1)
    late_env = zeros(4,nslot,size(Etot,2));
else

% Bformat response (Ambisonic 1st order 3D: W, X, Y, Z) late response
late_env        =   zeros(4,size(Etot,1),size(Etot,2));

late_env(1,:,:) =   10.^(Etot/10) -  reshape(Eref(1,:,:),size(Eref,2),8);
late_env(2:4,:,:) =  Idir-Eref(2:4,:,:);
end
% zeros before the start of the late response (to account for the substraction error 
% due to the truncature of the dB values) -- only until the DS
late_env(:,1:nslotlast,:)=zeros(4,nslotlast,8);

% Idir_late_norm  =   reshape(sqrt(sum(late_env(:,2:4,:).^2,2)),size(late_env,1),8);
% Eomni_late_lin  =   Etot_late_lin - Idir_late_norm;

%%% interpolating the 8 octave channel envelopes into the channels specified
%%% by BPfilters.mat
fref = [0 10^3*(2.^(-4:3)) LoRA.fs/2];%centre frequencies of Odeon's octave bands extended to 0Hz and fs/2
late_env = cat(3,late_env(:,:,1),late_env,late_env(:,:,8));%extend matrix by repeating the corner values

load BPfilters fc fbw
% g = [1 [fbw(2:31)]./[fc(2:31)*(2^.5-2^-.5)]];
% g(32:length(fc)) = g(end);
% g = repmat(g,size(late_env,2),1);

% % g = [1 fbw(2:end)./(fc(2:end)*(2^.5-2^-.5))];
% % g = repmat(g, size(late_env,2), 1);

late_envJB = zeros(size(late_env,1),size(late_env,2),length(fc));
for i = 1:size(late_env,1);%run through Ambisonics channels (i.e., 1..4)
    late_envJB(i,:,:) = interp1(log10([1 fref(2:end)].'),squeeze(late_env(i,:,:)).',log10([1 fc(2:end)].')).';
%     late_envJB(i,:,:) = (interp1(log10([1 fref(2:end)].'),squeeze(late_env(i,:,:)).',log10([1 fc(2:end)].')).').*g;
end

%% Synthesis
%--------------------------------------------------------------------------
% Enveloppe for late reflection for each loudspeaker 

% Decoding the envelopes
%Senv = AmbDecM(LoRA,late_env,0,1);
SenvJB = AmbDecM(LoRA,late_envJB,0,1);
global outlate
if isprint == 1 % output the encoded late reflection enveloppe
%    outlate = {late_env,Eref,resol,sresol};%,Idir_late_norm};
    outlateJB = {late_envJB,Eref,resol,sresol};%,Idir_late_norm};
else % for auralization
    %Multiply the enveloppe with uncorrelated noise sign(Senv).*
%    outlate = AddNoiseSF(LoRA,sqrt(abs(Senv)/sresol),fs,resol,1:8,logdest);
    outlate = AddNoiseJB(LoRA,sqrt(abs(SenvJB)/sresol),fs,resol,1:length(fc),logdest);
end



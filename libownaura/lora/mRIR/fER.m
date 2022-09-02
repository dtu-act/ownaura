% fER
%
% Calculate the early reflection multichannel impulse response.
%
% input:
%   -ER          [:,15] data matrix obtained with ReadEarlyReflections.m
%   -fs          sampling frequency
%   -M           Ambisonic order
%   -isprint     0:  output the early multichannel response
%                1:  output the enveloppe of the omnidriectionnal channel W 
%                2:  output the encoded ambisonic format 
%
% output:
%   -outlate     matrix (samples,channels), early multichannel response
%   -outprint    vector, envelope of the omnidriectionnal channel W
% 
% uses OctFiltb.m, LoudspeakersPos.m, NearestLoud.m, AmbEncM.m and AmbDecM.m
%
% (c) 2007 S. Favrot, CAHR
%___________________________________
% $Revision: 2010/10/25 $ 
%    - global LoRA removed
%
% $Revision: #1 $ 
%    - input matrix ER as from read by ReadEarlyReflections.
%
% $Revision: #1 $ 
%    - Initial version.
%___________________________________

function [outER,outprint] = fER(LoRA,ER,fs,M,move_ER,isprint)

if nargin < 5
    move_ER = 0;
end
if nargin < 6
    isprint = 0;
end

if size(ER,2)~=15
    error('ER shoud be a matrix of 15 columns')
end

%%   Initialisations
%--------------------------------------------------------------------------

ER(1:end,4:11)=10.^((ER(1:end,4:11))/20);

% if reflection comes before move_ER milliseconds, move by move_ER
% milliseconds to the back.
if move_ER
    for i = 1:size(ER, 1)
        if ER(i, 2) < move_ER
            ER(i, 2) = ER(i, 2) + move_ER;
        else
            break;
        end
    end
end
       
%% Analysis
%--------------------------------------------------------------------------
% Extracting information from the Early reflection data
% In which time sample each reflection occurs
treffs          =  round((ER(:,2)/1000)*fs)+1;

% [G,GN]          =  grp2idx(treffs);
% building ERtmp(nrefl,(1:8 -> band, 9 -> time slot, 10 -> theta, 11, -> delta); 
ERtmp           =  [ER(:,4:11) treffs deg2rad(ER(:,13)) deg2rad(ER(:,14)) ER(:,12)];
[Erx,Ery,Erz]   =  sph2cart(ERtmp(:,10)*linspace(1,1,8), ERtmp(:,11)*linspace(1,1,8),...
                        ERtmp(:,1:8));

if isprint==0

ERtmp     =  [diag((-1).^(ERtmp(:,9)'))*ERtmp(:,1:8) ERtmp(:,9:end)];
end

ERref = cat(2,ERtmp(:,1),ERtmp(:,1:8),ERtmp(:,8));%extend matrix by repeating the corner values
load BPfilters fc
ERint = interp1(log10([1 10^3*(2.^(-4:3)) LoRA.fs/2]).',ERref.',log10([1 fc(2:end)]).').';%interpolated ER frequency weights


if M
    %%%BERamb2nd = AmbEncM(LoRA,ERtmp(:,1:8),ERtmp(:,10),ERtmp(:,11),M);
    BERamb2nd = AmbEncM(LoRA,ERint,ERtmp(:,10),ERtmp(:,11),M);
   
    if isprint == 1
         outER = OctFiltImp(LoRA,BERamb2nd,ERtmp(:,9));
    elseif isprint==2
        outER = BERamb2nd;
    else

        outER = AmbDecM(LoRA,BERamb2nd,ERtmp(:,9),M);
    end

else
    % closest Loudspeaker
    % Loudspeakers positions
    L_posr  = LoRA.pos;
    %%%outER = NearestLoud(LoRA,ERtmp(:,1:8),ERtmp(:,10),ERtmp(:,11),ERtmp(:,9),fs,L_posr);
    outER = NearestLoud(LoRA,ERint,ERtmp(:,10),ERtmp(:,11),ERtmp(:,9),fs,L_posr);
end

    outprint    = 1;
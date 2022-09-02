% fDS
%
% Calculate the direct sound multichannel impulse response.
%
% input:
%   -DS          [1,15] First line of ER return by ReadEarlyReflections.m
%   -fs          sampling frequency
%   -M           Ambisonic order
%   -isprint     0:  output the DS multichannel response
%                1:  output the enveloppe of the omnidriectionnal channel W
%                2:  output the encoded ambisonic format
%
% output:
%   -outDS       matrix (samples,channels), early multichannel response
%
% uses OctFiltb.m, NearestLoud.m, AmbEncM.m and AmbDecM.m
%___________________________________
% $Revision: 2010/10/25 $ 
%    - global LoRA removed
%
% $Revision: #1 $ 
%    - input gain in dB 
%
% $Revision: #1 $ 
%    - Initial version.
%___________________________________
% (c) 2007 S. Favrot, CAHR

function outDS = fDS(LoRA,DS,fs,M,isprint)

if nargin < 5
    isprint = 0;
end

% Initialisations
DSspl   = 10.^((DS(4:11))/20);        % linear attenuation in the 8 octave bands
DStheta = deg2rad(DS(13));          % azimuth in radian ]-pi,pi]
DSdelta = deg2rad(DS(14));          % elevation in radian ]-pi,pi]
DSslot  = round((DS(2)/1000)*fs)+1; % time of arrival in sample
% L_posr  = LoudspeakersPos;          % Loudspeakers positions

load BPfilters fc    %read centre frequencies of final BP-filterbank
DSsplJB = interp1(log10([1 10^3*(2.^(-4:3)) LoRA.fs/2]), [DSspl(1) DSspl DSspl(8)],log10([1 fc(2:end)]));%interpolated linear attenuation of DS in frequency bands

if M                                % Ambisonic Mth order coding 
    %--- Encoding ---
    B = AmbEncM(LoRA,DSsplJB,DStheta,DSdelta,M);

    if isprint == 1                 % for linear plot (not currently supported
        outDS=[];
        for k = 1:size(B,2)
            tmp       = reshape(B(:,k,:),size(B,1),8);
            outDS(k,:) = OctFiltb(tmp,fs,1:8)';
        end
    elseif isprint==2               % for colorplot
        outDS = B;
    else                            % for the direct sound response
        %--- Decoding ---
        outDS = AmbDecM(LoRA,B,DSslot,M);
    end
else                                % closest Loudspeaker
    outDS = NearestLoud(LoRA,DSsplJB,DStheta,DSdelta,DSslot,fs,LoRA.pos);
end
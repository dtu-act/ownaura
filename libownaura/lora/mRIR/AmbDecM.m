% AmbDecM
%
% Decoding of Ambisonic channels of Mth order. 
%
% input:
%   B           (Ambisonic channels, samples, bands=L)
%   Loudset     (nb of loudspeakers,direction(theta, delta)): Loudspeakers
%               positions.
%   tslot       vector of time sample of each discrete reflection: filtered decoding
%               (used by fDS and fER)
%               0: non filtered decoding (used by fLATE)
%
% output:
%   S           (samples, speaker channels): decoded signals for each
%               loudspeaker (filtered decoding)
%               (samples, speaker channels,bds): decoded signals for each
%               loudspeaker and each band (non filtered decoding)
%
% uses OctFiltImp.m and YmnsM.m
%
% From: Daniel, J., Nicol, R. & Moreau, S. (2003), ‘Further investigations of high order
% ambisonics and wavefield synthesis for holophonic sound imaging’, Presented
% at the AES 114th convention p. preprint 5788.
%       Daniel, J., Rault, J. B. & Polack, J. D. (1998), ‘Ambisonics encoding of other
% audio formats for multiple listening conditions’, Presented at the AES 105th
% convention p. preprint 4795.
%___________________________________
% % $Revision: 2010/10/25 $ 
%    - remove global LoRA
%
% % $Revision: #1 $ 
%    - Shell filters for the filtered decoding
%
% $Revision: #1 $ 
%    - Uniformization between filtered and non filtered, decoding matrix, simplification
%   Loudset removed.
%
% $Revision: #1 $ 
%    - Initial version.
%___________________________________
% (c) 2007 S. Favrot, CAHR
%


function S = AmbDecM(LoRA,B,tslot,M)


% if M==1, bdcut = 4; end
% if M==2, bdcut = 5; end
% if M==3, bdcut = 5; end
% if M>3, bdcut = 6; end

% % Decoding matrix D1 and D2 computed in LoRA_startup

%-------------------------------
%shell filters
fs=LoRA.fs;
% fcbank      = 10^3*(2.^(-4:3));
% fcut = fcbank(bdcut)*sqrt(2);
fcut = 800*M;
fcutn = fcut/(fs/2);
[b,a] = butter(5,fcutn);
[b2,a2] = butter(5,fcutn,'high');
[h,w] = freqz(b,a,256,fs);
[h2,w2] = freqz(b2,a2,256,fs);
b1 = fir2(256,[w;fs/2]/(fs/2),[abs(h).^2;abs(h(end)).^2]);
b2 = fir2(256,[w2;fs/2]/(fs/2),[abs(h2).^2;abs(h2(end)).^2]);
%-------------------------------

D = LoRA.DecMat.D1{M};
Dm = LoRA.DecMat.D2{M};
if tslot    % filtering before decoding
    % filtering
    if LoRA.isnfc
        Bf = OctNFCImp(LoRA,B,tslot,M);
    else
        %%%Bf = OctFiltImp(LoRA,B,tslot);
        Bf = BpFiltImpJB(LoRA,B,tslot);
    end

    S1 = zeros(size(D,1),size(Bf,2));
    S2 = zeros(size(D,1),size(Bf,2));
    for bd=1:LoRA.hL % mixed
        S1 = S1 + D*Bf(:,:,bd);
        S2 = S2 + Dm*Bf(:,:,bd)*LoRA.DecMat.energycoeff;
    end
    S = fftfilte(b1,S1')+fftfilte(b2,S2');
    bL = length(b1);
    S = S(ceil(bL/2):end,:);

else        % no filtering
    if LoRA.isAmb2D
        B = B(1:2*M+1,:,:);
    end
    %S = zeros(size(B,2),size(D,1),8);
    S = zeros(size(B,2),size(D,1),LoRA.hL);

    % basic decoding for all bands (for the late reverberation part)
    for bd = 1:LoRA.hL   
        S(:,:,bd) = (D*B(:,:,bd))';
    end
end


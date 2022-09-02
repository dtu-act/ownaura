function AmbDecwriteconv(LoRA,fileout,fBformat,M,sndrge,gain,tail,logdest)

if nargin<5
    sizwav = wavread(fBformat,'size'); 
    sndrge = [1 sizwav(1)];
    if nargin<6
        gain = 1;
        if nargin<7
            tail=0;
            if nargin<8
                logdest=0;
            end
        end
    end
end
%initialisation Amb
IR = LoRA.hm; 

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
fcut = 600*M;
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
cf = LoRA.DecMat.energycoeff;

%initialisation conv
nIR = size(IR,1);
nchan = size(IR,2);
nfft = 2^16;
IR=[IR;zeros(mod(nIR,2),nchan)];

L = nfft - nIR-mod(nfft - nIR,4);
B1 = fft(IR,nfft).*repmat(conj(fft(b1,nfft)'),1,nchan);
B2 = fft(IR,nfft).*repmat(conj(fft(b2,nfft)'),1,nchan);
nb = nfft-L;

istart = sndrge(1);
yrem = zeros(nb-1,nchan);
k = 0;
% yend = 1;
ns = 1;
writelog(logdest,'...')
Lc=ceil((sndrge(2)-istart+nb-1)/L);
while istart <= sndrge(2)
    k = k+1;
    writelog(logdest,'\b\b\b%3.0f',k/Lc*100)
    iend = min(istart+L-1,sndrge(2));
    x = wavread(fBformat, [istart iend]);
    X = fft(x*gain,nfft);
    y = ifft((X*D').*B1)+ifft((X*Dm'*cf).*B2);
    y(1:nb-1,:) = y(1:nb-1,:)+yrem;
    %     yend = min(iend-istart+1,L);
    if iend < sndrge(2)
        yend = L;
        yrem = y(yend+1:yend+nb-1,:);
    else
        if tail
            yend = iend-istart+nb;
        else
            yend=iend-istart;
        end
    end
    ne = ns+yend-1;
    wavreadandadd(fileout,[ns ne],y(1:yend,1:nchan));
    istart = istart + L;
    ns = ne+1;
end
% if k<Lc
    writelog(logdest,'\b\b\b')
% end
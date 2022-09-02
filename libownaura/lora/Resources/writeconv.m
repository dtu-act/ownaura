function writeconv(fileout,IR,hm,offset,sndfile,sndrge,gain,tail,logdest)

if nargin<6
    info = audioinfo(sndfile);
    sndrge = [1 info.TotalSamples];
    if nargin<7
        gain = 1;
        if nargin<8
            tail=1;
            if nargin<9
                logdest=0;
            end
        end
    end
end

%initialisation
nIR = size(IR,1);
nchan = size(IR,2);
nfft = 2^nextpow2(nIR*2);
IR=[IR;zeros(mod(nIR,2),nchan)];

L = nfft - nIR-mod(nfft - nIR,4);
if ~isempty(hm) %equalization
    B = fft(IR,nfft).*fft(hm(:,1:nchan),nfft);
else
    B = fft(IR,nfft);
end
nb = nfft-L;


istart = sndrge(1);
yrem = zeros(nb-1,nchan);
k = 0;
% yend = 1;
ns = offset;
writelog(logdest,'...')
Lc=ceil((sndrge(2)-istart+nb-1)/L);
while istart <= sndrge(2)
    k = k+1;
    writelog(logdest,'\b\b\b%3.0f',k/Lc*100)
    iend = min(istart+L-1,sndrge(2));
    x = audioread(sndfile, [istart iend]);
    X = fft(x*gain,nfft);
    y = ifft(repmat(X,1,nchan).*B);
    y(1:nb-1,:) = y(1:nb-1,:)+yrem;
    %     yend = min(iend-istart+1,L);
    if iend < sndrge(2)
        yend = L;
        yrem = y(yend+1:yend+nb-1,:);
    else
        if tail
            yend = iend-istart+nb-1;
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
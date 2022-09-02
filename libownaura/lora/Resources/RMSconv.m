function [rC,rOrg,rIR]=RMSconv(IR,sndfile,tail,sndrge)

%initialisation
nIR = size(IR,1);
nchan = size(IR,2);
nfft = 2^nextpow2(nIR*2);
IR=[IR;zeros(mod(nIR,2),nchan)];

L = nfft - nIR-mod(nfft - nIR,4);
B = fft(IR,nfft);
nb = nfft-L;
if nargin<3
    tail=1;
end
if nargin<4
    sizwav = wavread(sndfile,'size'); 
    sndrge = [1 sizwav(1)];
end

%init loop
istart = sndrge(1);
yrem = zeros(nb-1,nchan);
k = 0;
% yend = 1;
% ns = 1;
fprintf('...');
Lc=ceil((sndrge(2)-istart+nb-1)/L);
ssqC = 0;
ssqx = 0;
while istart <= sndrge(2)
    k = k+1;
    fprintf('\b\b\b%3.0f',k/Lc*100)
    iend = min(istart+L-1,sndrge(2));
    x = wavread(sndfile, [istart iend]);
    ssqx = ssqx + sum(x.^2);
    X = fft(x,nfft);
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
%     ne = ns+yend-1;
    % Action
    ssqC = ssqC + sum(sum(y(1:yend,1:nchan),2).^2);
%     wavexreadandadd(fileout,[ns ne],y(1:yend,1:nchan));
    
    istart = istart + L;
%     ns = ne+1;
end
if tail
    len = sndrge(2)-sndrge(1)+nb-1;
else
    len = sndrge(2)-sndrge(1)+1;
end
rC = sqrt(ssqC/len);
rOrg = sqrt(ssqx/(sndrge(2)-sndrge(1)+1));
rIR = sqrt(sum(sum(IR,2).^2));
    fprintf('\b\b\b\n')

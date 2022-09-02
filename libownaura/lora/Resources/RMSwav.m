function [rx,mx] = RMSwav(sndfile,sndrge)
% Revised 16/02/2012 Chris, to calculate maximum magnitude value

% Initialisation
if nargin<2
    sizwav = wavread(sndfile,'size'); 
    sndrge = [1 sizwav(1)];
end
% block size
L = min(2^16,sndrge(2)-sndrge(1)/10);

%init loop
istart = sndrge(1);

k = 0;
fprintf('...');
ssqx = 0;
Lc=ceil((sndrge(2)-istart)/L);
maxOvr = 0; % Overall maximum (found among all channels)
while istart <= sndrge(2)
    k = k+1;
    fprintf('\b\b\b%3.0f',k/Lc*100)
    iend = min(istart+L-1,sndrge(2));
    x = wavread(sndfile, [istart iend]);
    maxCur = max(abs(x(:)));
    if maxCur > maxOvr
        maxOvr = maxCur;
    end
    ssqx = ssqx + sum(sum(x,2).^2);
    istart = istart + L;
end
len = sndrge(2)-sndrge(1)+1;
rx = sqrt(ssqx/len);
mx = maxOvr;
fprintf('\b\b\b\n')

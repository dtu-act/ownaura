% out = AddNoise(in,fs,resol,bds)
%
% Multiply loudspeaker signal enveloppes by uncoreelated bandpass noise
%
% input:
%   in          (enveloppe time,loudspeaker channels,band) envelopes for each
%               loudspeaker in each band
%   fs          sampling frequency
%               positions.
%   resol       time resolution of the enveloppes
%   bds         considered bands
%
% output:
%   out         out(time,loudspeaker channels) uncorrelated noise accross channel
%___________________________________
% $Revision: #5 $ 
%    - Enveloppe multiplication with and then filtering
%    - Energy compensation: ensure the result to have the energy stated in 'in'
%
% $Revision: #5 $ 
%    - Randomly compute noise
%    - Low pass filter of the enveloppe to limit spectral spreading
%
% $Revision: #5 $ 
%    - Using pre computed bandpass noise
%
% $Revision: #5 $ 
%    - Initial version.
%___________________________________
% (c) 2007 S. Favrot, CAHR
%

function [out,bk] = AddNoise(LoRA,in,fs,resol,bds,logdest)

if nargin<6
    logdest = 0;
end
out = 0; bk=1;

% Initialisation
L           = size(in,1);
nLL         = size(in,2);
sresol      = floor(resol/1000*fs);
lennoise    = sresol*L;
y           = zeros(lennoise,nLL);
xi          = (0:L)+0.5; % one sample added to acccount for problem due to non-zeros starting enveloppes
yi          = (0:sresol*(L+1)-1)/sresol;
hlen2       = (LoRA.hlen-1)/2;

% Initialisation of the energy compensation 
fcbank      = 10^3*(2.^(-4:3));
fbw         = fcbank/sqrt(2);
fbw(1)      = fcbank(1)*sqrt(2); 
fbw(end)    = LoRA.fs/2-fcbank(end)/sqrt(2);
hsquare     = fbw*2/LoRA.fs; % square sum of the filters IR 

% Generation of the random noise
noiseout = randn(lennoise,nLL);
if ~writelog(logdest,'...'),return,end

% for each loudspeaker channel
for nL = 1:nLL
    if ~writelog(logdest,'\b\b\b%3.0f',nL/nLL*100),return,end
    
    % Channel selection 
    inr     = reshape(in(:,nL,bds),L,length(bds));
    % Interpolation of the envelopes (for each band)
    env     = interp1(xi,[zeros(1,8);inr],yi,'pchip');
%     env = rectpulse(inr(:,:),sresol);
    env     = env(sresol+1:end,:);
    % Enveloppes multiplication and then filtering
    ytmp    = fftfilt(LoRA.h,[noiseout(:,nL(ones(1,8))).*env;zeros(hlen2,8)]);
    % Energy compensation to ensure the result to have the energy stated in 'inr'
    nrgcomp = sqrt(sum(inr.^2*sresol,1)./(sum(ytmp.^2)./hsquare));
    ytmp    = ytmp(hlen2+1:end,:)*diag(nrgcomp);
    % Sum of all bands
    y(:,nL)=sum(ytmp,2);

end
if ~writelog(logdest,'\b\b\b'),return,end
out     = y;
bk      = 0;
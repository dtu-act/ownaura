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
% $Revision: #1 $ 
%    - Enveloppe multiplication with and then filtering
%    - Energy compensation: ensure the result to have the energy stated in 'in'
%
% $Revision: #1 $ 
%    - Randomly compute noise
%    - Low pass filter of the enveloppe to limit spectral spreading
%
% $Revision: #1 $ 
%    - Using pre computed bandpass noise
%
% $Revision: #1 $ 
%    - Initial version.
%___________________________________
% (c) 2007 S. Favrot, CAHR
%

function out = AddNoiseJB(LoRA,in,fs,resol,bds,logdest)

if nargin<6
    logdest = 0;
end

% Initialisation
L           = size(in,1);
nLL         = size(in,2);
sresol      = floor(resol/1000*fs);
lennoise    = sresol*L;
y           = zeros(lennoise,nLL);
xi          = (0:L)+0.5; % one sample added to acccount for problem due to non-zeros starting enveloppes
yi          = (0:sresol*(L+1)-1)/sresol;
hlen2       = (LoRA.hlen-1)/2;
Nch         = length(bds);%number of frequency channels
seed        = LoRA.seed;

% Initialisation of the energy compensation 
load BPfilters fc fbw h
hsquare     = fbw*2/LoRA.fs; % square sum of the filters IR 

% Generation of the random noise
if ~isempty(seed)
    rng(seed);
end
noiseout = randn(lennoise,nLL);
writelog(logdest,'...')

% for each loudspeaker channel
for nL = 1:nLL
    writelog(logdest,'\b\b\b%3.0f',nL/nLL*100)
    
    % Channel selection 
    inr     = reshape(in(:,nL,bds),L,length(bds));
    % Interpolation of the envelopes (for each band)
    env     = interp1(xi,[zeros(1,Nch);inr],yi,'pchip');
%     env = rectpulse(inr(:,:),sresol);
    env     = env(sresol+1:end,:);
    % Enveloppes multiplication and then filtering
    ytmp    = fftfilt(h,[noiseout(:,nL(ones(1,Nch))).*env;zeros(hlen2,Nch)]);
    % Energy compensation to ensure the result to have the energy stated in 'inr'
    nrgcomp = sqrt(sum(inr.^2*sresol,1)./(sum(ytmp.^2)./hsquare));
    % If there is 0 energy in a band (i.e. the lowest 63Hz octave band),
    % change resulting, from division by zero, NaN to zero
    nrgcomp(isnan(nrgcomp)) = 0;
    
    ytmp    = ytmp(hlen2+1:end,:)*diag(nrgcomp);
    % Sum of all bands
    y(:,nL)=sum(ytmp,2);

end
writelog(logdest,'\b\b\b')
out         = y;

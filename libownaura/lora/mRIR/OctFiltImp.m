% out = OctFiltImp(in,tslot)
%
% For each band, transform the attenuation in each band (discrete domain) by the 
% impulse response of the corresponding band filter (temporal domain)
%
% in     (discrete reflection, channel, band)
% out    (time, channel, band) 
%
%________________________________________
% $Revision: 2010/10/25 $ 
%    - global LoRA removed
%

function out = OctFiltImp(LoRA,in,tslot)


% bds = 1:8;

% if first impulse too close to the beginning (ringing before the pic of the impulse)
negring=0;
if tslot(1)<(LoRA.hlen-1)/2+1
    tslot = tslot+(LoRA.hlen-1)/2;
    negring = 1;
end

len = tslot(end)+(LoRA.hlen-1)/2;
out = zeros(size(in,1),len,8);
for bd = 1:8 % for each band
    for t = 1:length(tslot) % for each discrete reflection
        % attenuated impulse response for the band
        reflfilt = in(:,t,bd)*LoRA.h(:,bd)';
        % place these impulse response in response
        tmp = out(:,tslot(t)-(LoRA.hlen-1)/2:tslot(t)+(LoRA.hlen-1)/2,bd);
        out(:,tslot(t)-(LoRA.hlen-1)/2:tslot(t)+(LoRA.hlen-1)/2,bd) = tmp+reflfilt;
    end
end

if negring
    out = out(:,(LoRA.hlen-1)/2+1:end,:);
end
    
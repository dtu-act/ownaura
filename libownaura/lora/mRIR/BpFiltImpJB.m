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

function out = BpFiltImpJB(LoRA,in,tslot)


% if first impulse too close to the beginning (ringing before the pic of the impulse)
negring=0;
if tslot(1)<(LoRA.hlen-1)/2+1
    tslot = tslot+(LoRA.hlen-1)/2;
    negring = 1;
end

len = tslot(end)+(LoRA.hlen-1)/2;
out = zeros(size(in,1),len,LoRA.hL); % not: single precision to save memory (changed by aahr)
FBLen = (LoRA.hlen-1)/2;

PL = LoRA.hL*length(tslot);
fprintf('Processing in BpFiltImpJB()... ')
indx = 0;

for bd = 1:LoRA.hL % for each band
    for t = 1:length(tslot) % for each discrete reflection
        indx = indx + 1;
        dispText = [num2str(indx) ' out of ' num2str(PL)];
        fprintf(dispText)
        % attenuated impulse response for the band
% %         reflfilt = in(:,t,bd)*LoRA.h(:,bd)';
        % Optimised multiplication considering the fact that each
        % in(:,t,bd) vector has only one non-zero element (impulse
        % describing a single reflection)
        nZerInd = find(in(:,t,bd)); % L/S index where examined single reflection is mapped
        reflfilt = in(nZerInd,t,bd)*LoRA.h(:,bd)'; % scaled filterbank response for given reflection
        
        % place these impulse response in response
        tsampleS = tslot(t) - FBLen;
        tsampleE = tsampleS + 2*FBLen;
% %         tmp = out(:,tsampleS:tsampleE,bd);
        out(nZerInd,tsampleS:tsampleE,bd) = out(nZerInd,tsampleS:tsampleE,bd) + reflfilt;

        fprintf([repmat(8,1,length(dispText)) '']) % delete the 'x out of y' part before refreshing in next loop pass
    end
end
fprintf([num2str(PL) ' out of ' num2str(PL) '... Completed!   \n'])

if negring
    out = out(:,(LoRA.hlen-1)/2+1:end,:);
end

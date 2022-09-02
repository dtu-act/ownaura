% out = OctNFCImp(in,tslot)
%
% For each band, transform the attenuation in each band (discrete domain) by the
% impulse response of the corresponding band filter (temporal domain), Near-field
% coding version.
%
% in     (discrete reflection, channel, band)
% out    (time, channel, band)
%___________________________________
% $Revision: 2010/10/25 $ 
%    - global LoRA removed
%
% $Revision: #1 $ 
%    - Cosine shape window to avoid bass-boost effect
%
% $Revision: #1 $ 
%    - Initial version.
%___________________________________
% (c) 2009 S. Favrot, CAHR
%

function out = OctNFCImp(LoRA,in,tslot,M)

tslotini=tslot;
c = 343;
% dBmax = 30;
HR = NFCfilt(LoRA.LoudR,M,LoRA.hlen,LoRA.fs);

if LoRA.isAmb2D
    ind=1;
    for m=1:M
        ind=[ind (m+1)*ones(1,2)];
    end
else
    ind=1;
    for m=1:M
        ind=[ind (m+1)*ones(1,2*m+1)];
    end
end 

% if first impulse too close to the beginning (ringing before the pic of the impulse)
negring=0;
if tslot(1)<(LoRA.hlen-1)/2+1
    tslot = tslot+(LoRA.hlen-1)/2;
    negring = 1;
end

len = tslot(end)+(LoRA.hlen-1)/2;
out = zeros(size(in,1),len,8);

for t = 1:length(tslot) % for each discrete reflection
    % compute Hrho function
    rho = tslotini(t)/LoRA.fs*c;
    [Hrho,fa] = NFCfilt(rho,M,LoRA.hlen,LoRA.fs);
%     % cos shape windows (regularization)
%     Mf=(rho*2*pi)/c*fa;
%     maskh=((cos(pi*(1./Mf)*(0:M))+1)/2).*((1./Mf)*(0:M)<=1);
    % Tickonov
    l=1;
    maskh=(1+l^2)./(1+abs(Hrho./HR).^2*l^2);
    % double side spectrum
    Hnfcreg = Hrho./HR.*maskh;
    Hnfcreg(1,:)=real(Hnfcreg(1,:));
    if mod(LoRA.hlen,2)
        Hnfcreg=[Hnfcreg;conj(flipud(Hnfcreg(2:end,:)))];
    else
        Hnfcreg=[Hnfcreg;real(Hnfcreg(end,:));conj(flipud(Hnfcreg(2:end,:)))];
    end
    
    for bd = 1:8 % for each band
        hnfcoct = ifft(Hnfcreg(:,ind).*LoRA.H(:,bd*ones(1,length(ind))));
        % attenuated impulse response for the band
        reflfilt = diag(in(:,t,bd))*hnfcoct';
        % place these impulse response in response
        tmp = out(:,tslot(t)-(LoRA.hlen-1)/2:tslot(t)+(LoRA.hlen-1)/2,bd);
        out(:,tslot(t)-(LoRA.hlen-1)/2:tslot(t)+(LoRA.hlen-1)/2,bd) = tmp+reflfilt;
    end
end

if negring
    out = out(:,(LoRA.hlen-1)/2+1:end,:);
end

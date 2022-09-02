% NearestLoud
%
% affect each reflection to the nearest loudspeaker
%
% input:
%   S           (nb of sources,bands=8): linear attenuation in each octave 
%               band for each source.  
%   theta       (nb of sources,1): sources azimuth
%   delta       (nb of sources,1): sources elevation
%   tslot       (nb of sources,1): time slot of each source (in samples 
%               according to fs)
%   fs          sampling frequency
%
% output:
%   outnL       (samples,channels): nearest loudspeaker response.
% 
%___________________________________
% $Revision: 2011/02/01 $ 
%    - Closest distance between the target source and the loudspeakers
%___________________________________
% (c) 2007 S. Favrot, CAHR

function [outnL,Nclosest] = NearestLoud(LoRA,S,theta,delta,tslot,fs,Loudset)

% Initialisation
Nclosest=[];
sig_band = zeros(size(Loudset,1),length(tslot),LoRA.hL);

[xs,ys,zs]=sph2cart(Loudset(:,1)+pi/2,Loudset(:,2),ones(size(Loudset,1),1));


% For each reflection
for k = 1:length(theta)
    % Find which is the closest loudspeaker
    [xt,yt,zt]=sph2cart(theta(k)+pi/2,delta(k),1);
    [m,idx]=min((xs-xt).^2+(ys-yt).^2+(zs-zt).^2);
    Nclosest(k) = idx;
    
    % Compute the response for this loudspeaker
    sig_band(Nclosest(k),k,:)= S(k,:);

end
out     = BpFiltImpJB(LoRA,sig_band,tslot);
outnL   = sum(out,3)';


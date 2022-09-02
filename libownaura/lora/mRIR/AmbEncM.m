% AmbEncM
%
% Encoding of virtual sources from the direction [theta,delta] in Ambisonic order M 
%
% input:
%   S           (nb of sources,bands=L): linear attenuation in each frequency 
%               band for each source.  
%   theta       (nb of sources,1): sources azimuth
%   delta       (nb of sources,1): sources elevation
%   M           Ambisonic order
%
% output:
%   B           (channels,samples,bands=L):  ambisonic channels (M+1)^2
%               encoded time course of the successive sources in L frequency bands.
% 
% uses Ymns.m 
%
% From: Daniel, J., Nicol, R. & Moreau, S. (2003), ‘Further investigations of high order
% ambisonics and wavefield synthesis for holophonic sound imaging’, Presented
% at the AES 114th convention p. preprint 5788.
%       Daniel, J., Rault, J. B. & Polack, J. D. (1998), ‘Ambisonics encoding of other
% audio formats for multiple listening conditions’, Presented at the AES 105th
% convention p. preprint 4795.
%___________________________________
% $Revision: 2010/10/25 $ 
%    - global LoRA removed
%
% $Revision: #1 $ 
%    - 2D encoding 
%
% $Revision: #1 $ 
%    - no filtering 
%
% $Revision: #1 $ 
%    - Initial version.
%___________________________________
% (c) 2007 S. Favrot, CAHR
%

function B = AmbEncM(LoRA,S,theta,delta,M)

% spherical harmonics functions
c               =  YmnsM(theta,delta,M,LoRA.isAmb2D)';

B=zeros(size(c,1),length(theta),LoRA.hL);

% Computation of the ambisonic time course from the ER (B=y.S)
for bd = 1:LoRA.hL
    B(:,:,bd)=c*diag(S(:,bd));
end

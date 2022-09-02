% YmnsM
%
% Spherical harmonics functions for N different positions
%
% input:
%   theta       column vector (length N): azimuth (in rad)
%   delta       column vector (length N): elevation (in rad)
%   M           int: Ambisonic order
%   isset2D     bool: 1 for a 2D spherical harmonics, 0 for 3D
%
% output:
%   y           (K components,N):  each line of the matrix correspond to one
%               ambisonic component, each colomn to a position.
%               3D: K = (M+1)^2
%               3D: K = 2M+1
%
% Adapted from: 
%       Daniel, J., Nicol, R. & Moreau, S. (2003), ‘Further investigations of high order
% ambisonics and wavefield synthesis for holophonic sound imaging’, Presented
% at the AES 114th convention p. preprint 5788.
%       Daniel, J., Rault, J. B. & Polack, J. D. (1998), ‘Ambisonics encoding of other
% audio formats for multiple listening conditions’, Presented at the AES 105th
% convention p. preprint 4795.
%
% Normalized 3D or 2D convention
%___________________________________
% $Revision: #1 $
%    - 2D funcitons included
%
% $Revision: #1 $
%    - Initial version.
%___________________________________
% (c) 2008 S. Favrot, CAHR


function y = YmnsM(theta, delta, M, isset2D)

if nargin<4
    isset2D=0;
end

if isset2D
    % 2D "spherical" harmonics
    y       = ones(length(theta),2*M+1);
    k = 1;
    ncoeff = 1;
    for m = 0:M
        % Schmidt Seminormalized Associated Legendre Functions (the term (-1)^n is not present
        % contrary to the Matlab help)
        leg=legendre(m,sin(delta),'sch');
        for n = m     
            for s = 1:-2:-(n~=0)
                y(:,k) = ncoeff*leg(n+1,:)'.*...
                    ((n==0)+(n~=0)*((s==1)*cos(n*theta)+(s==-1)*sin(n*theta)));
                k = k+1;
            end
        end
        ncoeff = ncoeff *2*(m+1)/sqrt((2*m+2)*(2*m+1));
    end
else
    % 3D spherical harmonics
    y       = ones(length(theta),(M+1)^2);
    k = 1;
    for m = 0:M
        % Schmidt Seminormalized Associated Legendre Functions (the term (-1)^n is not present
        % contrary to the Matlab help)
        leg=legendre(m,sin(delta),'sch');
        for n = m:-1:0
            for s = 1:-2:-(n~=0)
                y(:,k) = sqrt(2*m+1)*leg(n+1,:)'.*...
                    ((n==0)+(n~=0)*((s==1)*cos(n*theta)+(s==-1)*sin(n*theta)));
                k = k+1;
            end
        end
    end
end


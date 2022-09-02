% gm
% Coefficients for Ambisonic decoding maximizing the norm of the energy vector rE
% (max rE) for the Mth order decoding.
%
% input:
%   M           Ambisonic order
%   isset2D     bool: 1 for a 2D sphericla harmonics
%
% output:
%  g            3D: (M+1)^2 length vector
%               2D: 2*M+1 length vector
%
% From:
%       Daniel, J., Nicol, R. & Moreau, S. (2000), ‘Representation de champs
% acoustiques,application à la transmission et à la reproduction de scènes sonores
% complexes dans un contexte multimedia’, PhD thesis, 1996-2000 Université
% Paris 6.
%___________________________________
% $Revision: #1 $
%    - 2D funcitons included
%
% $Revision: #1 $
%    - Initial version.
%___________________________________
% (c) 2007 S. Favrot, CAHR

function g = gm(M, isset2D)
g = 1;

if nargin<2
    isset2D=0;
end

if isset2D
    % 2D "spherical" harmonics
    for m = 1:M
        gi = cos(m*pi/(2*M+2))*[1 1];
        g  = [g gi];
    end

else
    % 3D spherical harmonics
    g1 = max(roots(legp(M+1)));
    % if M==1, g1 = sqrt(1/3); end
    % if M==2, g1 = sqrt(3/5); end
    % if M==3, g1 = sqrt((30+4*sqrt(30))/(2*35)); end
    % if M==4, g1 = sqrt((70+4*sqrt(70))/(2*63)); end

    % if M==5, g1 = sqrt(fzero(@(x)231*x.^3-315*x.^2+105*x-5,0.8695)); end
    for m = 1:M
        leg = legendre(m,g1);
        gi = leg(1)*ones(1,2*m+1);
        %     E = E+(2*m+1)*leg(1)^2;
        g  = [g gi];
    end
end

% return the legendre polynom Pm
function p = legp(m)
switch m
    case 0
        p = 1;
    case 1
        p = [1 0];
    otherwise

        %init
        p = zeros(1,m+1);
        pm0 = p;pm0(end) = 1;
        pm1 = p;pm1(end-1) = 1;
        % recursive
        for l=2:m
            p=1/l*((2*l-1)*[pm1(2:end) 0]-(l-1)*pm0);
            pm0 = pm1;
            pm1 = p;
        end

end

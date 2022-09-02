function [Hs,f] = gsmoothspec(f,H,n)

% gammatone filter smoothing



% Initialisation
Hs = zeros(n,size(H,2));
ch = size(H,2);
L = size(H,1);
if length(f)~=L
    error('f and H must have the same length.')
end
if nargin<3 | n==1
    n=L;
    fivect = 1:L;
else
    fivect = floor(logspace(log10(1),log10(L),n));
end
% order of gammatone filter
v = 4;
% bandwidth parameter
b = 24.7*(0.00437*f + 1) * (factorial(v-1)).^2 / (pi*factorial(2*v-2)*2^(-(2*v-2)));

k=0;
% for i = floor(linspace(1,L,n));
for i =  fivect
    k=k+1;
    %power spectrum of gammatone filter
    Wi = (abs((1./(1 + j*(f-f(i))/b(i))).^v)).^2;
    Hs(k,:) = sum(repmat(Wi'/sum(Wi),1,ch).*H,1);
end
f=f(fivect);
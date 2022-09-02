% OctFiltBank
% Return the impulse response of the 8 octave band filters 'h(time,band)' 
% using klh.m and kbp.m. 
% From Orfanidis book "introduciton to signal processing"
% p. 561
% 
% taken from http://www.ece.rutgers.edu/~orfanidi/intro2sp/ (last check
% 13/07/07)

function [h,len]= ThirdOctFiltBank(fs)

% df          = 34.65;
% df          = 10;
df          = 30;
% df          = 50;

% Parameters
Apass       = 1;
Astop       = 20;
fcbank      = 10^3*(2.^((-12:9)/3));
% 
% low pass (first filter)
f2          = fcbank(1)*2^(1/6);
fpass       = f2-df/2;
fstop       = f2+df/2;
s           = 1;
h(:,1)      = klh(s, fs, fpass, fstop, Apass, Astop)';


%  band pass
s=1;
for k = 2:21;%1:8;%
    fc      = fcbank(k);
    f1      = fc*2^(-1/6);
    f2      = fc*2^(1/6);
    fpa     = f1+df/2;
    fsa     = f1-df/2;
    fpb     = f2-df/2;
    fsb     = f2+df/2;
    h(:,k)  = kbp(fs, fpa, fpb, fsa, fsb, Apass, Astop, s)';
end
% high pass (last filter)
f1          = fcbank(22)*2^(-1/6);
fpass       = f1+df/2;
fstop       = f1-df/2;
s           = -1;
h(:,22)      = klh(s, fs, fpass, fstop, Apass, Astop)';

len=length(h(:,1));

% % pink
% fcoeff=sqrt(sum(h.^2));
% h=h*diag(1./fcoeff);



function h = kbp(fs, fpa, fpb, fsa, fsb, Apass, Astop, s)
% kbp.m - bandpass FIR filter design using Kaiser window.
%
% h = kbp(fs, fpa, fpb, fsa, fsb, Apass, Astop, s)
%
% s = 1, -1 = standard, alternative design
% dbp(wa, wb, N) = ideal bandpass FIR filter

Df = min(fpa-fsa, fsb-fpb);  DF = Df / fs;
fa = ((1+s) * fpa + (1-s) * fsa - s * Df) / 2;  wa = 2 * pi * fa / fs;
fb = ((1+s) * fpb + (1-s) * fsb + s * Df) / 2;  wb = 2 * pi * fb / fs;

dpass = (10^(Apass/20) - 1) / (10^(Apass/20) + 1);
dstop = 10^(-Astop/20);
d = min(dpass, dstop);
A = -20 * log10(d);

[alpha, N] = kparm(DF, A);
h = dbp(wa, wb, N) .* kwind(alpha, N);




function w = kwind(alpha, N)
% kwind.m - Kaiser window.
%
% w  = kwind(alpha, N) = row vector
%
% alpha = Kaiser window shape parameter
% N  = 2M+1 = window length (must be odd)

M = (N-1) / 2; 
den = I0(alpha);

for n = 0:N-1,
       w(n+1) = I0(alpha * sqrt(n * (N - 1 - n)) / M) / den;
end



function h = klh(s, fs, fpass, fstop, Apass, Astop)
% klh.m - lowpass/highpass FIR filter design using Kaiser window.
%
% h = klh(s, fs, fpass, fstop, Apass, Astop)
%
% s = 1, -1 = lowpass, highpass
% dlh(s, wc, N) = ideal lowpass/highpass FIR filter

fc = (fpass + fstop) / 2;  wc = 2 * pi * fc / fs;
Df = s * (fstop - fpass);  DF = Df / fs;

dpass = (10^(Apass/20) - 1) / (10^(Apass/20) + 1);
dstop = 10^(-Astop/20);
d = min(dpass, dstop);  
A = -20 * log10(d);

[alpha, N] = kparm(DF, A);
h = dlh(s, wc, N) .* kwind(alpha, N);

function S = I0(x)
% I0.m - modified Bessel function of 1st kind and 0th order.
%
% S = I0(x)
%
% defined only for scalar x >= 0
% based on I0.c

eps = 10^(-9);
n = 1; S = 1; D = 1;

while D > (eps * S),
        T = x / (2*n);
        n = n+1;
        D = D * T^2;
        S = S + D;
end



function h = dbp(wa, wb, N)
% dbp.m - ideal bandpass FIR filter
%
% h = dbp(wa, wb, N) = row vector
%
% N = 2M+1 = filter length (odd)
% wa, wb = cutoff frequencies in [rads/sample]

M = (N-1)/2;

for k = -M:M,
   if k == 0,
      h(k+M+1) = (wb - wa) / pi;
   else
      h(k+M+1) = sin(wb * k) / (pi * k) - sin(wa * k) / (pi * k);
   end
end

function h = dlh(s, wc, N)
% dlh.m - ideal lowpass/highpass FIR filter
%
% h = dlh(s, wc, N) = row vector
%
% s = 1, -1 = lowpass, highpass
% N = 2M+1 = filter length (odd)
% wc = cutoff frequency in [rads/sample]

M = (N-1)/2;

for k = -M:M,
    if k == 0,
        h(k+M+1) = (1-s) / 2 + s * wc / pi;
    else
        h(k+M+1) = s * sin(wc * k) / (pi * k);
    end
end


function [alpha, N] = kparm(DF, A)
% kparm.m - Kaiser window parameters for filter design.
%
% [alpha, N] = kparm(DF, A)
%
% alpha = window shape parameter
% N = window length (odd)
% DF = Df/fs = transition width in units of fs
% A = ripple attenuation in dB; ripple = 10^(-A/20)

if A > 21,                                       % compute D factor
       D = (A - 7.95) / 14.36;
else
       D = 0.922;
end

if A <= 21,                                      % compute shape parameter
       alpha = 0;
elseif A < 50
       alpha = 0.5842 * (A - 21)^0.4 + 0.07886 * (A - 21);
else
       alpha = 0.1102 * (A - 8.7);
end

N = 1 + ceil(D / DF);                            % compute window length
N = N + 1 - rem(N, 2);                           % next odd integer


%NFCfilt
%___________________________________
% $Revision: #1 $ 
%    - Initial version.
%___________________________________
% (c) 2009 S. Favrot, CAHR
%


function [out,f]=NFCfilt(R,mmax,kk,fs)

c=343;
k=ceil(kk/2);
w=2*pi*(1:k)'*(fs/(2*k));
% w=2*pi*(1:k)'*(fs/(2*k));
% tmp=0;
out=zeros(k,mmax+1);
out(:,1)=ones(k,1);
for m=1:mmax
    tmp=ones(k,1);
    for n=1:m
        tmp=tmp+factorial(m+n)/(factorial(m-n)*factorial(n))*(-i*c./(2*w*R)).^n;
    end
    out(:,m+1)=tmp;
end
% 
% out = [out;conj(out(end-1:-1:2,:))];   % Fourier transform of real series.
% ht = real(ifft(out)); 
% 
% % double side spectrum
% out(1,:)=real(out(1,:));
% if mod(kk,2)
%     out=[out;conj(flipud(out(2:end,:)))];
% else
%     out=[out;real(out(end,:));conj(flipud(out(2:end,:)))];
% end
f=w/(2*pi);
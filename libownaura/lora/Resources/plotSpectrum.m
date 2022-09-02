% plotSpectrum
%
% Plot Spectrum of a signal
%example [hpl,f,yin,yinc]=plotSpectrum(in,fs,nfft,smooth,plotdb,plotlogx,plotstyle)

function varargout=plotSpectrum(in,fs,nfft,smooth,plotdb,plotlogx,varargin)

% arguments in:
if nargin<7,    varargin={'b-'};    end
if nargin<6,    plotlogx = 1;       end
if nargin<5,    plotdb=1;           end
if nargin<4,    smooth=0;           end
if nargin<3,    nfft=[];            end
if nargin<2
    fs=44100;warning('Default: using fs = 44100')
end


if isempty(nfft)
    nfft    = floor(size(in,1)/2)*2;%2^nextpow2(len); %finds the closest power of 2
end
yinc    = fft(in,nfft);
yinc    = yinc(1:nfft/2,:);
yin     = abs(yinc);
f       = 0:fs/nfft:fs/2-fs/nfft;

% gammatone smoothing
if smooth
    [yin,f] = gsmoothspec(f,yin,smooth);
end

if plotdb
    datapl = 20*log10(yin);
else
    datapl = yin;
end
if ~isempty(varargin)
    if plotlogx
        if nargin<7
            hpl = semilogx(f,datapl,'linewidth',1.3);
        else
            hpl = semilogx(f,datapl,'linewidth',1.3,'linestyle',lstyle,'color',colorp);
        end
%         a=get(gca,'XTick')';
%         set(gca,'Xticklabel',num2str(a,'%4.f'))
%         xlim([f(1)/1.1 f(end)*1.1])
    else
        if nargin<7
            hpl = plot(f,datapl,'linewidth',1.3);
        else
            hpl = plot(f,datapl,'linewidth',1.3,'linestyle',lstyle,'color',colorp);
        end
    end
    if plotdb
        ylabel('Attenuation [dB]')
    else
        ylabel('Attenuation [lin]')
    end
    grid on
else
    hpl=0;
end
% output [hpl,f,yin,yinc]
if nargout  , varargout = {hpl}; end
if nargout>1, varargout = {hpl,f}; end
if nargout>2, varargout = {hpl,f,yin}; end
if nargout>3, varargout = {hpl,f,yin,yinc}; end
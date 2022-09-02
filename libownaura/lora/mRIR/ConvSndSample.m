% ConvSndSample
%
% Convolve an anechoic sound sample with a multichannel room impulse
% response and write the results as a single channel wav-file.
%   fnameSnd        str     filename of the anechoic sound file
%   ymRIR           mat(time,chan) multichannel impulseresponse
%   fs              sampling freq.
%   nbits           number of bits
%   fnameOutput     str     filename of the auralized sound file
%   tail            bool    1: include the tail at the end of the auralize
%                           file (default = 1)
%   gain            num     multiply the anechoic snd file before
%                           convolution. if empty, normalized to the
%                           sndfile rms (default = [])
%   varargin        [ns ne] starting and ending sample for the anechoic
%                           file
%___________________________________
% $Revision: #3 $ 28/10/2010
%    - append '.wav' to file name if missing
%    - if wav file too long => convolve on-the-fly (without overloading matlab mem)
%___________________________________
% (c) 2009 S. Favrot, CAHR


function ConvSndSample(fnameSnd, ymRIR, fs, nbits, fnameOutput, tail, gain, ...
    logdest, varargin)

if nargin<6
    tail = 1;
end
if nargin<7
    gain = [];
end
if nargin<8
    logdest=0;
end
% append '.wav' extension to file name if needed
if ~strcmpi(fnameSnd(end-3:end),'.wav')
    fnameSnd = [fnameSnd,'.wav'];
end
if ~strcmpi(fnameOutput(end-3:end),'.wav')
    fnameOutput = [fnameOutput,'.wav'];
end

info = audioinfo(fnameSnd);
if info.NumChannels > 1, error('Anechoic sound files should be monaural'),end
if info.SampleRate~=fs, error('Sentence and impulse response should have the same sampling frequency'), end
if info.TotalSamples > 250000 % on-the-fly convolution if file too long for Matlab memory
    if isempty(gain)
        gain = 1/RMSwav(fnameSnd,[1 siz(1)]);
    end
    writelog(logdest,'.')
    wavwriteZeros([siz(1)+size(ymRIR,1)-1 size(ymRIR,2)],fs,nbits,fnameOutput)
    writelog(logdest,'\b')
    writeconv(fnameOutput,ymRIR,[],1,fnameSnd,[1 siz(1)],gain,tail,logdest)
else % for not too long snd files
    writelog(logdest,'.')
    % Read the anechoic sound file
    ysent=audioread(fnameSnd,varargin{:});
    writelog(logdest,'.')
    if isempty(gain) % normalize snd file to RMS one if gain is empty
        gain = 1/sqrt(mean(ysent.^2));
    end

    % Convolve and write one wav-file
    if tail
        yc=fftfilte(ymRIR,ysent*gain);
    else
        yc=fftfilt(ymRIR,ysent*gain);
    end
    writelog(logdest,'.')
    audiowrite(fnameOutput, yc, fs, 'BitsPerSample', nbits)
    writelog(logdest,'\b\b\b')
end





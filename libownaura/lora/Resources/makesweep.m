function [s, H] = makesweep(nfft, nrep, fs, fstart, fstop, timew, amplw, end_delay, verbose)
%function [s, InvRef] = makesweep(nfft, nrep, fs, fstart, fstop, timew, amplw, ...
%                            end_delay, verbose)
%
%Creates a logarithmic (or modified logarithmic) sweep excitation signal for
%impulse measurement purposes. Frequency domain sweep generation is used to allow
%more control on the sweep properties. As a default the time domain sweep will
%have a (nearly) constant amplitude.
%
%Using a logarithmic sweep allows the separation of distortion components - created
%for example by a loudspeaker - from the linear response of the device under test
%(DUT). If the sweep is long enough compared to the response of the DUT, the
%distortion components will manifest themselves as separate components in the end
%of the impulse response recovered by using SWEEP2IMP.
%
%The function allows modifications of the sweep rate as a function of frequency.
%With such modifications the amount of energy fed to the DUT, and thus effectively
%the signal-to-noise ratio (SNR), can be controlled as a function of frequency.
%However, the user should be aware that such processing will change the behavior
%of the distortion components. A single harmonic distortion component will no
%longer start from a single instant. Instead the start time will depend on the
%sweep rate at each frequency.
%
%Return values:
%  s = The sweep sequence.
%
%  InvRef = Inverse reference spectrum needed for recovering the impulse response
%    from the measurement results. See SWEEP2IMP.
%
%Basic parameters:
%  nfft = Number of samples in one sweep. For faster operation use a power of two.
%    Nfft must to be higher than the length of the impulse response being measured
%    in order to avoid circular wrapping of the response when averaging results of
%    several sweep repetitions.
%
%  nrep = Number of sweep repetitions. When averaging data from several repetitions
%    using SWEEP2IMP, the first sequence is by default discarded.
%
%  fs = Sampling frequency in Hz. Default: 48000.
%
%Band limited sweeps:
%  The parameters fstart and fstop allow limiting the frequency range of the sweep
%  excitation. The sweeps always start at near DC and extend to near Nyquist
%  frequency in order to avoid abrupt starting and stop phenomena. However, the
%  sweeping up until fstart and from fstop on can be made fast so that little
%  time (signal energy) is consumed at uninteresting frequencies.
%
%  These band limiting features will manifest themselves as zero phase band pass
%  filtering on the final recovered impulse response. Both highpass and lowpass
%  filters have a frequency response corresponding to a second order butterworth
%  filter. For very narrow bands and low upper limits the band limiting may cause
%  artifacts in the beginning and in the end of the recovered impulse response
%  due to periodic frequency domain processing.
%
%  fstart = -3 dB cutoff frequency of the optional highpass filter. Default:
%    10 Hz (corresponds to about -0.25 dB @ 20 Hz).
%
%  fstop = -3 dB cutoff frequency of the optional lowpass filter. Default:
%    fs/2 (off).
%
%Arbitrary sweep rate and amplitude control:
%  The parameters timew and amplw allow frequency dependent weighting of the
%  excitation signal magnitude spectrum. These weighting functions should be
%  column vectors of nfft+1 elements such that the first element corresponds to
%  DC and the last to Nyquist frequency (sorry for the weird parameter form).
%  Both weightings will be compensated when recovering the impulse response
%  with SWEEP2IMP. See also SWEEPWEIGHT.
%
%  timew = Sweep magnitude spectrum weighting that will affect the sweep rate
%    of a constant amplitude sweep.
%
%  amplw = Sweep magnitude spectrum weighting applied as amplitude control of
%    the sweep signal.
%
%The rest:
%  end_delay = Defines the fraction of zero samples in the end of a single
%    period of a sweep signal. The zeros are needed to capture the full response
%    when a single sweep is used. When averaging repeated sweeps it is best to
%    keep this parameter zero. Defaults: when nrep = 1: 0.4, otherwise: 0.
%
%  verbose = Controls plotting of additional figures for debugging purposes.
%    Value 1 can be used to investigate the effects of band limiting and user
%    defined spectral weighting.
%
%References: Müller & Massarani: "Transfer-Function Measurements with Sweeps,"
%  J. Audio Eng. Soc., Vol. 49, No. 6, Pp. 443-471, June 2001.
%
%See also: SWEEP2IMP, SWEEPWEIGHT
%
%Juha Merimaa 03.06.2003

ignore_bp_in_ref = 1;

if nargin < 2
  nrep = 1;
end
if nargin < 3 | isempty(fs)
  fs = 48000;
end
if nargin < 4 | isempty(fstart)
  fstart = 10;
end
if nargin < 5 | isempty(fstop)
  fstop = fs / 2;
end
if nargin < 6 | isempty(timew)
  timew = 0;
end
if nargin < 7 | isempty(amplw)
  amplw = 0;
end
if nargin < 8 | isempty(end_delay)
  if nrep > 1
    end_delay = 0;
  else
    end_delay = 0.4;
  end
end
if nargin < 9 | isempty(verbose)
  verbose = 0;
end

% allow some time for fluctuations before and after the actual sweep within the
% final excitation signal
fstart = max(fstart, fs / (2 * nfft));
predelay = ceil(max(fs / fstart, nfft / 200));
if predelay > nfft / 10
  predelay = ceil(nfft/10);
end
postdelay = ceil(max(fs / fstop, nfft / 200));
if postdelay > nfft / 10
  postdelay = ceil(nfft/10);
end
% the number of samples in the actual sweep
nsweep = round((1 - end_delay) * nfft) - predelay - postdelay;

% transform into seconds
sweep_sec = nsweep / fs;
predelay_sec = predelay / fs;

% from here on use a double length time window to prevent time domain artifacts
% from wrapping to the sweep signal note: this makes nfft always even!
nhalffft = nfft + 1; % up to and including Nyquist
nfft = 2 * nfft;
f = (0:nhalffft-1)' * fs / nfft;

% construct a pink magnitude spectrum
H = [fstart / f(2); sqrt(fstart ./ f(2:nhalffft))];

% frequency control options that will shape the time evolution of the sweep:
% highpass filtering
if fstart > fs / nfft
  [bhp, ahp] = butter(2, 2*fstart/fs, 'high');
  H = H .* abs(freqz(bhp, ahp, 2*pi*f/fs));
end
% lowpass filtering
if fstop < fs / 2
  [blp, alp] = butter(2, 2*fstop/fs);
  H = H .* abs(freqz(blp, alp, 2*pi*f/fs));
end
% user defined spectral weighting
if timew
  H = H .* timew(:);
end

% calculate group delay
C = sweep_sec ./ sum(H.^2);
tg = C * cumsum(H.^2);
tg = tg + predelay_sec;
if verbose
  vfig = figure;
  subplot(2, 2, 1), semilogx(f(1:nhalffft), tg);
  title('Constructed group delay');
  xlabel('Frequency / Hz');
  ylabel('Time / s');
  axis tight;
  grid on;
end
% calculate phase
ph = -2*pi*fs/nfft * cumsum(tg);
% force the phase to zero at Nyquist
ph = ph - f/f(nhalffft) .* mod(ph(nhalffft), 2*pi);
clear tg;

% optional spectral weighting controlling the amplitude of the sweep
if amplw
  H = H .* amplw(:);
end

% create double-sided spectrum
H = H .* exp(j*ph);
H(nhalffft+1:nfft) = conj(H(nhalffft-1:-1:2));

% convert to time domain
s = real(ifft(H));

if verbose > 1
  figure;
  subplot(2, 1, 1), plot(s, 'b-')
  title('The sweep signal before and after time windowing');
  xlabel('Time / samples');
  ylabel('Amplitude');
  hold on;
  subplot(2, 1, 2), semilogx(f(2:nhalffft), 20*log10(abs(H(2:nhalffft))+realmin), 'b-');
  xlabel('Frequency / Hz');
  ylabel('Magnitude / dB');
  axis tight;
  grid on;
  hold on;
end

% window the fluctuations before and after the actual sweep
w = hann(2 * predelay);
s(1:predelay) = s(1:predelay) .* w(1:predelay);
stopind = nsweep + predelay;
w = hann(2 * postdelay);
s(stopind+1:stopind+postdelay) = s(stopind+1:stopind+postdelay)...
  .* w(postdelay+1:2*postdelay);
s(stopind+postdelay+1:nfft) = 0;

if verbose > 1
  subplot(2, 1, 1), plot(s, 'r-')
  hold off;
  temp = fft(s);
  temp = temp(1:nhalffft);
  subplot(2, 1, 2), semilogx(f, 20*log10(abs(temp)), 'r-');
  clear temp
  hold off;
end

% back to the user defined nfft
nfft = nfft / 2;
s = s(1:nfft);

% normalize the amplitude and create the repetions
normfact = 1.02 * max(abs(s));
s = s ./ normfact;
if nrep > 1
  s2 = s;
  for k=2:nrep
    s2 = [s2; s];
  end
  s = s2;
  clear s2;
end

H = 1 ./ fft(s(1:nfft));
f = (0:nfft-1)' * fs / nfft;
% calculate a new reference spectrum without the bandpass filtering
% (in order not to amplify noise by the inverse of the sweep energy far
% outside the sweep band)
if ignore_bp_in_ref
  if fstart > fs / nfft
    H = H .* abs(freqz(bhp, ahp, 2*pi*f/fs));
  end
  if fstop < fs / 2
    H = H .* abs(freqz(blp, alp, 2*pi*f/fs));
  end
end

if verbose
  figure(vfig);
  subplot(2, 2, 2), plot(s(1:nfft));
  title('Sweep signal, single repetition');
  xlabel('Time / samples');
  ylabel('Amplitude');
  
  temp = fft(s(1:nfft)) .* H;
  subplot(2, 2, 4), semilogx(f, 20*log10(abs(temp)+realmin));
  title('Magnitude spectrum of the recovered impulse response');
  xlabel('Frequency / Hz');
  ylabel('Magnitude / dB');
  axis tight;
  a = axis;
  a(2) = fs / 2;
  a(3) = max(a(3), -60);
  axis(a);
  grid on;
  
  temp = real(ifft(temp));
  subplot(2, 2, 3), plot(-20:20, temp([nfft-19:nfft 1:21]));
  title('Recovered impulse response');
  xlabel('Time / samples');
  ylabel('Amplitude');
end


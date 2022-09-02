function impresp = sweep2imp(s, InvRef, nrep);
%function impresp = sweep2imp(s, InvRef, nrep)
%
%Recover an impulse response from a sweep excitation measurement.
%
%Parameters:
%  s = Response to the sweep signal.
%
%  InvRef = Inverse reference spectrum, given by MAKESWEEP.
%
%  nrep = Number of repetitions in the sweep excitation.
%
%See also: MAKESWEEP
%
%Juha Merimaa 03.06.2003

if nrep > 1;
  nfft = length(InvRef);
  s2 = 1 / (nrep - 1) * s(nfft+1:2*nfft);
  for k=2:nrep-1;
    s2 = s2 + 1 / (nrep-1) * s(k*nfft+1:(k+1)*nfft);
  end
  s = s2;
end
  
impresp = real(ifft(fft(s) .* InvRef));

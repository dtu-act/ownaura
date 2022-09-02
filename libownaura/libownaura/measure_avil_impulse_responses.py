# %%

import warnings
import argparse
import pathlib
from datetime import datetime

import sounddevice as sd
import numpy as np
import matplotlib.pyplot as plt
from response import Response
from scipy.signal.windows import hann
from tqdm import tqdm

def warn_on_streaming_error():
    status = sd.get_status()
    if status.input_underflow:
        warnings.warn('Input underflow')
    if status.input_overflow:
        warnings.warn('Input overflow')
    if status.output_overflow:
        warnings.warn('output overflow')
    if status.output_underflow:
        warnings.warn('output underflow')
    if status.priming_output:
        warnings.warn('Primed output')


def transfer_function(
    ref,
    meas,
    ret_time=True,
    axis=-1,
    reg=0,
    reg_lim_dB=None,
):
    """Compute transfer-function between time domain signals.

    Parameters
    ----------
    ref : ndarray, float
        Reference signal.
    meas : ndarray, float
        Measured signal.
    ret_time : bool, optional
        If True, return in time domain. Otherwise return in frequency domain.
    axis : integer, optional
        Time axis
    reg : float
        Regularization in deconvolution
    reg_lim_dB: float
        Regularize such that reference has at least reg_lim_dB below of maximum energy
        in each bin. Overwrites `reg` option.

    Returns
    -------
    h : ndarray, float
        Transfer-function between ref and meas.

    """
    R = np.fft.rfft(ref, axis=axis)
    Y = np.fft.rfft(meas, axis=axis)

    R[R == 0] = np.finfo(complex).eps  # avoid devision by zero

    # Avoid large TF gains that lead to Fourier Transform numerical errors
    TOO_LARGE_GAIN = 1e9
    too_large = np.abs(Y / R) > TOO_LARGE_GAIN
    if np.any(too_large):
        warnings.warn(
            f"TF gains larger than {20*np.log10(TOO_LARGE_GAIN):.0f} dB. Setting to 0"
        )
        Y[too_large] = 0

    if reg_lim_dB is not None:
        # maximum of reference
        maxRdB = np.max(20 * np.log10(np.abs(R)), axis=axis)

        # power in reference should be at least
        minRdB = maxRdB - reg_lim_dB

        # 10 * log10(reg + |R|**2) = minRdB
        reg = 10 ** (minRdB / 10) - np.abs(R) ** 2
        reg[reg < 0] = 0

    H = Y * R.conj() / (np.abs(R) ** 2 + reg)

    if ret_time:
        h = np.fft.irfft(H, axis=axis, n=ref.shape[axis])
        return h
    else:
        return H


def measure_single_impulse_response(
    sound,
    fs,
    out_ch=1,
    in_ch=1,
    reg_lim_dB=None,
    **sd_kwargs,
):
    """Measure impulse response between single output and multiple inputs.

    Parameters
    ----------
    sound : ndarray, shape (nt,)
        Excitation signal
    fs : int
        Sampling rate of sound
    out_ch : int or list, optional
        Output channels
    in_ch : int or list of length nin, optional
        Input channels

    Returns
    -------
    ndarray, shape (nin, nt)
        Impulse response between output channel and input channels

    """
    out_ch = np.atleast_1d(out_ch)
    in_ch = np.atleast_1d(in_ch)

    rec = sd.playrec(
        sound,
        samplerate=fs,
        input_mapping=in_ch.copy(),     # make copies of mapping because of
        output_mapping=out_ch.copy(),   # github.com/spatialaudio/python-sounddevice/issues/135
        blocking=True,
        **sd_kwargs,
    )
    warn_on_streaming_error()

    return transfer_function(sound[:, None], rec, axis=0, reg_lim_dB=reg_lim_dB).T


def exponential_sweep(
    T, fs, tfade=0.05, f_start=None, f_end=None, maxamp=1, post_silence=0
):
    """Generate exponential sweep.

    Sweep constructed in time domain as described by `Farina`_ plus windowing.

    Parameters
    ----------
    T : float
        length of sweep
    fs : int
        sampling frequency
    tfade : float
        Fade in and out time with Hann window.
    post_silence : float
        Added zeros in seconds.

    Returns
    -------
    ndarray, floats, shape (round(T*fs),)
        An exponential sweep

    .. _Farina:
       A. Farina, “Simultaneous measurement of impulse response and distortion
       with a swept-sine techniqueMinnaar, Pauli,” in Proc. AES 108th conv,
       Paris, France, 2000, pp. 1–15.

    """
    n_tap = int(np.round(T * fs))

    # start and stop frequencies
    if f_start is None:
        f_start = fs / n_tap
    if f_end is None:
        f_end = fs / 2

    assert f_start < f_end
    assert f_end <= fs / 2

    w_start = 2 * np.pi * f_start
    w_end = 2 * np.pi * f_end

    # constuct sweep
    t = np.linspace(0, T, n_tap, endpoint=False)
    sweep = np.sin(
        w_start
        * T
        / np.log(w_end / w_start)
        * (np.exp(t / T * np.log(w_end / w_start)) - 1)
    )
    sweep = sweep * maxamp  # some buffer in amplitude

    if tfade:
        n_fade = round(tfade * fs)
        fading_window = hann(2 * n_fade)
        sweep[:n_fade] = sweep[:n_fade] * fading_window[:n_fade]
        sweep[-n_fade:] = sweep[-n_fade:] * fading_window[-n_fade:]

    if post_silence > 0:
        silence = np.zeros(int(round(post_silence * fs)))
        sweep = np.concatenate((sweep, silence))

    return sweep


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Measure loudspeaker responses',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument('-o', '--output', help='output file name or path', default='h_avil_' + datetime.now().isoformat(timespec='seconds').replace(':', '-'), type=pathlib.Path)
    parser.add_argument('-t', '--sweep-time', help='length of exponential sweep in seconds', default=1, type=int)
    parser.add_argument('-n', '--nrepetitions', help='average impulse response over n repetitions', default=3, type=int)
    parser.add_argument('-p', '--post-silence', help='record X seconds longer to capture complete response', default=0.3, type=float)
    parser.add_argument('-m', '--max-amp', help='max amplitude of excitation signal', default=0.03, type=float)
    parser.add_argument('-i', '--input-channel', help='index of input channel', default=7, type=int)
    parser.add_argument('-N', '--nout', help='number of loudspeakers to measure', default=64, type=int)
    parser.add_argument('-d', '--debug', help='turn on plotting', default=False, action='store_true')

    args = parser.parse_args()

    # device setup
    fs = 48000
    sd.default.device = 'RedNet PCIe'
    sd.default.samplerate = fs
    sd.default.latency = ('low', 'low')
    out_chs = np.arange(1, args.nout + 1)

    # compute sweep signal
    x = exponential_sweep(args.sweep_time, fs, post_silence=args.post_silence, tfade=0) * args.max_amp;

    # measure every loudspeaker
    h = []
    for out_ch in tqdm(out_chs, desc='Loudspeaker', leave=False):
        # average over repetitions
        h_avg = 0
        for i in range(args.nrepetitions):
            h_avg += measure_single_impulse_response(x, fs, out_ch=out_ch, in_ch=args.input_channel)[0] / args.nrepetitions
        h.append(h_avg)
    h = np.stack(h)

    # save
    np.savez(str(args.output), h=h, fs=fs, x=x)
    print(f'Created {str(args.output)}')

    if args.debug:
        Response.from_time(fs, h).plot(dblim=(-40, 0), flim=(80, 20000))
        plt.show()


# %%

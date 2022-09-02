"""Compute compensation filter C

    $$\frac{H_D}{H_R} =  \frac{H_\text{step 2}}{C H_{AVIL}^T W_{ref}}$$

which is equivalent to

    $$C = \frac{H_R}{H_D} \frac{H_\text{step 2}}{H_{AVIL}^T W_{ref}}$$

"""

import os
import argparse
from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import scipy
import scipy.signal
import soundfile as sf

import libownaura.utils as utils

import response
from response import Response

# final filter parameters
fs = 48000
OWNAURA_PATH = Path(os.path.realpath(__file__)).parent.parent.parent
DEBUG = False

def wiener_filter(x, y, n, reg=0, constrained=False):
    """Compute optimal wiener filter.

    From Elliot, Signal Processing for Optimal Control, Eq. 3.3.26

    Parameters
    ----------
    x : array_like
        Reference signal.
    y : array_like
        Disturbance signal.
    n : int
        Output filter length.
    g : None or array_like, optional
        Secondary path impulse response.
    constrained : bool, optional
        If True, constrain filter to be causal.

    Returns
    -------
    numpy.ndarray, shape (n,)
        Optimal wiener filter in freqency domain.

    """
    # NOTE: one could time align the responses here first
    f, Sxy = scipy.signal.csd(x, y, fs=fs, nperseg=n, return_onesided=False)
    _, Sxx = scipy.signal.welch(x, fs=fs, nperseg=n, return_onesided=False)

    Sxx += reg

    if DEBUG:
        nplot = n // 2  # plot only positive freqs
        _, ax = plt.subplots()
        ax.loglog(f[:nplot], Sxx[:nplot] - reg, 'b', label="Sxx")
        ax.loglog(f[:nplot], reg * np.ones(nplot), 'k--', label="reg")
        ax.loglog(f[:nplot], reg + Sxx[:nplot] , 'b--', label="Sxx + reg")

        plt.loglog(f[:nplot], np.abs(Sxy[:nplot]), 'r', label="Sxy")
        plt.title("$H_{step2}$: Cross and Auto Power spectral densities")
        plt.legend()

    if not constrained:
        return np.real(np.fft.ifft(Sxy / Sxx))

    c = np.ones(n)
    c[n // 2 :] = 0
    # half at DC and Nyquist
    c[0] = 0.5
    if n % 2 == 0:
        c[n // 2] = 0.5

    # spectral factor
    F = np.exp(np.fft.fft(c * np.fft.ifft(np.log(Sxx), n=n), n=n))

    h = np.ones(n)
    h[n // 2 :] = 0
    return np.real(np.fft.ifft(np.fft.fft(h * np.fft.ifft(Sxy / F.conj()), n=n) / F))


def generate_bands_for_firls(bands, gains):
    bands_pairs = [
        bands[i : i + 2] for i in range(0, len(bands)) if len(bands[i : i + 2]) == 2
    ]
    bands_corners = [np.sqrt(b[0] * b[1]) for b in bands_pairs]
    bands_corners = np.concatenate(([0], np.repeat(bands_corners, 2), [fs / 2]))
    gains_corners = np.interp(bands_corners, bands, gains)
    return bands_corners, gains_corners


def compute_H_R_H_D(odeon_early_reflections_file):
    """Compute impulse response that represents the target ratio of reflected
    (H_R) to direct (H_D) sound in the Odeon simulation.

    The Odeon file only gives sound pressure levels in octave bands and arrival
    times. From these quantities, we generate a
    """
    # Load impulse responses from similation: Hr and Hd
    df = pd.read_csv(
        odeon_early_reflections_file, header=3, delimiter="\t", decimal=","
    )

    bands = [63, 125, 250, 500, 1000, 2000, 4000, 8000]

    direct_spl = df.iloc[0, 3:11].to_numpy(dtype=np.float)
    reflec_spl = df.iloc[1, 3:11].to_numpy(dtype=np.float)
    target_delay = df.iloc[1, 2] / 1000
    gain_dB = reflec_spl - direct_spl
    gains = 10 ** (gain_dB / 20)

    # FIR filter with right magnitude response
    number_samples = int(target_delay * fs) * 2 - 1
    gains_in_octave_bands = generate_bands_for_firls(bands, gains)
    h_linear = scipy.signal.firls(number_samples, *gains_in_octave_bands, fs=fs)
    # FIR filter with also right delay
    target_dirac = (
        Response.new_dirac(fs, n=number_samples)
        .delay(target_delay)
        .in_time
    )
    h_r_h_d = response.align(h_linear, target_dirac)

    if False:
        print(df)
        fig = Response.from_time(fs, h_r_h_d).plot_magnitude(label="H_R_H_D")
        fig.gca().semilogx(bands, gain_dB, label="Odeon")
        plt.title("Comparison of $H_R/H_D$ to Odeon reflection in magnitude")
        plt.legend()

        fig = Response.from_time(fs, h_r_h_d).plot_time(tlim=(0, 0.03))
        plt.vlines(target_delay, 0, 0.25, color="orange")
        plt.title("Comparison of $H_R/H_D$ to Odeon reflection in time")
        plt.show()

    return h_r_h_d


def load_H_avil(h_avil_file):
    with np.load(h_avil_file) as data:
        assert data["fs"] == fs
        h = data["h"]

    if False:
        Response.from_time(fs, h).plot(tlim=(0, 0.1), dblim=(-40, 0))
        plt.suptitle("Avil transfer functions $H_{avil}$")
        plt.show()

    return h


def load_W_ref(lora_w_file):
    w_ref, fs_irfile = sf.read(lora_w_file)
    assert fs_irfile == fs
    w_ref = w_ref.T

    if False:
        Response.from_time(fs, w_ref).plot(tlim=(0, 0.1))
        plt.suptitle("Lora filters $W_{ref}$")
        plt.show()

    return w_ref


def compute_H_direct_avil(h_direct_avil_recording_file, reg, window_length=1024, headset_ch=1, measmic_ch=0, constrained=True):
    # load recording
    data, fsf = sf.read(h_direct_avil_recording_file)
    assert fsf == fs
    x = data[:, headset_ch]  # headset mic
    y = data[:, measmic_ch]  # calibration mic

    if False:
        nperseg = 2048
        h = wiener_filter(x, y, nperseg, reg=reg, constrained=constrained)
        fig = Response.from_time(fs, h).plot(label=f"nperseg = {nperseg}")
        nperseg = 1024
        h = wiener_filter(x, y, nperseg, reg=reg, constrained=constrained)
        fig = Response.from_time(fs, h).plot(use_fig=fig, label=f"nperseg = {nperseg}")
        nperseg = 512
        h = wiener_filter(x, y, nperseg, reg=reg, constrained=constrained)
        fig = Response.from_time(fs, h).plot(use_fig=fig, label=f"nperseg = {nperseg}")
        nperseg = window_length
        h = wiener_filter(x, y, nperseg, reg=reg, constrained=constrained)
        fig = Response.from_time(fs, h).plot(use_fig=fig, label=f"nperseg = {nperseg} CHOSEN")
        plt.suptitle("$H_{step2}$: check that long filter does not have more energy.")

    nperseg = window_length
    h = wiener_filter(x, y, nperseg, reg=reg, constrained=constrained)

    # process response
    r = Response.from_time(fs, h)

    if DEBUG:
        _, ax = plt.subplots()
        f, Cxy = utils.coherence_csd(x, y, fs, nperseg=4096 * 8)
        ax.semilogx(f, Cxy)
        plt.title("$H_{step2}$: Coherence Cxy between measurement and headset mics\nshould be close to 1 in speech range")

        plt.show()

    return r.in_time


def compute_compensation_filter(h_R_h_D, h_direct_avil, h_avil, w_ref, M, reg):
    """Compute two things: a minimum phase filter that compensates for gain, and a delay that compensates time shifts."""
    N = 64
    assert h_avil.shape[0] == w_ref.shape[0] == N, f"need {64} channels in avil"

    ## gain

    # what comes out of avil
    h_current = np.zeros(h_avil.shape[1] + w_ref.shape[1] - 1)
    for i in range(N):
        h_current += np.convolve(h_avil[i], w_ref[i])

    # what we want
    h_target = np.convolve(h_R_h_D, h_direct_avil)

    # calibration_gain = H_target / H_current
    nsamples = max(len(h_target), len(h_current))
    calibration_gain = np.abs(np.fft.rfft(h_target, n=nsamples)) /(np.abs(np.fft.rfft(h_current, n=nsamples)) + reg)

    # average calibration_gain over bands in log scale
    band_center_freqs = [32, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]  # include 32 and 16000 only to get start_end_freqs
    band_startend_freqs = [
        np.sqrt(b[0] * b[1])
        for b in [
            band_center_freqs[i : i + 2] for i in range(0, len(band_center_freqs)) if len(band_center_freqs[i : i + 2]) == 2
        ]
    ]
    mean_of_calibration_gain_over_bands = 10**(np.array(
        [
            np.mean(10 * np.log10(gains))
            for gains in np.split(
                calibration_gain,
                [
                    utils.find_nearest(Response.freq_vector(nsamples, fs), b)[1]
                    for b in band_startend_freqs
                ],
            )
        ]
    ) / 10)

    # we are only interested in bands 63 to 8000 so just set first and last to f=0 and f=fs/2 for firwin2
    band_center_freqs[0] = 0
    band_center_freqs[-1] = fs / 2

    if DEBUG:
        plt.figure()
        plt.title('Comparison of minimum_phase filter gain to target gain')
        plt.semilogx(Response.freq_vector(nsamples, fs), 10*np.log10(calibration_gain), label="target calibration gain")
        plt.semilogx(band_center_freqs, 10*np.log10(mean_of_calibration_gain_over_bands), label="target calibration gain in octave bands")

    # design linear phase filter with calibration_gain as magnitude
    for Mc in [32, 128, 512, 1024]:
        Mc -= 1
        h_linear_phase = scipy.signal.firwin2(Mc, band_center_freqs, mean_of_calibration_gain_over_bands, fs=fs)
        h_minimum_phase_square_root_mag = scipy.signal.minimum_phase(h_linear_phase)
        h_minimum_phase = np.convolve(h_minimum_phase_square_root_mag, h_minimum_phase_square_root_mag)

        if DEBUG:
            plt.plot(
                Response.freq_vector(Mc, fs),
                10*np.log10(np.abs(np.fft.rfft(h_minimum_phase))),
                label=f"minimum phase, M = {Mc}",
            )

    h_linear_phase = scipy.signal.firwin2(M, band_center_freqs, mean_of_calibration_gain_over_bands, fs=fs)
    h_minimum_phase_square_root_mag = scipy.signal.minimum_phase(h_linear_phase)
    h_minimum_phase = np.convolve(h_minimum_phase_square_root_mag, h_minimum_phase_square_root_mag)

    if DEBUG:
        plt.plot(
            Response.freq_vector(M, fs),
            10*np.log10(np.abs(np.fft.rfft(h_minimum_phase))),
            'k',
            label=f"minimum phase, M = {M} CHOSEN",
        )

        plt.legend()
        plt.grid(True)
        plt.xlabel('Frequency [Hz]')
        plt.ylabel('Magnitude [dB]')

    if DEBUG:
        fig = Response.from_time(fs, h_linear_phase).plot(label='linear phase')
        Response.from_time(fs, h_minimum_phase).plot(use_fig=fig, label='minimum phase')
        plt.suptitle('linear- and minimum-phase filters')
        plt.show()


    ## delay shift
    # pad to same length before comparing
    if len(h_current > len(h_target)):
        h_target = np.pad(h_target, (0, len(h_current) - len(h_target)))
    elif len(h_current < len(h_target)):
        h_current = np.pad(h_current, (0, len(h_target) - len(h_current)))
    delay_samples = response.delay_between(h_target, h_current)

    print(f"Calibration will cut {delay_samples} samples / {delay_samples / fs * 1000:.2f} ms.")

    return h_minimum_phase, delay_samples


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Compute calibration filter",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        "calibration_recording",
        help='recording of headset and measurement microphone, e.g. "calibration_recording.aif"',
    )
    parser.add_argument("-o", "--output", help='output file path', type=Path, default="calibration_file")
    parser.add_argument("--measmic-ch", help='channel index of measurement microphone in recoding', default=0, type=int)
    parser.add_argument("--headset-ch", help='channel index of headset microphone in recoding', default=1, type=int)
    parser.add_argument(
        "--filter-length", help="set length (N) of minimum_phase filter. Must be odd.", default=511, type=int
    )
    parser.add_argument(
        "--debug", action="store_true", help="turn on debug plotting", default=False
    )
    parser.add_argument(
        "--reg_C", help="set regularization parameter (epsilon) in gain estimation of calibration filter (C)", default=1e-10, type=float
    )
    parser.add_argument(
        "--reg_H_direct_avil", help="set regularization parameter in estimation of H_{direct, avil}", default=1e-14, type=float
    )
    parser.add_argument(
        "--window_length", help="set window length (M) in estimation of H_{direct, avil} via Welch's method", default=512, type=int
    )
    parser.add_argument(
        "--h_avil_file",
        help="file path to AVIL impulse responses",
        type=Path,
        default=OWNAURA_PATH / "h_avil_2022-01-20T15-57-38.npz"
    )
    parser.add_argument(
        "--lora_ir_reference_file",
        help="path to impulse response from lora for reference room",
        type=Path,
        default=OWNAURA_PATH / "Lora filters/Calibration room.wav"
    )
    parser.add_argument(
        "--early_reflections_file",
        help="path to early reflections from Odeon for reference room",
        type=Path,
        default=OWNAURA_PATH / "Odeon rooms/Calibration room/AVIL implementation files/10_10_10m_sketchupbase.Job01.00001EarlyReflections.Txt"
    )

    args = parser.parse_args()
    DEBUG = args.debug

    print(f'Using h_avil_file {args.h_avil_file}')
    print(f'Using early_reflections_file {args.early_reflections_file}')
    print(f'Using lora_ir_reference_file {args.lora_ir_reference_file}')

    # compute or load
    print("Computing target response H_R / H_D")
    h_R_h_D = compute_H_R_H_D(str(args.early_reflections_file))

    print("Computing avil response H_refl_avil")
    h_avil = load_H_avil(str(args.h_avil_file))

    print("Computing odeon reference filter")
    w_ref = load_W_ref(str(args.lora_ir_reference_file))

    print("Computing h_direct_avil")
    h_direct_avil = compute_H_direct_avil(args.calibration_recording, reg=args.reg_H_direct_avil, window_length=args.window_length, headset_ch=args.headset_ch, measmic_ch=args.measmic_ch)

    print("Computing calibration filter")
    h, n = compute_compensation_filter(h_R_h_D, h_direct_avil, h_avil, w_ref, args.filter_length, reg=args.reg_C)

    np.savez(args.output, h=h, n=n, fs=fs, docs="h: impulse response, n: samples to cut at beginning, fs: samplerate")
    print(f"Created {args.output.resolve()}.npz")
# %%
import argparse
from pathlib import Path

from matplotlib import pyplot as plt
import numpy as np
import matplotlib.pyplot as plt
import soundfile as sf

from response import Response
from libownaura.compute_calibration_filter import compute_H_direct_avil
from scipy.signal import flattop, lfilter

DEBUG = True

measmic_channel_calibration_recording = 1
headset_channel_calibration_recording = 2

measmic_channel_convolver_recording = 0
headset_channel_convolver_recording = 1


def amplitude_spectrum(x, axis=-1, norm=True):
    """Convert time domain signal to single sided amplitude spectrum.
    Parameters
    ----------
    x : ndarray
        Real signal, which can be multidimensional (see axis).
    axis : int, optional
        Transformation is done along this axis. Default is -1 (last axis).
    norm: bool, optinal
        If True, normalize the response in frequency domain such that the
        amplitude of sinusoids is conserved.
    Returns
    -------
    ndarray
        Frequency response X with `X.shape[axis] == x.shape[axis] // 2 + 1`.
        The single sided spectrum.
    Notes
    -----
    Frequency spectrum is normalized for conservation of ampltiude.
    If len(x[axis]) is even, x[-1] contains the term representing both positive
    and negative Nyquist frequency (+fs/2 and -fs/2), and must also be purely
    real. If len(x[axis]) is odd, there is no term at fs/2; x[-1] contains the
    largest positive frequency (fs/2*(n-1)/n), and is complex in the general
    case.
    """
    # move time axis to front
    x = np.moveaxis(x, axis, 0)

    n = x.shape[0]

    X = np.fft.rfft(x, axis=0)

    if norm:
        X /= n

    # sum complex and real part
    if n % 2 == 0:
        # zero and nyquist element only appear once in complex spectrum
        X[1:-1] *= 2
    else:
        # there is no nyquist element
        X[1:] *= 2

    # and back again
    X = np.moveaxis(X, 0, axis)

    return X

def calibrator_gain_from_calibrator_recording(fname):
    """Read a calibrator recording and compute calibration gain for signals from that channel."""
    # nominal calibrator pressure
    L = 94
    pref = 20e-6
    calibration_pressure = 10 ** (L / 20) * pref * np.sqrt(2)

    # read calibrator recording
    rec, fs = sf.read(fname)
    rec = rec[:, measmic_channel_calibration_recording]
    N = rec.shape[0]
    freqs = np.linspace(0, fs/2, N // 2 + 1)

    # window with flattop and compute amplitude spectrum
    window = flattop(N)
    gain_window = window.mean()
    rec_windowed = rec * window / gain_window
    A = amplitude_spectrum(rec_windowed)

    # uncalibrated amplitude
    pressure_measured = np.abs(A).max()

    # this gain applied to uncalibrated signal calibrates it into sound pressure
    calibrator_gain = calibration_pressure / pressure_measured

    if DEBUG:
        print("calibration gain:", calibrator_gain)
        plt.figure()
        plt.plot(freqs, 20*np.log10(np.abs(A/np.sqrt(2)/pref)), label='Uncalibrated')
        plt.plot(freqs, 20*np.log10(np.abs(A * calibrator_gain/np.sqrt(2)/pref)), label='Calibrated')
        plt.hlines(L, 0, fs / 2, label='94dB')
        plt.legend()
        plt.xlim(950, 1050)
        plt.ylim(90,96)
        plt.grid(True)

        plt.figure()
        plt.plot(rec * calibrator_gain, label="calibrator signal after calibration")
        plt.plot(rec, label="calibrator signal before calibration")
        plt.legend()
        plt.show()

    return calibrator_gain


def headset_to_sound_pressure(x, calibrator_gain, ir_headset_measmic):
    """Estimate sound pressure level at measmic from headset recording."""
    x *= calibrator_gain
    x = lfilter(ir_headset_measmic, 1, x)
    return x


# %%
def test():
    calibrator_recording = "M:\\OwnAura\\Data\\measurement_microphone_SPLcalibration_recording.wav"
    headset_mic_calibration_recording = "M:\\OwnAura\\20211103_Pilot1\\recordings\\calibration_recording.aif"

    calibrator_gain = calibrator_gain_from_calibrator_recording(calibrator_recording)
    ir_headset_measmic = compute_H_direct_avil(headset_mic_calibration_recording, reg=10e-14, constrained=True, window_length=1024)

    Response.from_time(48000, ir_headset_measmic).plot()

    x, fs = sf.read(headset_mic_calibration_recording)
    headsetrec = x[:, headset_channel_calibration_recording]
    measmicrec = x[:, measmic_channel_calibration_recording]

    headset_sp = headset_to_sound_pressure(headsetrec, calibrator_gain, ir_headset_measmic)
    measmic_sp = measmicrec * calibrator_gain

    plt.figure()
    plt.plot(headset_sp[3000:4000], label="headset")
    plt.plot(measmic_sp[3000:4000], label="measmic")
    plt.legend()

# test()

# %%

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Convert headset recording to calibrated sound pressure at 1m",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        "measmic_calibrator_recording",
        help='recording of the calibrator signal at the measurement microphone',
    )
    parser.add_argument(
        "headset_measmic_calibration_recording",
        help='recording of headset and measurement microphone, e.g. "calibration_recording.aif"',
    )
    parser.add_argument(
        "files", nargs='+', help='files to convert'
    )
    parser.add_argument(
        "--debug", action="store_true", help="turn on debug plotting", default=False
    )

    args = parser.parse_args()
    DEBUG = args.debug

    if Path(args.measmic_calibrator_recording).suffix != ".aif":
            raise ValueError("Use original aif file!")

    print("Computing calibration gains and filters")
    calibrator_gain = calibrator_gain_from_calibrator_recording(args.measmic_calibrator_recording)
    ir_headset_measmic = compute_H_direct_avil(args.headset_measmic_calibration_recording, reg=10e-14, constrained=True, window_length=1024)

    for f in args.files:
        print("Processing ", f, "...")
        x, fs = sf.read(f)
        assert x.shape[1] == 2, "Can only calibrate 2channel recordings made with the convolver patch"

        if DEBUG:
            plt.figure()
            plt.title("file to be compesanted")
            plt.plot(x[:, measmic_channel_convolver_recording] * calibrator_gain, label="calibrator signal after calibration")
            plt.plot(x[:, measmic_channel_convolver_recording], label="calibrator signal before calibration")
            plt.legend()
            plt.show()

        x[:, headset_channel_convolver_recording] = headset_to_sound_pressure(x[:, headset_channel_convolver_recording], calibrator_gain, ir_headset_measmic)
        x[:, measmic_channel_convolver_recording] *= calibrator_gain

        newfilename = str(Path(f).with_suffix("")) + "_sound pressure at 1m.wav"
        sf.write(newfilename, x, fs, format="WAV", subtype="FLOAT")

        xn, fs = sf.read(newfilename)
        print(10*np.log10(np.sum(xn[:, measmic_channel_convolver_recording]**2)/len(xn[:, measmic_channel_convolver_recording])/(20e-6)**2))
        print("saved ", newfilename)
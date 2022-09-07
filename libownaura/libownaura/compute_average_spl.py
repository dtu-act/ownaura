# %%
import argparse
import numpy as np
import matplotlib.pyplot as plt
import scipy.signal as sig
import soundfile as sf
from response import Response, _third_octave_bands

from libownaura.recordings_to_sound_pressure import measmic_channel_convolver_recording, headset_channel_convolver_recording


def power_in_bands(x, fs, bands=None, nperseg=1024):
    """Compute power of signal in frequency bands.

    Power(band) =   1/T  integral  |X(f)| ** 2 df
                        f in band

    Parameters
    ----------
    bands : list of tuples, optional
        nbands Center, lower and upper frequencies of bands.
    avgaxis: int, tuple or None
        Average result over these axis

    Returns
    -------
    P: ndarray, shape (..., len(bands))
        Power in bands
    fcs: list, length len(bands)
        Center frequencies of bands

    """
    if bands is None:
        bands = _third_octave_bands

    # center frequencies
    fc = np.asarray([b[0] for b in bands])
    f, Pxx = sig.welch(x, fs=fs, scaling="spectrum")

    P = np.zeros(len(bands))
    for i, (_, fl, fu) in enumerate(bands):
        if fu <= fs / 2:  # include only bands in frequency range
            iband = np.logical_and(fl <= f, f < fu)
            bandwidth = fu - fl
            P[i] = np.sum(Pxx[..., iband]) # / bandwidth

    return P, fc


def plot_power_in_bands(
        P, fc, bands=None, use_ax=None, barkwargs={}, dbref=1, **figkwargs
    ):
        """Plot signal's power in bands.

        Parameters
        ----------
        bands : list or None
            List of tuples (f_center, f_lower, f_upper)
        use_ax : matplotlib.axis.Axis or None, optional
            Plot into this axis.
        barkwargs : dict
            Keyword arguments to `axis.bar`
        dbref : float
            dB reference.
        **figkwargs
            Keyword arguments passed to plt.subplots

        Returns
        -------
        P : ndarray
            Power in bands
        fc : ndarray
            Band frequencies
        fig : matplotlib.figure.Figure
            Figure

        """
        nbands = len(P)

        if use_ax is None:
            fig, ax = plt.subplots(**figkwargs)
        else:
            ax = use_ax
            fig = ax.get_figure()

        xticks = range(1, nbands + 1)
        ax.bar(xticks, 10 * np.log10(P / dbref ** 2), **barkwargs)
        ax.set_xticks(xticks)
        ax.set_xticklabels(["{:.0f}".format(f) for f in fc], rotation="vertical")
        ax.grid(True)
        ax.set_xlabel("Band's center frequencies [Hz]")
        ax.set_ylabel("Energy [dB]")

        return (P, fc, fig)


def average_sound_pressure_level(x):
    """Compute average sound pressure level of pressure signal."""
    pref=20e-6
    average_energy = np.sum(np.abs(x)**2) / len(x)
    return 10*np.log10(average_energy/pref**2)
    

def test_average_sound_pressure_level():
    fs = 48000
    T = 10
    t = np.linspace(0, T, fs*T, endpoint=False)
    noise = np.random.normal(scale=1, size=len(t))
    signal = np.sin(1000*2*np.pi*t) * 1.4175715661678836
    assert np.allclose(average_sound_pressure_level(signal), 94)

test_average_sound_pressure_level()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Compute average sound pressure level",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        "file",
        help='recordings of calibrated headset and measurement microphone', nargs='+'
    )
    parser.add_argument(
        "--debug", action="store_true", help="turn on debug plotting", default=False
    )
    
    args = parser.parse_args()
    DEBUG = args.debug

    for f in args.file:
        x, fs = sf.read(f)
        if DEBUG:
            print(x.shape)
            plt.figure()
            plt.plot(x[:, measmic_channel_convolver_recording], label="measmic")
            plt.legend()
            plt.figure()
            plt.plot(x[:, headset_channel_convolver_recording], label="headset")
            plt.legend()
            plt.show()
        print(f)
        print("headset:\t", average_sound_pressure_level(x[:, headset_channel_convolver_recording]))
        print("measmic:\t", average_sound_pressure_level(x[:, measmic_channel_convolver_recording]))


# This here is not needed and also not clear if correct
# # %% 
# n, fc = power_in_bands(noise, fs)
# s, _ = power_in_bands(signal, fs)
# ns, _ = power_in_bands(noise+signal, fs)

# plt.plot(fc, 10*np.log10(s))
# plt.plot(fc, 10*np.log10(n))
# plt.plot(fc, 10*np.log10(ns-n))
# plt.legend(["signal", "noise", "noisysig - noise"])

# _, _, fig = plot_power_in_bands(n, fc)
# plot_power_in_bands(s, fc, use_ax=fig.gca())
# plot_power_in_bands(ns-n, fc, use_ax=fig.gca())
# plt.legend(["signal", "noise", "noisysig - noise"])



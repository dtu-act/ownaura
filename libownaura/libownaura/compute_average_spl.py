"""Compute the average sound pressure level of voiced parts of a recording."""

import argparse

import numpy as np
import matplotlib.pyplot as plt
import soundfile as sf
import librosa
import librosa.feature

from libownaura.recordings_to_sound_pressure import (
    measmic_channel_convolver_recording, headset_channel_convolver_recording)


def average_sound_pressure_level(x):
    """Compute average sound pressure level of pressure signal."""
    pref=20e-6
    average_energy = np.sum(np.abs(x)**2) / len(x)
    return 10*np.log10(average_energy/pref**2)


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



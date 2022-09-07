"""Compute the average sound pressure level of voiced parts of a recording."""

import sys
import argparse
from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt
import soundfile as sf
import librosa
import librosa.feature
import librosa.display

from tabulate import tabulate
from libownaura.recordings_to_sound_pressure import (
    measmic_channel_convolver_recording, headset_channel_convolver_recording)


def avg_spl(x: np.ndarray, noise_var=0):
    """Compute average sound pressure level of pressure signal w/o noise"""
    pref=20e-6
    return 10*np.log10((np.var(x) - noise_var)/pref**2)


def split_voice_unvoiced(y: np.ndarray, sr: int, noise_var: float, threshold=0.5):
    """Split signal into voiced and unvoiced parts based on spectral flatness."""
    frame_length = 2048
    hop_length = 512
    stftkwargs = dict(n_fft=frame_length, hop_length=hop_length)

    # complex spectrum
    S = librosa.stft(y=y, **stftkwargs)

    # voice metric
    flatness = librosa.feature.spectral_flatness(S=np.abs(S), amin=np.sqrt(noise_var), **stftkwargs)
    voicedness = 1-flatness

    # separate depending on threshold
    condition = voicedness > threshold
    voiced_frames = np.where(condition, S, np.zeros_like(S))
    unvoiced_frames = np.where(~condition, S, np.zeros_like(S))
    voiced_frames_compr = np.compress(condition[0], S, axis=-1)
    unvoiced_frames_compr = np.compress(~condition[0], S, axis=-1)

    # rebuild build time signal from frames
    voiced = librosa.istft(voiced_frames, **stftkwargs)
    unvoiced = librosa.istft(unvoiced_frames, **stftkwargs)
    voiced_compr = librosa.istft(voiced_frames_compr, **stftkwargs)
    unvoiced_compr = librosa.istft(unvoiced_frames_compr, **stftkwargs)

    if PLOT:
        _, ax = plt.subplots(nrows=6, sharex=True, figsize=(10, 10))
        librosa.display.waveshow(y, sr=sr, ax=ax[0])
        time = librosa.times_like(S, sr=sr, **stftkwargs)
        rms_frames = librosa.feature.rms(y=y, frame_length=frame_length, hop_length=hop_length)
        ax[0].set_ylabel("waveform\n orig")
        ax[1].plot(time, rms_frames.T)
        ax[1].plot(time, np.ones_like(time)*np.sqrt(noise_var))
        ax[1].set_ylabel("rms")
        ax[2].plot(time, flatness.T)
        ax[2].set_ylabel("flatness")
        ax[3].plot(time, voicedness.T)
        ax[3].set_ylabel("voicedness")
        ax[3].plot(time, np.ones_like(time)*thresh)
        ax[4].set_ylabel("waveform\n voiced")
        librosa.display.waveshow(voiced, sr=sr, ax=ax[4])
        ax[5].set_ylabel("waveform\n unvoiced")
        librosa.display.waveshow(unvoiced, sr=sr, ax=ax[5])
        plt.tight_layout()
        plt.show()

    return voiced, unvoiced, voiced_compr, unvoiced_compr


def compute_noise_variance_from_calibrated_noise_recordings():
    calibrated_noise_var = {}
    for key, f in [("none", "No_noise_sound pressure at 1m.wav"),
                   ("33dB", "Noise_33dBA_sound pressure at 1m.wav"),
                   ("43dB", "Noise_43dBA_sound pressure at 1m.wav")]:
        n, sr = sf.read(f)
        n = n.T
        calibrated_noise_var[key] = n.var(axis=-1).tolist()
    print(calibrated_noise_var)
    sys.exit(0)

if __name__ == "__main__":

    # computed from background noise measurements
    # calibrated_noise_var = compute_noise_variance_from_calibrated_noise_recordings()
    calibrated_noise_var = {
        'none': [4.982600020366221e-06, 8.420907748206339e-07],
        '33dB': [1.804999794887358e-05, 7.943788796140364e-07],
        '43dB': [2.12545564057614e-05, 7.367032106082632e-07]}

    class CustomFormatter(argparse.ArgumentDefaultsHelpFormatter, argparse.RawDescriptionHelpFormatter):
        pass
    parser = argparse.ArgumentParser(
        description="Compute average sound pressure levels and save to csv",
        formatter_class=CustomFormatter,
        epilog="""
Some examples
=============
Plot useful graphs and save wav files of voiced and unvoiced parts for noise level 43dB:

    python -m libownaura.compute_average_spl --savewav  --plot 43dB 2022-02-09T13-18-49\ subject\ P0325\ room\ 8\ dualTask\ False_sound\ pressure\ at\ 1m.wav

Save wavs for no noise:

    python -m libownaura.compute_average_spl --savewav none 2022-02-09T13-23-33\ subject\ P0325\ room\ 6\ dualTask\ False_sound\ pressure\ at\ 1m.wav

Just compute for 33dB noise:

    python -m libownaura.compute_average_spl 33dB 2022-02-09T13-28-01\ subject\ P0325\ room\ 4\ dualTask\ False_sound\ pressure\ at\ 1m.wav

"""
    )
    parser.add_argument(
        "noise", choices=calibrated_noise_var.keys(), help="noise setting"
    )
    parser.add_argument(
        "file",
        help='recordings of calibrated headset and measurement microphone', nargs='+'
    )
    parser.add_argument(
        "-t", "--thresh", help="voicedness threshold", default=0.95
    )
    parser.add_argument(
        "--savewav", action="store_true", help="save wave files", default=False
    )
    parser.add_argument(
        "--plot", action="store_true", help="plot some useful data", default=False
    )

    args = parser.parse_args()
    PLOT = args.plot
    SAVEWAV = args.savewav

    noise_vars = calibrated_noise_var[args.noise]

    thresh = args.thresh

    headers = ['name', 'chan',
                'all [dB]', 'only voiced [dB]', 'only unvoiced [dB]',
                'all-noise [dB]', 'only voiced-noise [dB]', 'only unvoiced-noise [dB]',
                'voice/unvoiced ratio']

    table = []
    for f in args.file:
        if Path(f).suffix != '.wav':
            raise ValueError("input the calibrated wav files, not the original aif")

        print('Processing', f, '...')
        x, sr = sf.read(f)
        filename = Path(f).stem
        channels = (('headset', headset_channel_convolver_recording),
                    ('measmic', measmic_channel_convolver_recording))
        for ch, idx in channels:
            xc = x[:, idx]
            nvar = noise_vars[idx]
            _, _, vc, uc = split_voice_unvoiced(xc, sr, nvar, thresh)
            talking_ratio = vc.shape[0] / x.shape[0]
            spl = map(avg_spl, (xc, vc, uc))
            spl_without_noise = map(lambda x: avg_spl(x, nvar), (xc, vc, uc))
            table.append([filename, ch, *spl, *spl_without_noise, talking_ratio])

            if SAVEWAV:
                sf.write(f+"_"+ch+"_only_voice.wav", vc, sr)
                sf.write(f+"_"+ch+"_only_unvoice.wav", uc, sr)

        print(tabulate(table[-2:], headers=headers))

    print()
    print("Summary")
    print("=======")
    print(tabulate(table, headers=headers))

    import csv
    csvname = f'average_spl_noise_{args.noise}.csv'
    with open(csvname, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(headers)
        writer.writerows(table)
    print("Wrote all results to", csvname)




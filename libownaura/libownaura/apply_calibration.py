"""Calibrate a filter for OwnAuralization"""

import argparse
import re
from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt
import soundfile as sf
from response import Response


def apply_calibration(w, h, n):
    """Convonve each filter in w with h and cut or pad by n samples.

    Args:
        w (ndarray[nch, nsample]): multichan impulse response
        h (1d ndarray): calibration impulse response
        n: cut or pad with this amount of samples
    """
    # calibrate filter gain with minimum_phase_filter
    w_cal = np.zeros((w.shape[0], h.shape[0] + w.shape[1] - 1))
    for i in range(w.shape[0]):
        w_cal[i] = np.convolve(w[i], h)

    # calibrate filter time
    if n > 0:  # cut samples at beginning
        w_cut = w_cal[:, :n]
        print(f"Cutting {np.sum(w_cut**2) / np.sum(w_cal**2) * 100:.5f}% of energy in filter.")
        w_cal = w_cal[:, n:]
    elif n < 0: # pad at the beginning
        w_cal = np.pad(w_cal, ((0, 0), (-n, 0)))

    # NOTE: one could apply a quick fade in here

    return w_cal


def main(lora_filter, calibration_file, outfile, debug):
     # load lora wav file
    w, fs = sf.read(lora_filter)
    w = w.T  # shape (nch, nsample)

    # load calibration file
    with np.load(calibration_file) as data:
        assert data['fs'] == fs, f"impulse response (fs={fs}) and calibration file (fs={data['fs']}) must have same samplerate"
        h = data['h']
        n = data['n']

    w_cal = apply_calibration(w, h, n)

    if debug:
        r_cal = Response.from_time(fs, np.abs(w_cal).sum(axis=0))
        r_orig = Response.from_time(fs, np.abs(w).sum(axis=0))

        # plt.figure()
        # plt.subplot(3, 1, 1)
        # D = librosa.amplitude_to_db(librosa.stft(r_nowindow.in_time), ref=np.max)
        # librosa.display.specshow(D, y_axis='log', sr=fs, vmin=-100, vmax=0)
        # plt.colorbar(format='%+2.0f dB')
        # plt.subplot(3, 1, 2)
        # D = librosa.amplitude_to_db(librosa.stft(r_window.in_time), ref=np.max)
        # librosa.display.specshow(D, y_axis='log', sr=fs, vmin=-100, vmax=0)
        # plt.colorbar(format='%+2.0f dB')
        # plt.subplot(3, 1, 3)
        # D = librosa.amplitude_to_db(librosa.stft(r_orig.in_time), ref=np.max)
        # librosa.display.specshow(D, y_axis='log', sr=fs, vmin=-100, vmax=0)
        # plt.colorbar(format='%+2.0f dB')

        plt.figure()
        plt.subplot(2, 1 , 1)
        plt.title('Energy decay of filter sum')
        plt.plot(r_orig.times, 20*np.log10(np.abs(r_orig.in_time) / np.max(np.abs(r_orig.in_time))), label='original')
        plt.plot(r_cal.times, 20*np.log10(np.abs(r_cal.in_time)  / np.max(np.abs(r_cal.in_time))), label='calibrated')
        plt.legend()
        plt.xlabel('Time [s]')
        plt.ylabel('Energy [s]')

        plt.subplot(2, 1 , 2)
        plt.title('Close up at filter start')
        plt.plot(r_orig.times, r_orig.in_time / np.max(np.abs(r_orig.in_time)), label='original')
        plt.plot(r_cal.times, r_cal.in_time / np.max(np.abs(r_cal.in_time)), label='calibrated')
        plt.legend()
        plt.xlim(0, 0.030)
        plt.xlabel('Time [s]')
        plt.ylabel('Normalized filter amplitude')
        plt.show()

    # NOTE: subtype here is important, without, there are audible artifacts in the responses, presumbably due to the small values
    sf.write(outfile, w_cal.T, fs, subtype='FLOAT')
    print(f"Saved calibrated filter at `{outfile}`.")


if __name__ == '__main__':

    # def my_regex_window_type(arg_value, pat=re.compile(r"\(\(\d*\.\d+|\d+,\d*\.\d+|\d+\),\(\d*\.\d+|\d+,\d*\.\d+|\d+\)\)")):
    #     if not pat.match(arg_value):
    #         raise argparse.ArgumentTypeError
    #     return arg_value

    parser = argparse.ArgumentParser(
        description='Calibrate a set of lora filters.',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument('lora_filter', help='wav export from lora toolbox.')
    parser.add_argument('-c', '--calibration_file', default='calibration_filter.npz')
    parser.add_argument('-o', '--output', help='path or name of output file')
    #parser.add_argument('--window', help='a time window to be applied to all filters', default=((0, 0.0001), ((3.5, 3.8))), type=my_regex_window_type)
    parser.add_argument('-d', '--debug', help='turn on debug plotting', action='store_true')

    # parse args
    args = parser.parse_args()
    DEBUG = args.debug

    if args.output:
        outfile_str = args.output
    else:
        lora_filter_path = Path(args.lora_filter)
        outfile_str = str(lora_filter_path.parent / lora_filter_path.stem) + "_calibrated.wav"

    main(args.lora_filter, args.calibration_file, outfile_str, DEBUG)
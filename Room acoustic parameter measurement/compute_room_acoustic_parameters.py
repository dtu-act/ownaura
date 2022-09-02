# %%
import csv
from itertools import cycle

import matplotlib.pyplot as plt
import numpy as np
import soundfile as sf
from tqdm import tqdm
from response import Response
from tabulate import tabulate
from acoustics import room
from acoustics.bands import (octave, octave_high, octave_low,
                             third, third_high, third_low)
from acoustics.signal import bandpass
from scipy import stats

from libownaura.measure_avil_impulse_responses import transfer_function

SR = 48000  # samplerate

print('Change the DEBUG variable to `True` to get some plots.')
DEBUG = False  # toggle debug plotting

def RT_impulse(fs, raw_signal, bands, init, end, ax=None):  # pylint: disable=too-many-locals
    """
    Reverberation time from a WAV impulse response.

    :param file_name: name of the WAV file containing the impulse response.
    :param bands: Octave or third bands as NumPy array.
    :param init, end: Start and end levels, e.g. EDT (init, end) = (0, -10), T30 (init, end) == (-5, -35)
    :returns: Reverberation time :math:`T_{60}`

    Adapted from https://github.com/python-acoustics/python-acoustics/blob/master/acoustics/room.py
    """
    if bands == 'octave':
        center = octave(125, 8000)
        low = octave_low(center[0], center[-1])
        high = octave_high(center[0], center[-1])
    elif bands == 'third':
        center = third(125, 8000)
        low = third_low(center[0], center[-1])
        high = third_high(center[0], center[-1])
    elif bands == 'fullband':
        center = ['fullband']
        low = [100]
        high = [8000]
    else:
        raise ValueError()

    if ax:
        color_codes = map('C{}'.format, cycle(range(10)))

    factor = 60 / (init - end)
    RT = []
    for c, l, h in zip(center, low, high):
        # Filtering signal
        filtered_signal = bandpass(raw_signal, l, h, fs, order=8)
        abs_signal = np.abs(filtered_signal) / np.max(np.abs(filtered_signal))

        # Schroeder integration
        sch = np.cumsum(abs_signal[::-1]**2)[::-1]
        sch_db = 10.0 * np.log10(sch / np.max(sch))

        # Linear regression
        init_sample = np.abs(sch_db - init).argmin()
        end_sample = np.abs(sch_db - end).argmin()
        x = np.arange(init_sample, end_sample) / fs
        y = sch_db[init_sample:end_sample]
        slope, intercept = stats.linregress(x, y)[0:2]

        # Reverberation time (T30, T20, T10 or EDT)
        db_regress_init = (init - intercept) / slope
        db_regress_end = (end - intercept) / slope
        RT.append(factor * (db_regress_end - db_regress_init))

        if ax:
            color=next(color_codes)
            linestyle ='-' if c != 'fullband' else '--'
            ax.plot(x, y, label=c, color=color, linestyle=linestyle)
            ax.plot(x, intercept + slope*x, color=color, linestyle=linestyle)
    return np.array(RT)



def file_to_tf(fname):
    print('Loading', fname)
    rec, srr = sf.read(fname)
    assert SR == srr
    # rec_reference = rec[:, 3] # reference is excitation signal
    rec_reference = rec[:, 2] # reference is headset signal
    rec_leftear = rec[:, 0]
    rec_rightear = rec[:, 1]

    print('Frequency window')
    # filter frequencies above and below the 125 to 8000 hz octave bands
    freqwin = ((60, 88), (12000, 14000))
    delay_seconds = 0 # delay to get causal response
    rec_leftear = (
        Response.from_time(SR, rec_leftear)
        .delay(delay_seconds)
        .freq_window(*freqwin)  # apply freqwin
        .in_time
    )
    rec_rightear = (
        Response.from_time(SR, rec_rightear)
        .delay(delay_seconds)
        .freq_window(*freqwin)
        .in_time
    )

    print('Compute transfer function')
    cut_seconds = 0 # cut 10 ms at the beginning of responses to move impulse close to t=0 when using reference signal
    ntake = 5 * SR  # take only 5 seconds of the response
    h_left = transfer_function(ref=rec_reference, meas=rec_leftear, reg_lim_dB=50)[int(cut_seconds * SR):ntake]
    h_right = transfer_function(ref=rec_reference, meas=rec_rightear, reg_lim_dB=50)[int(cut_seconds * SR):ntake]

    if DEBUG:
        plt.figure()
        freqs = Response.freq_vector(len(rec_leftear), SR)
        plt.semilogx(freqs, 20 * np.log10(np.abs(np.fft.rfft(rec_rightear))), label='right ear')
        plt.semilogx(freqs, 20 * np.log10(np.abs(np.fft.rfft(rec_leftear))), label='left ear')
        plt.semilogx(freqs, 20 * np.log10(np.abs(np.fft.rfft(rec_reference))), label='headset')
        plt.xlim(50, 15000)
        plt.xlabel('Frequency [Hz]')
        plt.ylabel('Magnitude [dB]')
        plt.ylim(-50, 50)
        plt.suptitle(f'Energy in recordings for {fname}')
        plt.legend()
        plt.show()

    return h_left, h_right


if __name__ == '__main__':

    rooms = ['Anechoic', 'CalibrationRoom'] + [f'Room{i}' for i in range(1, 13)]

    # collect RTs in table
    octave_bands = octave(125, 8000)
    data = []
    data.append(['Room'] + [f'T_30 {band} [s]' for band in octave_bands] + ['DT_40,ME [s]', 'Room Gain G_RG [dB]', 'Voice Support ST_V [dB]', 'G_RG from ST_V [dB]'])

    h_noroom_left, h_noroom_right = file_to_tf('HatsDir/recordings/Anechoic.aif')

    # Energy level without room as average over both ears
    E_anechoic = (np.sum(h_noroom_left**2) + np.sum(h_noroom_right**2)) / 2

    for room in tqdm(rooms, desc='rooms'):
        if room == 'Anechoic':
            # dont do loading work twice
            h_left, h_right = h_noroom_left, h_noroom_right
        else:
            h_left, h_right = file_to_tf(f"HatsDir/recordings/{room}.aif")

        if DEBUG:
            fig = Response.from_time(SR, h_left).plot(label='room response left ear')
            Response.from_time(SR, h_right).plot(label='room response right ear', use_fig=fig)
            Response.from_time(SR, h_noroom_left).plot(label='anechoic response left ear', use_fig=fig)
            Response.from_time(SR, h_noroom_right).plot(label='anechoic response right ear', use_fig=fig)
            plt.suptitle(f'Anechoic and {room} response')
            plt.show()

        # time window for direct and reverberant sound
        h_direct_left = Response.from_time(SR, h_left).time_window(None, (0.0045, 0.0055)).in_time
        h_direct_right = Response.from_time(SR, h_right).time_window(None, (0.0045, 0.0055)).in_time
        h_reverb_left = Response.from_time(SR, h_left).time_window((0.0045, 0.0055), None).in_time
        h_reverb_right = Response.from_time(SR, h_right).time_window((0.0045, 0.0055), None).in_time

        if DEBUG:
            t = Response.from_time(SR, h_right).times
            plt.plot(t, h_direct_right)
            plt.plot(t, h_reverb_right)
            plt.xlim((0, 0.050))
            plt.show()

        ax = None
        if DEBUG:
            fig, ax = plt.subplots()

        # first col is name
        results = [room]

        # next cols are T30
        t30_left = RT_impulse(SR, h_left, bands='octave', init=-5, end=-35, ax=ax)
        t30_right = RT_impulse(SR, h_right, bands='octave', init=-5, end=-35, ax=ax)
        t30 = (t30_left + t30_right) / 2
        results += t30.round(2).tolist()

        # next col is DT_40,ME
        DT_40_left = RT_impulse(SR, h_left, bands="fullband", init=0, end=-40, ax=ax)
        DT_40_right = RT_impulse(SR, h_right, bands="fullband", init=0, end=-40, ax=ax)
        DT_40 = (DT_40_left + DT_40_right) / 2
        results += DT_40.round(2).tolist()

        # next col is room gain
        E_room = (np.sum(h_left**2) + np.sum(h_right**2)) / 2
        G_RG = 10 * np.log10(E_room / E_anechoic)
        results.append(G_RG.round(3))

        # next col is voice support
        E_reverb = (np.sum(h_reverb_left**2) + np.sum(h_reverb_right**2)) / 2
        E_direct = (np.sum(h_direct_left**2) + np.sum(h_direct_right**2)) / 2
        ST_V = 10 * np.log10(E_reverb / E_direct)
        results.append(ST_V.round(3))

        # next col is room gain computed from voice support
        G_ST_V = 10 * np.log10(10**(ST_V/10) + 1)
        results.append(G_ST_V.round(3))

        data.append(results)

        if DEBUG:
            ax.legend()
            ax.set_title(f'{room} $T_{{30}}$')
            ax.set_xlabel('time [s]')
            ax.set_ylabel('Level [dB]')
            plt.suptitle('Decay curves with fit')
            plt.show()

    # print as table
    print(tabulate(data, headers='firstrow'))

    # save as table
    with open('estimate_room_parameter.csv', 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerows(data)

    print('Written results to `estimate_room_parameter.csv`')
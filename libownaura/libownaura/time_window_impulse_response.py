import argparse
import pathlib

import numpy as np
import matplotlib.pyplot as plt
from response import Response
from scipy.signal.windows import hann

from libownaura.utils import time_window_type

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Time window loudspeaker responses',
        epilog='Example: python -m libownaura.time_window_impulse_response --debug -w "((0.0195, 0.0197), (0.023, 0.024))" h_avil_2021-02-05T16-59-50.npz',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument('response', help='impulse response file', type=pathlib.Path)
    parser.add_argument('-w', '--time-window', help='specify the hann-window as a pair of in/out fade times in seconds. Default is `((0.0195, 0.0197), (0.023, 0.024))`',
        default=((0.0195, 0.0197), (0.023, 0.024)), type=time_window_type,
    )
    parser.add_argument('-o', '--output', help='output file name or path', default=None, type=pathlib.Path)
    parser.add_argument('-d', '--debug', help='turn on plotting', default=False, action='store_true')

    args = parser.parse_args()

    if args.output is None:
        args.output = args.response.with_name(args.response.stem + '_windowed')

    with np.load(args.response) as data:
        h = data['h']
        fs = data['fs']

    print(repr(args.time_window))

    t_start = args.time_window[0][0]
    t_end = args.time_window[1][1]

    # crop the responses
    r = Response.from_time(fs, h)
    r_windowed = r.time_window(*args.time_window).timecrop(0, t_end)  # creates copy

    if args.debug:
        r.plot(tlim=(t_start, t_end), flim=(80, 20000), dblim=(-30, -5));
        plt.suptitle('Before cropping and windowing');
        r_windowed.plot(tlim=(t_start, t_end), flim=(80, 20000), dblim=(-30, -5));
        plt.suptitle('After cropping and windowing');
        plt.show()

    # save
    np.savez(args.output, h=r_windowed.in_time, fs=fs)
    print(f"Created {args.output}")



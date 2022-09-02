import argparse
import re
import numpy as np

from scipy.signal import correlate, coherence
from response import Response
from ast import literal_eval

def time_align(x, y, fs, trange=None):
    """Time align two signals, zeropad as necessary.

    If `dt` is positive `x` was delayed and `y` zeropadded for same length.
    """
    assert len(x) == len(y)
    n = x.size

    # cross correlation
    xcorr = correlate(y, x, mode="full")

    # delta time array to match xcorr
    t = np.arange(1 - n, n) / fs

    if trange is not None:
        idx = np.logical_and(trange[0] <= t, t <= trange[1])
        t = t[idx]
        xcorr = xcorr[idx]

    # estimate delay in time
    dt = t[xcorr.argmax()]

    # match both responses in time and length
    if dt >= 0:
        x = Response.from_time(fs, x).delay(dt, keep_length=False).in_time
        y = Response.from_time(fs, y).zeropad_to_length(x.size).in_time
    else:
        y = Response.from_time(fs, y).delay(-dt, keep_length=False).in_time
        x = Response.from_time(fs, x).zeropad_to_length(y.size).in_time

    return x, y, dt


def coherence_csd(x, y, fs, compensate_delay=True, **csd_kwargs):
    """Estimate maginitude squared coherence of two signals using Welch's method.

    Parameters
    ----------
    x, y : ndarray, float
        Reference and measured signal in one dimensional arrays of same length.
    fs : int
        Sampling frequency
    compensate_delay: optional, bool
        Compensate for delays in correlation estimations.
    **csd_kwargs
        Kwargs are fed to csd and welch functions.

    Returns
    -------
    f : ndarray
        Array of sample frequencies.
    Cxy : ndarray
        Magnitude squared coherence

    """
    assert x.ndim == 1
    assert y.ndim == 1
    assert x.size == y.size

    if compensate_delay:
        x, y, _ = time_align(x, y, fs)

    f, Cxy = coherence(x, y, fs=fs, **csd_kwargs)

    return f, Cxy


def find_nearest(array, value):
    """Find nearest value in an array and its index."""
    idx = (np.abs(array - value)).argmin()
    return array[idx], idx


def time_window_type(arg_value, pat=re.compile(r"\(\(\d*\.\d+|\d+,\d*\.\d+|\d+\),\(\d*\.\d+|\d+,\d*\.\d+|\d+\)\)")):
    if not pat.match(arg_value):
        raise argparse.ArgumentTypeError
    return literal_eval(arg_value)
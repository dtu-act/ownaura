import soundfile as sf

from libownaura.measure_avil_impulse_responses import exponential_sweep


sweep = exponential_sweep(T=60, fs=48000, tfade=0.5, f_start=50, f_end=15000, maxamp=1, post_silence=5)
sf.write('sweep_T60_ps5.wav', data=sweep, samplerate=48000, subtype='FLOAT')

sweep = exponential_sweep(T=120, fs=48000, tfade=0.5, f_start=50, f_end=15000, maxamp=1, post_silence=5)
sf.write('sweep_T120_ps5.wav', data=sweep, samplerate=48000, subtype='FLOAT')

sweep = exponential_sweep(T=180, fs=48000, tfade=0.5, f_start=50, f_end=15000, maxamp=1, post_silence=5)
sf.write('sweep_T180_ps5.wav', data=sweep, samplerate=48000, subtype='FLOAT')

sweep = exponential_sweep(T=240, fs=48000, tfade=0.5, f_start=50, f_end=15000, maxamp=1, post_silence=5)
sf.write('sweep_T240_ps5.wav', data=sweep, samplerate=48000, subtype='FLOAT')
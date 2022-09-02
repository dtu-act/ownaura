# System validation

For setup, do as in `Setup AVIL` in `Ownaura/README.md`. Additionally:

- place Head-and-torso-simulator (HATS) on seat
  - correct seat height such that head is in center
  - correct distance of measurement microphone to avil center to 1m
  - place headset on HATS
- connect XLR OUT 1 -> amplifier -> HATS mouth loudspeaker

For calibration,

- start noise generator with pink noise `MAX/noise_generator.maxpat`
- check levels in headset and measurement mic with `MAX/monitor_levels.maxpat`
- record 60s of noise using the patch `MAX/record_all_mics.maxpat`
  - save as `data/hats_right_measmic_headset_whitenoise (calibration_rec).aif`

To compute the calibration filters, run

    cd Ownaura/Validation
    python -m libownaura.compute_calibration_filter "data\hats_right_measmic_headset_whitenoise (calibration_rec).aif" -o processed\calibration_filter --debug

To build the calibrated LORA filters, run

    python compute_calibrated_room_filters.py

To measure with HATS,

- connect HATS microphones to
    + LEMO 1 -> NEXUS 1 -> input DSP #5 and
    + LEMO 2 -> NEXUS 2 -> input DSP #7
- check that amplifier gain in NEXUS is 1 V/Pa for both channels

For sweep measurements for TF estimation from mouth to ears,

- start convolver patch at `MAX/convolver.maxpatch`
- load a calibrated filter from `processed/calibrated lora filters`
- play and record sweeps with `MAX/sweep_measurement.maxpat`.

To analyze all recordings and compute room gain, voice support and reverberation time, run

    python compute_room_acoustic_parameters.py
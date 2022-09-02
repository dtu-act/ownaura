import os
import argparse
from pathlib import Path
from libownaura.apply_calibration import main as apply_calibration

OWNAURA_PATH = Path(os.path.realpath(__file__)).parent.parent.parent

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Calibrate Lora filters using calibration file",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        "-c", "--calibration_file",
        help="the calibration file",
        default="calibration_file.npz"
    )
    parser.add_argument(
        "-l", "--lora_filter_folder",
        help="the folder holding the lora filters",
        default=OWNAURA_PATH / "Lora filters",
        type=Path
    )
    parser.add_argument(
        "-o", "--output_folder",
        help="folder to save output",
        default=".",
        type=Path
    )
    parser.add_argument(
        "--debug", action="store_true", help="turn on debug plotting", default=False
    )

    args = parser.parse_args()

    print(f'Using calibration_file {args.calibration_file}')
    print(f'Using lora_filter_folder {args.lora_filter_folder}')
    print(f'Using output_folder {args.output_folder}')

    lora_filters = list(args.lora_filter_folder.glob("*.wav"))

    if not lora_filters:
        raise Exception(f'Could not find any lora filters in {args.lora_filter_folder}. Check path!')

    for lora_filter in lora_filters:
        outfile = str(args.output_folder / (lora_filter.stem + "_calibrated.wav"))
        print('Calibrating', lora_filter)
        apply_calibration(str(lora_filter), args.calibration_file, outfile, args.debug)
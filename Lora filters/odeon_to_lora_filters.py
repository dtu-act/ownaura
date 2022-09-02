"""Computes LORA filters for each room in `Ownaura/Odeon rooms`"""

import os
from pathlib import Path
from tqdm import tqdm

# quote escaping
def tostr(path):
    return f'"{str(path)}"'
def tostr2(path):
    return f"'{str(path)}'"


OWNAURA_PATH = Path("..").resolve()  # use absolute paths
ROOMS_PATH = OWNAURA_PATH / 'Odeon rooms'

# all folders in ROOMS_PATH that have a AVIL implementation files subfolder
folders = [x for x in ROOMS_PATH.iterdir() if x.is_dir() and (x / 'AVIL implementation files').is_dir()]

ignore_direct = 1  # remove the direct sound
trim = 1           # Trim the length of responses that contain only zeros
debug = 0

for room in tqdm(folders):
    print(room)
    # move early relfections by this amount of milliseconds if not Calibration room
    move_ER = 22 if room.stem != "Calibration Room" else 0

    name = room.stem
    implementation_folder = room / 'AVIL implementation files'
    implementation_file_stem = str(next(implementation_folder.glob("*EarlyReflections.Txt")).name).replace("EarlyReflections.Txt","")
    outfile = Path.cwd() / (name + '.wav')
    os.system(" ".join((
        'matlab',
        f'-sd {tostr(OWNAURA_PATH / "libownaura" / "matlab")}',
        f'-batch "compute_avil_ir_from_odeon_exports({tostr2(implementation_folder)}, {tostr2(implementation_file_stem)}, {tostr2(outfile)}, {ignore_direct}, {move_ER}, {debug}, {trim})"'
    )))

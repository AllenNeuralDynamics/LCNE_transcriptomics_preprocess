"""
Transfer MERFISH cell_metadata.csv and cell_by_gene.csv from the Allen network drive
into the local repo's data/merfish/metadata/ directory, preserving folder structure.

Also creates 0-byte .tif placeholder files so the notebook's region-selection logic
(which counts .tif files per region) still works.

Usage:
    python code/transfer_merfish_data.py
"""

import glob
import os
import shutil
from pathlib import Path

SOURCE_ROOT = Path("/allen/aind/scratch/shuonan.chen/pons_images")
REPO_ROOT = Path(__file__).parent.parent
DEST_ROOT = REPO_ROOT / "data" / "merfish" / "metadata"

CSV_NAMES = {"cell_metadata.csv", "cell_by_gene.csv"}


def transfer():
    if not SOURCE_ROOT.exists():
        raise FileNotFoundError(f"Source not found: {SOURCE_ROOT}")

    csv_pattern = str(SOURCE_ROOT / "*/analyzed_data/*/region_*/*.csv")
    csv_files = glob.glob(csv_pattern)

    copied = 0
    skipped = 0
    total_bytes = 0

    for src_path in sorted(csv_files):
        src = Path(src_path)
        if src.name not in CSV_NAMES:
            continue

        rel = src.relative_to(SOURCE_ROOT)
        dst = DEST_ROOT / rel

        if dst.exists() and dst.stat().st_size == src.stat().st_size:
            skipped += 1
            continue

        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        size = dst.stat().st_size
        total_bytes += size
        copied += 1
        print(f"  copied {rel}  ({size / 1e6:.1f} MB)")

    # Create 0-byte .tif placeholders for region selection logic
    tif_pattern = str(SOURCE_ROOT / "*/analyzed_data/*/region_*/images/*.tif")
    tif_files = glob.glob(tif_pattern)
    placeholders = 0

    for tif_path in sorted(tif_files):
        tif = Path(tif_path)
        rel = tif.relative_to(SOURCE_ROOT)
        dst = DEST_ROOT / rel

        if dst.exists():
            continue

        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.touch()
        placeholders += 1

    print(f"\nDone: {copied} CSVs copied ({total_bytes / 1e6:.1f} MB), "
          f"{skipped} skipped, {placeholders} .tif placeholders created.")


if __name__ == "__main__":
    transfer()

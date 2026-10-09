#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Measure a red logo against the text beside it, in a PPM rendered by pdftoppm.

Prints "<logo height px> <offset half-px>": the offset is between the logo's centre and the
centre of the first glyph left of it (the P of "Prepared", which runs cap height to baseline).

Usage: uv run tests/centre.py page.ppm
"""

from __future__ import annotations

import sys
from pathlib import Path


def read_ppm(path: Path) -> tuple[int, int, bytes]:
    data = path.read_bytes()
    fields: list[bytes] = []
    pos = 0
    # Header: magic, width, height, maxval, each separated by whitespace (no comments from pdftoppm).
    while len(fields) < 4:
        while data[pos:pos + 1].isspace():
            pos += 1
        start = pos
        while not data[pos:pos + 1].isspace():
            pos += 1
        fields.append(data[start:pos])
    if fields[0] != b"P6" or fields[3] != b"255":
        raise SystemExit(f"{path}: expected an 8-bit P6 PPM, got {fields[0]!r} maxval {fields[3]!r}")
    width, height = int(fields[1]), int(fields[2])
    return width, height, data[pos + 1:]


def main() -> int:
    width, height, px = read_ppm(Path(sys.argv[1]))

    def rgb(x: int, y: int) -> tuple[int, int, int]:
        i = (y * width + x) * 3
        return px[i], px[i + 1], px[i + 2]

    red = [(x, y) for y in range(height) for x in range(width)
           if (c := rgb(x, y))[0] > 200 and c[1] < 60 and c[2] < 60]
    if not red:
        raise SystemExit("no red logo found")
    top, bottom = min(y for _, y in red), max(y for _, y in red)
    left = min(x for x, _ in red)

    def ink(x: int, y: int) -> bool:
        return sum(rgb(x, y)) < 3 * 128

    columns = [x for x in range(left) if any(ink(x, y) for y in range(height))]
    if not columns:
        raise SystemExit("no text left of the logo")
    stem = range(columns[0], columns[0] + 3)
    rows = [y for y in range(height) if any(ink(x, y) for x in stem)]
    logo_mid2 = top + bottom
    text_mid2 = min(rows) + max(rows)
    print(bottom - top + 1, abs(logo_mid2 - text_mid2))
    return 0


if __name__ == "__main__":
    sys.exit(main())

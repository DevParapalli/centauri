#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Vendor Proxima's shared tokens.toml into src/tokens.toml.

Centauri is published as a self-contained Typst package, so it carries its own
copy of the shared tokens. This script is the only way that copy changes.

Usage:
    uv run scripts/sync-tokens.py --ref v1.1.0          # from GitHub at a tag
    uv run scripts/sync-tokens.py --from ../proxima/tokens.toml
    uv run scripts/sync-tokens.py --ref v1.1.0 --check  # exit 1 if the copy differs
"""

from __future__ import annotations

import argparse
import sys
import tomllib
import urllib.request
from pathlib import Path

REPO = "DevParapalli/proxima"
DEST = Path(__file__).resolve().parent.parent / "src" / "tokens.toml"
REQUIRED = ("version", "scale", "neutral", "state", "chart", "accent")


def fetch(ref: str) -> str:
    url = f"https://raw.githubusercontent.com/{REPO}/{ref}/tokens.toml"
    with urllib.request.urlopen(url, timeout=20) as response:  # noqa: S310 (fixed host)
        return response.read().decode("utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--ref", help="git tag or commit in the proxima repository")
    source.add_argument("--from", dest="path", type=Path, help="local tokens.toml")
    parser.add_argument("--check", action="store_true", help="compare only, do not write")
    args = parser.parse_args()

    text = fetch(args.ref) if args.ref else args.path.read_text(encoding="utf-8")
    data = tomllib.loads(text)  # refuse to vendor a file that does not parse
    missing = [key for key in REQUIRED if key not in data]
    if missing:
        print(f"error: tokens.toml is missing {', '.join(missing)}", file=sys.stderr)
        return 2

    origin = f"{REPO}@{args.ref}" if args.ref else str(args.path)
    header = (
        f"# Vendored by scripts/sync-tokens.py from {origin}.\n"
        "# Do not edit. Change tokens.toml in the proxima repository and sync again.\n\n"
    )
    vendored = header + text

    if args.check:
        current = DEST.read_text(encoding="utf-8") if DEST.exists() else ""
        body = current.split("\n\n", 1)[1] if "\n\n" in current else current
        if body != text:
            print(f"{DEST} differs from {origin}", file=sys.stderr)
            return 1
        return 0

    DEST.write_text(vendored, encoding="utf-8")
    print(f"wrote {DEST.name} (tokens v{data['version']}) from {origin}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Vendor Proxima's shared tokens.toml into src/tokens.toml.

Centauri is published as a self-contained Typst package, so it carries its own
copy of the shared tokens. This script is the only way that copy changes.

Usage:
    uv run scripts/sync-tokens.py                       # latest Proxima vX.Y.* for typst.toml's X.Y
    uv run scripts/sync-tokens.py --ref 0.3             # same, X.Y given explicitly
    uv run scripts/sync-tokens.py --from ../proxima/tokens.toml
    uv run scripts/sync-tokens.py --check               # exit 1 if the copy differs
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
import tomllib
import urllib.request
from pathlib import Path

REPO = "DevParapalli/proxima"
ROOT = Path(__file__).resolve().parent.parent
DEST = ROOT / "src" / "tokens.toml"
PACKAGE = ROOT / "typst.toml"
REQUIRED = ("version", "scale", "neutral", "state", "chart", "accent")
XY = re.compile(r"v?(\d+)\.(\d+)")


def latest_tag(ls_remote: str, xy: str) -> str | None:
    """Highest vX.Y.Z tag in `git ls-remote --tags` output, or None."""
    tag = re.compile(rf"refs/tags/(v{re.escape(xy)}\.(\d+))")
    found = [m for line in ls_remote.splitlines() if (m := tag.fullmatch(line.split("\t")[-1]))]
    # Numeric, so v0.3.10 outranks v0.3.9.
    return max(found, key=lambda m: int(m[2]))[1] if found else None


def remote_tags() -> str:
    result = subprocess.run(
        ["git", "ls-remote", "--tags", "--refs", f"https://github.com/{REPO}.git"],
        capture_output=True,
        text=True,
        timeout=30,
        check=True,
    )
    return result.stdout


def fetch(ref: str) -> str:
    url = f"https://raw.githubusercontent.com/{REPO}/{ref}/tokens.toml"
    with urllib.request.urlopen(url, timeout=20) as response:  # noqa: S310 (fixed host)
        return response.read().decode("utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    source = parser.add_mutually_exclusive_group()
    source.add_argument("--ref", help="major.minor (0.3 or v0.3); defaults to typst.toml's")
    source.add_argument("--from", dest="path", type=Path, help="local tokens.toml")
    parser.add_argument("--check", action="store_true", help="compare only, do not write")
    args = parser.parse_args()

    if args.path:
        text = args.path.read_text(encoding="utf-8")
        origin = str(args.path)
    else:
        package = tomllib.loads(PACKAGE.read_text(encoding="utf-8"))["package"]["version"]
        own = ".".join(package.split(".")[:2])
        if args.ref is None:
            xy = own
        elif m := XY.fullmatch(args.ref):
            xy = f"{m[1]}.{m[2]}"
        else:
            print(f"error: --ref takes major.minor, such as 0.3 or v0.3, not {args.ref!r}", file=sys.stderr)
            return 2
        if xy != own:
            print(f"error: --ref {xy} does not match typst.toml version {package}", file=sys.stderr)
            return 2
        try:
            tags = remote_tags()
        except FileNotFoundError:
            print("error: git not installed", file=sys.stderr)
            return 2
        tag = latest_tag(tags, xy)
        if tag is None:
            print(f"error: {REPO} has no v{xy}.* tag", file=sys.stderr)
            return 2
        text = fetch(tag)
        origin = f"{REPO}@{tag}"

    data = tomllib.loads(text)  # refuse to vendor a file that does not parse
    missing = [key for key in REQUIRED if key not in data]
    if missing:
        print(f"error: tokens.toml is missing {', '.join(missing)}", file=sys.stderr)
        return 2

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

#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pypdf>=5,<7", "pillow>=11,<13"]
# ///
"""LOL's tests: Centauri's suite first, then the brand's own checks. Run: `uv run examples/lol/run.py`.

A brand repository copies this file. There, CENTAURI is the Centauri submodule
(vendor/centauri), ROOT the brand repository and FONTS the brand's font folder.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
CENTAURI = HERE.parent.parent
ROOT = CENTAURI  # the brand imports "/lib.typ", so Typst's root is the Centauri checkout
FONTS = CENTAURI / "fonts"
sys.path.insert(0, str(CENTAURI / "tests"))
sys.dont_write_bytecode = True

import checks  # noqa: E402
from checks import fonts, squeezed, text  # noqa: E402

BRAND = HERE.relative_to(ROOT)


def main() -> int:
    # Centauri's own suite must pass before the brand's checks mean anything.
    base = subprocess.run([sys.executable, str(CENTAURI / "tests" / "run.py")], timeout=1800)
    if base.returncode != 0:
        print("FAIL  Centauri's suite")
        return 1

    s = checks.Suite(ROOT, FONTS)
    report = BRAND / "report.typ"
    pdf = s.passes(report)
    s.passes(report, "--input", "stage=draft")
    s.rejects(BRAND / "tests" / "sensitivity-typo.typ", "is not one of the theme's levels")
    if pdf is None:
        return s.done()

    # Masthead: the class in the header, changed by `furniture` from the next page.
    s.report("masthead class on page 3", "LOL Internal" in text(pdf, 3))
    s.report("masthead class changes on page 4", "LOL Confidential" in text(pdf, 4))
    # LOL's page distances place the masthead rule, the topmost stroke, 1.6cm from the top.
    from_top = [round((checks.page_height(pdf, 3) - y) / checks.CM, 2) for _, _, y in checks.strokes(pdf, 3)]
    s.report("masthead rule at LOL's header-line", min(from_top, default=None) == 1.6, repr(from_top))
    # Ledger: logo, class and page count in the footer, from the page after the switch.
    last = text(pdf, 6)
    s.report("ledger footer on page 6", "LOL Confidential" in last and "Page 6 of 6" in last, repr(last[-80:]))
    # Words and faces come from the theme: nothing falls back to Centauri's own.
    s.report("contents title from the theme's words", "What’s inside" in text(pdf, 2))
    families = {name.split("-")[0] for name in fonts(pdf)}
    s.report("only LOL's faces are embedded", families <= {"Outfit", "IBMPlexMono", "InstrumentSerif"}, repr(families))
    draft = s.pdf(report, "--input", "stage=draft")
    s.report("draft watermark from the theme's words", "LOLDRAFT" in squeezed(draft, 3))
    return s.done()


if __name__ == "__main__":
    sys.exit(main())

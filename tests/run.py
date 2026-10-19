#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pypdf>=5,<7", "pillow>=11,<13"]
# ///
"""Centauri's test suite: every example and test builds, each gate stops the build, and the
output carries what it should. Run from anywhere: `uv run tests/run.py`.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
sys.path.insert(0, str(HERE))
sys.dont_write_bytecode = True  # keep tests/__pycache__ out of the tree

import checks  # noqa: E402
from checks import lines, pages, squeezed, strokes, text, words  # noqa: E402


def documents(s: checks.Suite) -> None:
    for f in ("examples/showcase.typ", "tests/final-clean.typ", "tests/tone.typ", "tests/accent-pages.typ",
              "tests/fit-logo.typ", "tests/backdrop.typ", "tests/warn.typ"):
        s.passes(f)
    for f, message in (
        ("tests/final-todo.typ", "unresolved todo"),
        ("tests/final-lint.typ", "lint match"),
        ("tests/contrast.typ", "below 4.5:1"),
        ("tests/label-case-invalid.typ", "label-case must be"),
        ("tests/furniture-rule-invalid.typ", "header-rule must be a stroke, none or auto"),
        ("tests/annexes-invalid.typ", "annexes numbering takes two patterns"),
        ("tests/theme-unknown-key.typ", "unknown theme key fonts.headings"),
        ("tests/theme-missing.typ", "theme is missing words"),
        ("tests/sensitivity-invalid.typ", "is not one of the theme's levels"),
        ("tests/accent-none.typ", "this theme has no accents"),
        ("tests/kind-invalid.typ", "kind must be document or deck"),
        ("tests/deck-document-arg.typ", "unexpected argument: stage"),
    ):
        s.rejects(f, message)


def decks(s: checks.Suite) -> None:
    s.passes("examples/deck.typ")
    s.passes("examples/deck-accents.typ", "--input", "projection=light")
    s.passes("examples/deck-accents.typ", "--input", "projection=dark")
    s.passes("tests/deck-accent.typ")
    for args in ((), ("--input", "projection=dark"), ("--input", "mode=handout"), ("--input", "mode=titles"),
                 ("--input", "notes=true")):
        s.passes("tests/slides.typ", *args)
    s.rejects("tests/slide-overflow.typ", "overflows its page")
    s.rejects("tests/slide-title-stop.typ", "ends with a full stop")


def labels(s: checks.Suite) -> None:
    pdf = s.pdf("tests/captions.typ")
    for want in ("FIGURE1", "TABLE1"):
        s.report(f"caption label {want}", want in squeezed(pdf))
    pdf = s.pdf("tests/label-case.typ")
    body = text(pdf)
    for want in ("Figure 1", "Owner key", "Risk R1"):
        s.report(f"label-case as-written: {want}", want in body)
    s.report("label-case as-written prints no capitals", not re.search(r"FIGURE|OWNER KEY|RISK", body))


def furniture(s: checks.Suite) -> None:
    # Page 1 keeps both hairlines; `furniture` then drops the header rule and sets a red footer
    # rule, which page 2 shows and page 3 keeps.
    pdf = s.pdf("tests/furniture-rules.typ")
    for page, want_hair, want_red in ((1, 2, 0), (2, 0, 1), (3, 0, 1)):
        found = strokes(pdf, page)
        hair = sum(1 for w, _ in found if w == 0.5)
        red = sum(1 for w, c in found if c == (1.0, 0.0, 0.0))
        s.report(f"furniture rules page {page}", (hair, red) == (want_hair, want_red),
                 f"{hair} hairlines, {red} red (want {want_hair}, {want_red})")

    # A custom folio on page 1, a new sensitivity on page 2, Centauri's folio on page 3.
    pdf = s.pdf("tests/folio.typ")
    for page, want in ((1, "Internal – page 1 of 3"), (2, "Public – page 2 of 3"), (3, "3/3 | Public")):
        s.report(f"folio page {page}: {want}", want in lines(pdf, page))

    # A folio function in the footer's right slot prints in the right third.
    pdf = s.pdf("tests/folio-right.typ")
    hits = [x for t, x, _ in words(pdf, 1) if t.startswith("Internal")]
    width = checks.page_width(pdf, 1)
    s.report("folio in the right footer slot", bool(hits) and hits[0] / width > 0.67, f"x = {hits}")

    pdf = s.pdf("tests/furniture.typ")
    for page, want in ((1, "1/3 | Internal"), (2, "CLIENT"), (2, "2/3 | Confidential"), (3, "3/3 | Public")):
        s.report(f"furniture page {page}: {want}", want in text(pdf, page))
    s.report("furniture page 3 cleared", "CLIENT" not in text(pdf, 3))

    pdf = s.pdf("tests/first-page.typ")
    for want in ("BRIEFHEAD", "BRIEFFOOT"):
        s.report(f"first page furniture {want}", want in text(pdf, 1))

    # The sensitivity prints from a header slot and changes on the page after `furniture`.
    pdf = s.pdf("tests/sensitivity-header.typ")
    for page, want in ((1, "MARK-INTERNAL"), (2, "MARK-PUBLIC")):
        s.report(f"sensitivity in the header, page {page}: {want}", want in text(pdf, page))


def headings(s: checks.Suite) -> None:
    pdf = s.pdf("tests/theme-heading.typ")
    found = lines(pdf)
    for want in ("CUSTOM-H1 1 First", "CUSTOM-H2 1.1 Second MID"):
        s.report(f"theme heading function: {want}", want in found, repr(found))

    # Numbering restarts at A; references read "Annex A", or the theme's or caller's word.
    pdf = s.pdf("tests/annexes.typ")
    found = lines(pdf)
    for want in ("2 Body two", "See Annex A.", "A Key personnel", "A.1 Delivery lead", "B Glossary"):
        s.report(f"annexes: {want}", want in found, repr(found))
    s.report("annexes: no divider", pages(pdf) == 1)
    pdf = s.pdf("tests/annexes-custom.typ")
    for page, want in ((1, "See Appendix I."), (2, "Appendices"), (2, "Supporting material"),
                       (3, "I Key personnel"), (3, "I.a Delivery lead"), (3, "II Glossary")):
        s.report(f"annexes custom page {page}: {want}", want in lines(pdf, page), repr(lines(pdf, page)))
    pdf = s.pdf("tests/annexes-word.typ")
    s.report("annexes word from the theme", "See Schedule A." in lines(pdf))


def covers(s: checks.Suite) -> None:
    # Page 1 has no backdrop, page 2 a red block at the top left, page 3 a function that reads the tone.
    plain = s.png("tests/backdrop.typ", 1, 20)
    block = s.png("tests/backdrop.typ", 2, 20)
    s.report("backdrop none draws nothing", not checks.red_pixels(plain))
    s.report("backdrop content is drawn", block.getpixel((5, 5)) == (255, 0, 0), repr(block.getpixel((5, 5))))
    pdf = s.pdf("tests/backdrop.typ")
    s.report("backdrop function sees the cover's tone", "BACKDROP-TONE-dark" in text(pdf, 3))


def remarks(s: checks.Suite) -> None:
    draft = s.pdf("tests/warn.typ")
    review = s.pdf("tests/warn.typ", "--input", "stage=review")
    s.report("warn shows in draft", "WARN-REMARK" in text(draft))
    s.report("warn is dropped in review", "WARN-REMARK" not in text(review))
    at = [[(round(x, 2), round(y, 2)) for t, x, y in words(pdf, 1) if t == "AFTER-LINE"] for pdf in (draft, review)]
    s.report("warn takes no space", at[0] == at[1] and at[0] != [], repr(at))


def logos(s: checks.Suite) -> None:
    # An image (page 1) and a box with text (page 2), both 1.2cm, are capped at 0.8cm (94px at
    # 300 ppi) and centred on the cap-height midline within a pixel.
    for page in (1, 2):
        height, offset = checks.logo_centring(s.png("tests/logo-line.typ", page, 300))
        s.report(f"logo-line page {page}: {height}px, offset {offset}", height <= 95 and offset <= 2)


def docs(s: checks.Suite) -> None:
    # Every complete example in the docs (a typ block that opens with the package import) builds.
    for doc in ("README.md", "docs/reference.md"):
        blocks = re.findall(r"^```typ\n(.*?)^```$", (ROOT / doc).read_text(encoding="utf-8"), re.M | re.S)
        for i, block in enumerate(blocks, 1):
            if not block.startswith('#import "@preview/centauri'):
                continue
            src = ROOT / f".doc-example-{Path(doc).stem}-{i}.typ"
            src.write_text(re.sub(r'"@preview/centauri:[0-9.]*"', '"/lib.typ"', block, count=1), encoding="utf-8")
            try:
                s.passes(src.name)
            finally:
                src.unlink()

    # docs/reference.md documents every name lib.typ exports, and nothing else.
    lib = (ROOT / "lib.typ").read_text(encoding="utf-8")
    exported = set()
    for names in re.findall(r'^#import "src/[^"]+":\s*(\([^)]*\)|[^\n]+)', lib, re.M):
        for name in names.strip("()").split(","):
            name = name.split(" as ")[-1].strip()
            if name:
                exported.add(name)
    documented = set(re.findall(r"^### `([a-z0-9-]+)`", (ROOT / "docs/reference.md").read_text(encoding="utf-8"), re.M))
    missing, extra = sorted(exported - documented), sorted(documented - exported)
    s.report("docs/reference.md covers every export", not missing and not extra,
             f"undocumented: {missing}; documented but not exported: {extra}")


def sync_tokens(s: checks.Suite) -> None:
    run = subprocess.run([sys.executable, str(HERE / "sync-tokens.py")], capture_output=True, text=True, timeout=60)
    print(run.stdout, end="")
    s.report("sync-tokens checks", run.returncode == 0, run.stderr)


def main() -> int:
    s = checks.Suite(ROOT, ROOT / "fonts")
    for group in (documents, decks, labels, furniture, headings, covers, remarks, logos, docs, sync_tokens):
        group(s)
    return s.done()


if __name__ == "__main__":
    sys.exit(main())

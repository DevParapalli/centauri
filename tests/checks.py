"""Build and output checks for Centauri and the brand packages built on it.

Imported by tests/run.py and by a brand's own runner (examples/lol/run.py shows one).
Needs `typst` on PATH; reads PDFs with pypdf and PNGs with Pillow, which the importing
script declares in its PEP 723 block.
"""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image
from pypdf import PdfReader
from pypdf.generic import ContentStream

TIMEOUT = 180  # seconds per typst run; the showcase takes a few


class Suite:
    """Compiles Typst files and records named pass/fail results."""

    def __init__(self, root: Path, font_path: Path) -> None:
        self.typst = shutil.which("typst")
        if self.typst is None:
            sys.exit("error: typst not installed")
        self.root = root.resolve()
        self.font_path = font_path.resolve()
        self._tmp = tempfile.TemporaryDirectory()
        self.out = Path(self._tmp.name)
        self.failed = 0
        self._n = 0

    def report(self, name: str, ok: bool, detail: str = "") -> bool:
        if ok:
            print(f"ok    {name}")
        else:
            print(f"FAIL  {name}" + (f": {detail}" if detail else ""))
            self.failed += 1
        return ok

    def compile(self, src: str | Path, *args: str, fmt: str = "pdf", ppi: int | None = None,
                pages: str | None = None) -> tuple[subprocess.CompletedProcess[str], Path]:
        """Run typst compile; the output is a fresh file in the suite's temporary directory."""
        self._n += 1
        out = self.out / (f"{self._n}.pdf" if fmt == "pdf" else f"{self._n}-{{p}}.png")
        cmd = [self.typst, "compile", "--root", str(self.root), "--font-path", str(self.font_path),
               "--ignore-system-fonts", *args]
        if fmt != "pdf":
            cmd += ["--format", fmt]
        if ppi is not None:
            cmd += ["--ppi", str(ppi)]
        if pages is not None:
            cmd += ["--pages", pages]
        cmd += [str(src), str(out)]
        run = subprocess.run(cmd, capture_output=True, text=True, timeout=TIMEOUT, cwd=self.root)
        return run, out

    def passes(self, src: str | Path, *args: str) -> Path | None:
        """Must compile with no errors and no warnings; returns the PDF."""
        run, out = self.compile(src, *args)
        name = " ".join([str(src), *args])
        clean = run.returncode == 0 and not run.stderr.strip()
        self.report(name, clean, "expected a clean build\n" + run.stderr)
        return out if clean else None

    def rejects(self, src: str | Path, message: str) -> None:
        """Must fail to compile with `message` in the error."""
        run, _ = self.compile(src)
        if run.returncode == 0:
            self.report(str(src), False, f"expected failure: {message}")
        else:
            self.report(str(src), message in run.stderr, f"wrong error, wanted {message!r}\n{run.stderr}")

    def pdf(self, src: str | Path, *args: str) -> Path:
        """Compile and return the PDF, stopping the suite if the build fails."""
        run, out = self.compile(src, *args)
        if run.returncode != 0:
            sys.exit(f"error: {src} did not build\n{run.stderr}")
        return out

    def png(self, src: str | Path, page: int, ppi: int, *args: str) -> Image.Image:
        """Render one page with typst itself and return it as an RGB image."""
        run, out = self.compile(src, *args, fmt="png", ppi=ppi, pages=str(page))
        if run.returncode != 0:
            sys.exit(f"error: {src} did not render\n{run.stderr}")
        files = sorted(self.out.glob(out.name.replace("{p}", "*")))
        if len(files) != 1:
            sys.exit(f"error: expected one PNG for page {page} of {src}, got {len(files)}")
        return Image.open(files[0]).convert("RGB")

    def done(self) -> int:
        self._tmp.cleanup()
        return 1 if self.failed else 0


def pages(pdf: Path) -> int:
    return len(PdfReader(pdf).pages)


def text(pdf: Path, page: int | None = None) -> str:
    """Extracted text of one page (1-based) or the whole document."""
    reader = PdfReader(pdf)
    chosen = reader.pages if page is None else [reader.pages[page - 1]]
    return "\n".join(p.extract_text() for p in chosen)


def lines(pdf: Path, page: int | None = None) -> list[str]:
    """Text lines with runs of whitespace collapsed to one space."""
    return [re.sub(r"\s+", " ", ln).strip() for ln in text(pdf, page).splitlines() if ln.strip()]


def squeezed(pdf: Path, page: int | None = None) -> str:
    """Text with all whitespace removed, for letter-spaced labels that extract as "F I G U R E"."""
    return re.sub(r"\s+", "", text(pdf, page))


def words(pdf: Path, page: int) -> list[tuple[str, float, float]]:
    """(text, x, y) for each text run on a page, in PDF points from the bottom left."""
    found: list[tuple[str, float, float]] = []

    def visit(t: str, cm: list[float], tm: list[float], _font: object, _size: float) -> None:
        if t.strip():
            x = tm[4] * cm[0] + tm[5] * cm[2] + cm[4]
            y = tm[4] * cm[1] + tm[5] * cm[3] + cm[5]
            found.append((t.strip(), x, y))

    PdfReader(pdf).pages[page - 1].extract_text(visitor_text=visit)
    return found


def page_width(pdf: Path, page: int) -> float:
    return float(PdfReader(pdf).pages[page - 1].mediabox.width)


def _times(m: list[float], n: list[float]) -> list[float]:
    """PDF matrix product m × n, as cm composes onto the current transformation."""
    a, b, c, d, e, f = m
    a2, b2, c2, d2, e2, f2 = n
    return [a * a2 + b * c2, a * b2 + b * d2, c * a2 + d * c2, c * b2 + d * d2,
            e * a2 + f * c2 + e2, e * b2 + f * d2 + f2]


def strokes(pdf: Path, page: int) -> list[tuple[float, tuple[float, ...], float]]:
    """(line width, stroke colour components, y of the path's origin in points from the bottom)
    for every stroked path on a page."""
    reader = PdfReader(pdf)
    ops = ContentStream(reader.pages[page - 1].get_contents(), reader).operations
    width, colour, ctm, stack, out = 1.0, (0.0,), [1.0, 0.0, 0.0, 1.0, 0.0, 0.0], [], []
    for args, op in ops:
        if op == b"q":
            stack.append((width, colour, ctm))
        elif op == b"Q" and stack:
            width, colour, ctm = stack.pop()
        elif op == b"cm":
            ctm = _times([float(a) for a in args], ctm)
        elif op == b"w":
            width = float(args[0])
        elif op in (b"SC", b"SCN", b"RG", b"G"):
            colour = tuple(float(a) for a in args if not str(a).startswith("/"))
        elif op in (b"S", b"s", b"B", b"b", b"B*", b"b*"):
            out.append((width, colour, ctm[5]))
    return out


def page_height(pdf: Path, page: int) -> float:
    return float(PdfReader(pdf).pages[page - 1].mediabox.height)


CM = 72 / 2.54  # points per centimetre


def fonts(pdf: Path) -> set[str]:
    """Base names of the fonts embedded in a PDF, subset prefixes removed."""
    names: set[str] = set()
    for p in PdfReader(pdf).pages:
        res = p.get("/Resources")
        if res is None:
            continue
        for ref in (res.get_object().get("/Font") or {}).values():
            base = str(ref.get_object().get("/BaseFont", ""))
            names.add(re.sub(r"^/?([A-Z]{6}\+)?", "", base))
    return names


def red_pixels(img: Image.Image) -> list[tuple[int, int]]:
    w, h = img.size
    px = img.load()
    return [(x, y) for y in range(h) for x in range(w) if (c := px[x, y])[0] > 200 and c[1] < 60 and c[2] < 60]


def logo_centring(img: Image.Image) -> tuple[int, int]:
    """Height of a red logo and its offset, in half pixels, from the first glyph left of it.

    The glyph (the P of "Prepared") runs cap height to baseline, so equal centres mean the
    logo sits on the cap-height midline.
    """
    w, h = img.size
    px = img.load()
    red = red_pixels(img)
    if not red:
        raise ValueError("no red logo found")
    top, bottom = min(y for _, y in red), max(y for _, y in red)
    left = min(x for x, _ in red)

    def ink(x: int, y: int) -> bool:
        return sum(px[x, y]) < 3 * 128

    columns = [x for x in range(left) if any(ink(x, y) for y in range(h))]
    if not columns:
        raise ValueError("no text left of the logo")
    stem = range(columns[0], columns[0] + 3)
    rows = [y for y in range(h) if any(ink(x, y) for x in stem)]
    return bottom - top + 1, abs((top + bottom) - (min(rows) + max(rows)))

// Proxima tokens for print. Alpha tokens are flattened onto their ground so fills stay opaque in PDF.

#let _lin(v) = if v <= 0.04045 { v / 12.92 } else { calc.pow((v + 0.055) / 1.055, 2.4) }

/// WCAG 2 relative luminance of a colour.
#let luminance(col) = {
  let (r, g, b, ..) = rgb(col).components(alpha: false).map(v => _lin(v / 100%))
  0.2126 * r + 0.7152 * g + 0.0722 * b
}

/// WCAG 2 contrast ratio between two colours, 1 to 21.
#let contrast(a, b) = {
  let (hi, lo) = (luminance(a), luminance(b)).sorted().rev()
  (hi + 0.05) / (lo + 0.05)
}

#let _over(fg, alpha, ground) = color.mix((fg, alpha * 100%), (ground, (1 - alpha) * 100%), space: rgb)

// Pull a text colour toward `ink` in 10% steps until it reaches 4.5:1 on `bg`.
#let _legible(text, bg, ink) = {
  let c = text
  for step in range(1, 11) {
    if contrast(c, bg) >= 4.5 { break }
    c = color.mix((text, 100% - step * 10%), (ink, step * 10%), space: rgb)
  }
  c
}

#let accents = (
  indigo: (
    light: (accent: rgb("#5757D9"), deep: rgb("#4343C4"), ink: rgb("#FFFFFF"), charts: (rgb("#5050D6"), rgb("#1F8A63"), rgb("#8A6200"), rgb("#D23B72"), rgb("#2380BC"))),
    dark: (accent: rgb("#8D8DF5"), deep: rgb("#5757D9"), ink: rgb("#0B0B1C"), charts: (rgb("#6A6AE8"), rgb("#2FA97C"), rgb("#B8831F"), rgb("#D95C6E"), rgb("#3E9CD6"))),
  ),
  teal: (
    light: (accent: rgb("#12837C"), deep: rgb("#0C6A64"), ink: rgb("#FFFFFF"), charts: (rgb("#0793A2"), rgb("#5050D6"), rgb("#8A6200"), rgb("#D23B72"), rgb("#2380BC"))),
    dark: (accent: rgb("#5FD3C8"), deep: rgb("#2B9E95"), ink: rgb("#04211E"), charts: (rgb("#0FA0AF"), rgb("#6A6AE8"), rgb("#B8831F"), rgb("#D95C6E"), rgb("#3E9CD6"))),
  ),
  ember: (
    light: (accent: rgb("#B05808"), deep: rgb("#8F4508"), ink: rgb("#FFFFFF"), charts: (rgb("#A44F0E"), rgb("#1F8A63"), rgb("#5050D6"), rgb("#D23B72"), rgb("#2380BC"))),
    dark: (accent: rgb("#F2A566"), deep: rgb("#CE7627"), ink: rgb("#2A1404"), charts: (rgb("#C0641F"), rgb("#2FA97C"), rgb("#6A6AE8"), rgb("#D95C6E"), rgb("#3E9CD6"))),
  ),
  lime: (
    light: (accent: rgb("#66790A"), deep: rgb("#525F00"), ink: rgb("#FFFFFF"), charts: (rgb("#66790A"), rgb("#5050D6"), rgb("#8A6200"), rgb("#D23B72"), rgb("#2380BC"))),
    dark: (accent: rgb("#CFE763"), deep: rgb("#9DBB2E"), ink: rgb("#1D2404"), charts: (rgb("#8C9F2B"), rgb("#6A6AE8"), rgb("#B8831F"), rgb("#D95C6E"), rgb("#3E9CD6"))),
  ),
)

/// First candidate that reaches 4.5:1 against every ground.
#let pick-link(candidates, grounds) = {
  let ok = candidates.filter(c => grounds.all(g => contrast(c, g) >= 4.5))
  assert(ok.len() > 0, message: "centauri: no link colour reaches 4.5:1 on this palette")
  ok.first()
}

#let _light(a) = {
  let paper = rgb("#FFFFFF")
  let cover = rgb("#EDEEF6")
  let ink-hi = rgb("#1B1D2E")
  let state(text, fill, fill-alpha, line-alpha) = {
    let f = _over(fill, fill-alpha, paper)
    (text: _legible(text, f, ink-hi), fill: f, line: _over(text, line-alpha, paper))
  }
  (
    mode: "light",
    paper: paper,
    cover: cover,
    panel: rgb("#F7F8FC"),
    ink-hi: ink-hi,
    ink-mid: rgb("#4E5270"),
    ink-low: rgb("#9094B0"),
    hairline: _over(ink-hi, 0.14, paper),
    hairline-soft: _over(ink-hi, 0.07, paper),
    accent: a.accent,
    accent-deep: a.deep,
    accent-ink: a.ink,
    accent-fill: _over(a.accent, 0.12, paper),
    link: pick-link((a.accent, a.deep, ink-hi), (paper, cover)),
    mint: state(rgb("#0F8A5C"), rgb(62, 199, 138), 0.16, 0.3),
    amber: state(rgb("#8F6400"), rgb(245, 201, 81), 0.24, 0.3),
    rose: state(rgb("#C43552"), rgb(248, 113, 133), 0.15, 0.3),
    sky: state(rgb("#1272AE"), rgb(110, 198, 245), 0.2, 0.3),
    charts: a.charts,
  )
}

#let _dark(a) = {
  let paper = rgb("#0A0B12")
  let white = rgb("#FFFFFF")
  let state(text, fill, fill-alpha, line-alpha) = {
    let f = _over(fill, fill-alpha, paper)
    (text: _legible(text, f, white), fill: f, line: _over(text, line-alpha, paper))
  }
  (
    mode: "dark",
    paper: paper,
    cover: paper,
    panel: rgb("#12141F"),
    ink-hi: rgb("#EFF0F8"),
    ink-mid: rgb("#A9ADC7"),
    ink-low: rgb("#666B8A"),
    hairline: _over(white, 0.14, paper),
    hairline-soft: _over(white, 0.08, paper),
    accent: a.accent,
    accent-deep: a.deep,
    accent-ink: a.ink,
    accent-fill: _over(a.accent, 0.12, paper),
    link: pick-link((a.accent, rgb("#EFF0F8")), (paper,)),
    mint: state(rgb("#5EDBA6"), rgb(62, 199, 138), 0.13, 0.28),
    amber: state(rgb("#F5C951"), rgb(245, 201, 81), 0.12, 0.26),
    rose: state(rgb("#F8929F"), rgb(248, 113, 133), 0.13, 0.3),
    sky: state(rgb("#6EC6F5"), rgb(110, 198, 245), 0.12, 0.26),
    charts: a.charts,
  )
}

/// Build a theme. Override any key by adding a dictionary: `theme() + (radius: ...)`.
#let theme(accent: "indigo") = {
  assert(accent in accents, message: "centauri: accent must be one of " + accents.keys().join(", "))
  let a = accents.at(accent)
  (
    accent: accent,
    light: _light(a.light),
    dark: _dark(a.dark),
    fonts: (
      sans: ("Outfit",),
      serif: ("Instrument Serif",),
      mono: ("IBM Plex Mono", "DejaVu Sans Mono"),
    ),
    weight: (body: 380, h1: 480, h2: 520, h3: 540, strong: 560, kpi: 490),
    size: (body: 10pt, small: 8.5pt, label: 7pt, h1: 20pt, h2: 13pt, h3: 10.5pt, cover: 32pt, kpi: 22pt, watermark: 110pt),
    radius: (s: 6pt, m: 9pt, l: 13.5pt, full: 999pt),
  )
}

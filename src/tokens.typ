// Centauri tokens. Shared values come from tokens.toml, vendored from Proxima by
// scripts/sync-tokens.py. Print-only decisions (flattened alpha, hairlines, sizes)
// live here. Alpha tokens are flattened onto their ground so fills stay opaque in PDF.

#let shared = toml("tokens.toml")
#let phi = shared.scale.phi

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

/// Accent names available to `theme`, in token order.
#let accents = shared.accent

/// First candidate that reaches 4.5:1 against every ground.
#let pick-link(candidates, grounds) = {
  let ok = candidates.filter(c => grounds.all(g => contrast(c, g) >= 4.5))
  assert(ok.len() > 0, message: "centauri: no link colour reaches 4.5:1 on this palette")
  ok.first()
}

#let _states(mode, paper, ink) = {
  let out = (:)
  for (name, s) in shared.state.at(mode) {
    let fill = _over(rgb(s.base), s.fill, paper)
    out.insert(name, (text: _legible(rgb(s.text), fill, ink), fill: fill, line: _over(rgb(s.text), s.line, paper)))
  }
  out
}

// Tonal ramp for an accent, 50 (lightest) to 950 (darkest), built in OKLCH from the
// light-mode accent so hue stays constant. Keys are strings: ramp.at("700").
#let _steps = (
  ("50", 0.97, 0.15), ("100", 0.94, 0.25), ("200", 0.88, 0.45), ("300", 0.80, 0.70),
  ("400", 0.71, 0.90), ("500", 0.62, 1.00), ("600", 0.54, 1.00), ("700", 0.46, 0.90),
  ("800", 0.37, 0.75), ("900", 0.28, 0.60), ("950", 0.20, 0.50),
)
#let ramp(hex) = {
  let (_, c, h, ..) = oklch(rgb(hex)).components()
  let out = (:)
  for (k, l, cf) in _steps { out.insert(k, rgb(oklch(l * 100%, c * cf, h))) }
  out
}

/// Whichever of the two inks reads better on `ground`.
#let ink-on(ground, dark: rgb("#1B1D2E"), light: rgb("#EFF0F8")) = if contrast(dark, ground) >= contrast(light, ground) { dark } else { light }

#let _accent(a, paper) = (
  accent: rgb(a.accent),
  accent-deep: rgb(a.deep),
  accent-ink: rgb(a.ink),
  accent-fill: _over(rgb(a.accent), 0.12, paper),
  charts: a.charts.map(rgb),
)

#let _light(a) = {
  let n = shared.neutral.light
  let paper = rgb(n.panel_2)
  let cover = rgb(n.void)
  let ink-hi = rgb(n.ink_hi)
  let acc = _accent(a, paper)
  (
    mode: "light",
    paper: paper,
    cover: cover,
    panel: rgb(n.panel),
    ink-hi: ink-hi,
    ink-mid: rgb(n.ink_mid),
    ink-low: rgb(n.ink_low),
    hairline: _over(ink-hi, 0.14, paper),
    hairline-soft: _over(ink-hi, 0.07, paper),
    link: pick-link((acc.accent, acc.accent-deep, ink-hi), (paper, cover)),
    chart-neutral: rgb(shared.chart.neutral.light),
  ) + acc + _states("light", paper, ink-hi)
}

#let _dark(a) = {
  let n = shared.neutral.dark
  let paper = rgb(n.void)
  let white = rgb("#FFFFFF")
  let ink-hi = rgb(n.ink_hi)
  let acc = _accent(a, paper)
  (
    mode: "dark",
    paper: paper,
    cover: paper,
    panel: rgb(n.panel),
    ink-hi: ink-hi,
    ink-mid: rgb(n.ink_mid),
    ink-low: rgb(n.ink_low),
    hairline: _over(white, 0.14, paper),
    hairline-soft: _over(white, 0.08, paper),
    link: pick-link((acc.accent, ink-hi), (paper,)),
    chart-neutral: rgb(shared.chart.neutral.dark),
  ) + acc + _states("dark", paper, white)
}

/// Heading sizes: size(hN) = body * phi ^ ((6 - N) / k), so h6 == body.
/// `small` and `label` step down from body by one and two heading steps.
/// `display` is h1 * phi, for covers and title slides.
#let scale(body, k) = {
  let step = calc.pow(phi, 1 / k)
  let h(n) = body * calc.pow(step, 6 - n)
  (
    body: body,
    small: body / step,
    label: body / calc.pow(step, 2),
    h1: h(1), h2: h(2), h3: h(3), h4: h(4), h5: h(5), h6: h(6),
    display: h(1) * phi,
    kpi: h(1),
  )
}

/// Build a theme. Override any key by adding a dictionary: `theme() + (radius: ...)`.
/// `accent` is the default; every accent is built so documents, pages and covers can switch.
/// `scales.document` (10pt, k = 3) sets documents; `scales.deck` (16pt, k = 2) sets slides.
#let theme(accent: "indigo", document: (body: 10pt, k: 3), deck: (body: 18pt, k: 2)) = {
  assert(accent in accents, message: "centauri: accent must be one of " + accents.keys().join(", "))
  let palettes = (:)
  for (name, a) in accents {
    palettes.insert(name, (
      light: _light(a.light) + (accent-name: name, ramp: ramp(a.light.accent)),
      dark: _dark(a.dark) + (accent-name: name, ramp: ramp(a.light.accent)),
    ))
  }
  (
    accent: accent,
    palettes: palettes,
    light: palettes.at(accent).light,
    dark: palettes.at(accent).dark,
    // Print faces, Centauri's own, all OFL-1.1: Atkinson Hyperlegible Next and Mono
    // (Braille Institute) for text and code, Newsreader for quotations.
    fonts: (
      sans: ("Atkinson Hyperlegible Next",),
      serif: ("Newsreader 16pt",),
      mono: ("Atkinson Hyperlegible Mono", "DejaVu Sans Mono"),
    ),
    // Weight falls as size rises: large type is set light, small headings carry the weight.
    weight: (body: 400, strong: 650, h1: 500, h2: 540, h3: 580, h4: 620, h5: 660, h6: 700, kpi: 600, label: 500),
    deck-weight: (display: 300, h1: 320, h2: 360, h3: 420, h4: 480, h5: 560, h6: 650),
    scales: (
      document: scale(document.body, document.k) + (watermark: 110pt),
      deck: scale(deck.body, deck.k) + (watermark: 110pt),
    ),
    radius: (s: 6pt, m: 9pt, l: 13.5pt, full: 999pt),
  )
}

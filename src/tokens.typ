// Colour and scale utilities. Theme-free: they take colours and lengths, so any theme,
// Centauri's or a brand's, can build its palette with them.

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

/// `fg` at `alpha` (0 to 1) over `ground`, flattened so fills stay opaque in PDF.
#let over(fg, alpha, ground) = color.mix((fg, alpha * 100%), (ground, (1 - alpha) * 100%), space: rgb)

/// Pull a text colour toward `ink` in 10% steps until it reaches 4.5:1 on `bg`.
#let legible(text, bg, ink) = {
  let c = text
  for step in range(1, 11) {
    if contrast(c, bg) >= 4.5 { break }
    c = color.mix((text, 100% - step * 10%), (ink, step * 10%), space: rgb)
  }
  c
}

/// First candidate that reaches 4.5:1 against every ground.
#let pick-link(candidates, grounds) = {
  let ok = candidates.filter(c => grounds.all(g => contrast(c, g) >= 4.5))
  assert(ok.len() > 0, message: "centauri: no link colour reaches 4.5:1 on this palette")
  ok.first()
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

/// Heading sizes: size(hN) = body * ratio ^ ((6 - N) / k), so h6 == body.
/// `small` and `label` step down from body by one and two heading steps.
/// `display` is h1 * ratio, for covers and title slides.
#let scale(body, k, ratio) = {
  let step = calc.pow(ratio, 1 / k)
  let h(n) = body * calc.pow(step, 6 - n)
  (
    body: body,
    small: body / step,
    label: body / calc.pow(step, 2),
    h1: h(1), h2: h(2), h3: h(3), h4: h(4), h5: h(5), h6: h(6),
    display: h(1) * ratio,
    kpi: h(1),
  )
}

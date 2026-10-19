// Lafayette O'Reilly Logistics (LOL): an invented company from the AI training track, used
// here as a complete brand package on Centauri. It is the example to copy and the fixture
// that `examples/lol/run.py` tests. A real brand package imports "@preview/centauri:0.4.1"
// instead of the checkout.

#import "/lib.typ": *

/// LOL's colours: harbour navy for ink and covers, container orange for the accent.
#let colours = (
  navy: rgb("#13294B"),
  navy-deep: rgb("#0B1A33"),
  orange: rgb("#E8590C"),
  orange-deep: rgb("#B8460A"),
  sand: rgb("#F6F1E9"),
  steel: rgb("#5B6B82"),
  mist: rgb("#D9DEE6"),
)

/// The LOL wordmark, drawn in Typst: "LOL" in a navy box with an orange container block.
/// On a dark ground the box turns white and the letters navy.
#let logo(height: 0.6cm, tone: auto) = context {
  let dark = (if tone == auto { theme-now().tone } else { tone }) == "dark"
  let (ground, ink) = if dark { (white, colours.navy) } else { (colours.navy, white) }
  box(height: height, baseline: 20%, stack(dir: ltr, spacing: height * 0.12,
    box(height: height, inset: (x: height * 0.22), fill: ground, radius: height * 0.08,
      align(horizon, text(font: "Outfit", weight: 800, size: height * 0.62, tracking: 0.04em, fill: ink)[LOL])),
    box(width: height * 0.42, height: height, fill: colours.orange, radius: height * 0.08),
  ))
}

#let _h1(it) = {
  let t = theme-now()
  let num = heading-number(it)
  block(above: 1.8em, below: 1em, sticky: true, grid(
    columns: (4pt, 1fr), column-gutter: 10pt,
    rect(width: 4pt, height: t.sizes.h1 * 1.25, fill: t.colors.accent),
    {
      if num != none { label-text(num, fill: t.colors.accent-deep); linebreak() }
      text(font: t.fonts.heading, size: t.sizes.h1, fill: t.colors.ink-hi, it.body)
    },
  ))
}

#let _h2(it) = {
  let t = theme-now()
  let num = heading-number(it)
  block(above: 1.5em, below: 0.7em, sticky: true, text(font: t.fonts.heading, size: t.sizes.h2, fill: t.colors.ink-hi)[
    #if num != none [#text(fill: t.colors.accent-deep, num) ]#it.body
  ])
}

// Quotations hang from an orange rule, in the heading face.
#let _quote(it) = {
  let t = theme-now()
  block(above: 1.4em, below: 1.4em, inset: (left: 14pt), stroke: (left: 3pt + t.colors.accent),
    text(font: t.fonts.quote, size: t.sizes.h4, fill: t.colors.ink-hi, it.body))
}

// Cover backdrop: three containers stacked at the top right, clear of the title and meta.
#let _containers() = {
  let t = theme-now()
  let row(n, w, fill) = stack(dir: ltr, spacing: 4pt, ..range(n).map(_ => rect(width: w, height: 1.6cm, fill: fill)))
  place(top + right, dx: -2.2cm, dy: 2.6cm, stack(spacing: 4pt,
    align(right, row(1, 3.4cm, t.colors.accent)),
    row(2, 3.4cm, t.colors.ink-low),
  ))
}

#let _page-folio() = context {
  let t = theme-now()
  text(font: t.fonts.label, size: t.sizes.label + 0.5pt)[Page #counter(page).get().first() of #counter(page).final().first()]
}

#let _sensitivity() = context text(font: theme-now().fonts.label, size: theme-now().sizes.label + 0.5pt, theme-now().sensitivity)

/// Furniture arrangements. `masthead` (the theme's own) carries the logo and sensitivity in the
/// header; `ledger` keeps the page top clear and puts everything in the footer.
#let presets = (
  masthead: (
    header: (left: () => logo(height: 0.45cm), center: none, right: _sensitivity),
    footer: (left: none, center: none, right: _page-folio),
    header-rule: auto, footer-rule: none,
  ),
  ledger: (
    header: (left: none, center: none, right: none),
    footer: (left: () => logo(height: 0.35cm), center: _sensitivity, right: _page-folio),
    header-rule: none, footer-rule: auto,
  ),
)

/// LOL's theme: Centauri's, with LOL's colours, faces, headings, furniture, data classes and words.
#let lol-theme = extend(centauri-theme, (
  colors: (
    light: (
      paper: white, cover: colours.sand, panel: colours.sand,
      ink-hi: colours.navy, ink-mid: colours.navy, ink-low: colours.steel,
      hairline: colours.mist, hairline-soft: colours.mist,
      accent: colours.orange, accent-deep: colours.orange-deep, accent-ink: white,
      accent-fill: over(colours.orange, 0.12, white), link: colours.navy,
      charts: (colours.navy, colours.orange, colours.steel, colours.orange-deep, colours.mist),
      ramp: ramp(colours.orange), chart-neutral: colours.mist,
    ),
    dark: (
      paper: colours.navy-deep, cover: colours.navy, panel: colours.navy-deep,
      ink-hi: white, ink-mid: colours.mist, ink-low: rgb("#9AA7BA"),
      hairline: colours.steel, hairline-soft: colours.steel,
      accent: colours.orange, accent-deep: rgb("#FF8A4C"), accent-ink: colours.navy-deep,
      accent-fill: over(colours.orange, 0.2, colours.navy-deep), link: white,
      charts: (white, colours.orange, colours.mist, rgb("#FF8A4C"), colours.steel),
      ramp: ramp(colours.orange), chart-neutral: colours.steel,
    ),
  ),
  // One set of colours: LOL has no accent switching.
  accents: none,
  fonts: (
    body: ("Outfit",),
    heading: ("Instrument Serif",),
    label: ("IBM Plex Mono",),
    code: ("IBM Plex Mono",),
    quote: ("Instrument Serif",),
  ),
  type: (document: (body: 10.5pt)),
  strokes: (emphasis: 3pt),
  page: (left: 2.2cm, right: 2.2cm, header-line: 1.6cm, header-gap: 0.8cm),
  h1: _h1,
  h2: _h2,
  elements: (quote: _quote, backdrop: _containers),
  furniture: presets.masthead,
  // The five data classes in LOL's AI policy.
  sensitivity: (
    default: "LOL Internal",
    levels: ("LOL Public", "LOL Internal", "LOL Confidential", "LOL Highly Confidential", "LOL Restricted"),
  ),
  words: (contents: [What's inside], annex: "Schedule", draft: "LOL DRAFT", drafting-note: [Ops note.]),
  label-case: "as-written",
))

/// The LOL document template: `#show: lol.with(title: ...)`.
#let lol = centauri.with(theme: lol-theme)

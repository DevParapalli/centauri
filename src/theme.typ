// Centauri's own theme. Colours come from tokens.toml, vendored from Proxima by
// scripts/sync-tokens.py; everything else is Centauri's print decisions. A brand overrides
// any part of it with `extend` (src/schema.typ). Alpha tokens are flattened onto their
// ground so fills stay opaque in PDF.

#import "tokens.typ": contrast, over, legible, pick-link, ramp
#import "runtime.typ": theme-now, heading-number, at-page-top, label-text, folio

#let _shared = toml("tokens.toml")

// Proxima names its states after colours; the theme names them after what they mean.
#let _state-names = (success: "mint", caution: "amber", danger: "rose", info: "sky")

#let _states(mode, paper, ink) = {
  let out = (:)
  for (name, token) in _state-names {
    let s = _shared.state.at(mode).at(token)
    let fill = over(rgb(s.base), s.fill, paper)
    out.insert(name, (text: legible(rgb(s.text), fill, ink), fill: fill, line: over(rgb(s.text), s.line, paper)))
  }
  out
}

// The keys an accent sets on top of the theme's colours.
#let _accent-keys(a, light-accent, paper, grounds, candidates) = {
  let acc = rgb(a.accent)
  (
    accent: acc,
    accent-deep: rgb(a.deep),
    accent-ink: rgb(a.ink),
    accent-fill: over(acc, 0.12, paper),
    charts: a.charts.map(rgb),
    ramp: ramp(light-accent),
    link: pick-link(candidates(acc, rgb(a.deep)), grounds),
  )
}

#let _light-neutrals = {
  let n = _shared.neutral.light
  let paper = rgb(n.panel_2)
  let ink-hi = rgb(n.ink_hi)
  (
    paper: paper,
    cover: rgb(n.void),
    panel: rgb(n.panel),
    ink-hi: ink-hi,
    ink-mid: rgb(n.ink_mid),
    ink-low: rgb(n.ink_low),
    hairline: over(ink-hi, 0.14, paper),
    hairline-soft: over(ink-hi, 0.07, paper),
    chart-neutral: rgb(_shared.chart.neutral.light),
  ) + _states("light", paper, ink-hi)
}

#let _dark-neutrals = {
  let n = _shared.neutral.dark
  let paper = rgb(n.void)
  let white = rgb("#FFFFFF")
  (
    paper: paper,
    cover: paper,
    panel: rgb(n.panel),
    ink-hi: rgb(n.ink_hi),
    ink-mid: rgb(n.ink_mid),
    ink-low: rgb(n.ink_low),
    hairline: over(white, 0.14, paper),
    hairline-soft: over(white, 0.08, paper),
    chart-neutral: rgb(_shared.chart.neutral.dark),
  ) + _states("dark", paper, white)
}

#let _accents = {
  let out = (:)
  for (name, a) in _shared.accent {
    let l = _light-neutrals
    let d = _dark-neutrals
    out.insert(name, (
      light: _accent-keys(a.light, a.light.accent, l.paper, (l.paper, l.cover), (acc, deep) => (acc, deep, l.ink-hi)),
      dark: _accent-keys(a.dark, a.light.accent, d.paper, (d.paper,), (acc, deep) => (acc, d.ink-hi)),
    ))
  }
  out
}

// Heading numbers inline beside the title, hung in the margin, or left out (`heading-numbers`).
#let _with-number(it, size, weight, fill, title) = {
  let t = theme-now()
  let num = heading-number(it)
  if num == none { return title }
  let n = text(size: size, weight: weight, fill: fill, number-width: "tabular", num)
  if t.heading-numbers == "hang" {
    let w = measure(n).width
    pad(left: -w - 0.55em, grid(columns: (w, 1fr), column-gutter: 0.55em, n, title))
  } else {
    grid(columns: (auto, 1fr), column-gutter: 0.5em, n, title)
  }
}

// Levels 2 to 6: plain headings, numbers in low ink at the heading's own size and weight.
#let _plain(level, above, below, tracking: 0em) = it => {
  let t = theme-now()
  let size = t.sizes.at("h" + str(level))
  let weight = t.type.weights.at("h" + str(level))
  block(above: above, below: below, sticky: true, _with-number(it, size, weight, t.colors.ink-low,
    text(font: t.fonts.heading, size: size, weight: weight, tracking: tracking, fill: t.colors.ink-hi, it.body)))
}

// A level 1 heading that opens a page is a banner across the page: a tinted band, number and
// title centred, an accent rule beneath. One that falls mid-page, or any level 1 heading in a
// multi-column layout, sits under a rule with its number beside it.
#let _h1(it) = {
  let t = theme-now()
  let q = t.colors
  let w = t.type.weights
  let title = text(font: t.fonts.heading, size: t.sizes.h1, weight: w.h1, tracking: -0.01em, fill: q.ink-hi, it.body)
  if t.columns == 1 and at-page-top() {
    let num = heading-number(it)
    block(width: 100%, above: 0pt, below: 1.8em, breakable: false, fill: color.mix((q.accent, 9%), (q.paper, 91%), space: rgb),
      outset: (left: t.page.left, right: t.page.right), inset: (y: 1.15cm),
      stroke: (bottom: t.strokes.emphasis + q.link),
      align(center, block(width: 76%, align(center, {
        if num != none [#text(size: t.sizes.h1, weight: w.body, fill: q.link, number-width: "tabular", num)#h(0.45em)]
        title
      }))))
  } else {
    block(above: 1.6em, below: 1.2em, width: 100%, {
      line(length: 100%, stroke: t.strokes.rule + q.ink-hi)
      v(0.5em)
      _with-number(it, t.sizes.h1, w.body, q.link, title)
    })
  }
}

// Block quotations are one of the two places the serif appears; the drop cap is the other.
#let _quote(it) = {
  let t = theme-now()
  let q = t.colors
  block(above: 1.3em, below: 1.3em, inset: (left: 12pt, y: 2pt), stroke: (left: t.strokes.emphasis + q.accent-deep), {
    text(font: t.fonts.quote, style: "italic", weight: 400, size: t.sizes.h5, tracking: 0.005em, fill: q.ink-hi, it.body)
    if it.attribution != none {
      v(0.3em)
      label-text(it.attribution)
    }
  })
}

#let _raw(it) = {
  let t = theme-now()
  block(width: 100%, fill: t.colors.panel, stroke: t.strokes.hairline + t.colors.hairline-soft, radius: t.radius.m, inset: 9pt, it)
}

#let _caption(it) = {
  let t = theme-now()
  block(width: 100%, align(left, text(size: t.sizes.small, fill: t.colors.ink-mid, {
    label-text([#it.supplement #it.counter.display(it.numbering)])
    h(0.7em)
    it.body
  })))
}

#let _footnote(it) = {
  set text(size: theme-now().sizes.small)
  it
}

// Cover backdrop: a radial bloom of the accent from the top left corner.
#let _bloom() = {
  let t = theme-now()
  let q = t.colors
  let k = if t.tone == "dark" { 24% } else { 16% }
  rect(width: 100%, height: 100%, fill: gradient.radial(
    color.mix((q.accent, k), (q.cover, 100% - k), space: rgb), q.cover, center: (8%, 4%), radius: 95%))
}

/// Centauri's theme. Override any part with `extend(centauri-theme, (...))`.
#let centauri-theme = (
  // Light and dark palettes in the indigo accent; `accents` holds the others for `use-accent`.
  colors: (
    light: _light-neutrals + _accents.indigo.light,
    dark: _dark-neutrals + _accents.indigo.dark,
  ),
  accents: _accents,
  // Print faces, Centauri's own, all OFL-1.1: Atkinson Hyperlegible Next and Mono
  // (Braille Institute) for text, labels and code, Newsreader for quotations.
  fonts: (
    body: ("Atkinson Hyperlegible Next",),
    heading: ("Atkinson Hyperlegible Next",),
    label: ("Atkinson Hyperlegible Mono", "DejaVu Sans Mono"),
    code: ("Atkinson Hyperlegible Mono", "DejaVu Sans Mono"),
    quote: ("Newsreader 16pt",),
  ),
  type: (
    document: (body: 10pt, k: 3),
    deck: (body: 18pt, k: 2),
    ratio: _shared.scale.phi,
    // Weight falls as size rises: large type is set light, small headings carry the weight.
    weights: (body: 400, strong: 650, h1: 500, h2: 540, h3: 580, h4: 620, h5: 660, h6: 700, kpi: 600, label: 500),
    deck-weights: (display: 300, h1: 320, h2: 360, h3: 420, h4: 480, h5: 560, h6: 650),
  ),
  strokes: (hairline: 0.5pt, rule: 0.75pt, emphasis: 1.5pt),
  // Distances from the paper's edges: the header line (its rule) sits `header-line` down and
  // the body starts `header-gap` below it; the footer line sits `footer-line` up and the body
  // ends `footer-gap` above it.
  page: (left: 2cm, right: 2cm, header-line: 1.75cm, header-gap: 0.95cm, footer-line: 1.5cm, footer-gap: 0.8cm),
  h1: _h1,
  h2: _plain(2, 1.8em, 0.8em, tracking: -0.01em),
  h3: _plain(3, 1.4em, 0.6em),
  h4: _plain(4, 1.2em, 0.55em),
  h5: _plain(5, 1.1em, 0.5em),
  h6: _plain(6, 1em, 0.45em),
  elements: (quote: _quote, raw: _raw, caption: _caption, footnote: _footnote, backdrop: _bloom),
  // Slots take content, none, or a function of no arguments called in context.
  furniture: (
    header: (left: none, center: none, right: none),
    footer: (left: none, center: folio, right: none),
    header-rule: auto,
    footer-rule: auto,
  ),
  // `levels`, when set, lists every sensitivity a document may use; any other stops the build.
  sensitivity: (default: none, levels: none),
  words: (
    contents: [Contents],
    draft: "DRAFT",
    annex: "Annex",
    drafting-note: [Drafting note.],
    no-entries: [No entries.],
    req: [Reference],
    status: (compliant: [Compliant], partial: [Partial], exception: [Exception], noted: [Noted]),
    registers: (
      assumption: (word: "Assumption", prefix: "A"),
      dependency: (word: "Dependency", prefix: "D"),
      decision: (word: "Decision", prefix: "DEC"),
      risk: (word: "Risk", prefix: "R"),
      issue: (word: "Issue", prefix: "I"),
    ),
    tables: (
      revision-history: ([Version], [Date], [Author], [Change]),
      request-list: ([No.], [Request], [Owner], [Needed by]),
      qa-table: ([No.], [Reference], [Question]),
      compliance-matrix: ([Ref], [Requirement], [Status], [Response]),
      register-table: ([ID], [Statement], [Page]),
    ),
    sig-block: ([Name], [Title], [Signature], [Date]),
    deck: (section: "Section", of: "of", slides: "slides", minutes: [minutes], expected-output: [Expected output], source: [Source:]),
  ),
  // Small labels (captions, key-value keys, table headers, register cards): "upper" sets
  // them in tracked capitals, "as-written" keeps the author's case for brands that avoid capitals.
  label-case: "upper",
  radius: (s: 6pt, m: 9pt, l: 13.5pt, full: 999pt),
)

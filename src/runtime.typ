// What a document is set with, held in state so components, theme functions and brand
// code all read it the same way: `theme-now()` inside `context`.

#import "tokens.typ": scale

/// Active page tone, "light" or "dark". Dark inside a dark cover.
#let tone = state("centauri-tone", "light")
/// Accent in force: none means the theme's own colours. Change it with `use-accent`.
#let _accent = state("centauri-accent", none)
// The theme and the document settings that theme functions read. `centauri` sets it at the
// start of the body and again in every page header, because a header is laid out before the
// body's first update and would otherwise see none on page 1.
#let _doc = state("centauri-doc", none)
#let _todos = counter("centauri-todo")

/// Palette for a tone and accent: the theme's colours with the accent's on top.
#let resolve-colors(t, tone, accent) = {
  let base = t.colors.at(tone)
  let over = if accent == none { (:) } else { t.accents.at(accent).at(tone) }
  base + over + (mode: tone, accent-name: accent)
}

/// Type sizes for "document" or "deck".
#let sizes(t, which) = {
  let s = t.type.at(which)
  scale(s.body, s.k, t.type.ratio) + (watermark: 110pt)
}

// Furniture in force on page `p`: the theme's, then every `furniture` call made on an earlier
// page, in order. A call takes effect on the page after the one it sits on.
#let furniture-on(t, p) = {
  let f = t.furniture + (sensitivity: t.sensitivity.default)
  for m in query(<centauri-furniture>) {
    if m.location().page() >= p { break }
    let c = m.value
    f = f + c + (header: f.header + c.at("header", default: (:)), footer: f.footer + c.at("footer", default: (:)))
  }
  f
}

/// The theme in force here, inside `context`: `colors` is resolved for the page's tone and
/// accent, and `tone`, `accent`, `stage`, `sensitivity`, `sizes`, `heading-numbers` and
/// `columns` describe this point in the document.
#let theme-now() = {
  let d = _doc.get()
  assert(d != none, message: "centauri: no theme in force; start the document with #show: centauri.with(...)")
  let t = d.theme
  let tn = tone.get()
  let a = _accent.get()
  t + (
    colors: resolve-colors(t, tn, a),
    tone: tn,
    accent: a,
    stage: d.stage,
    sensitivity: if d.size == "deck" { t.sensitivity.default } else { furniture-on(t, here().page()).sensitivity },
    sizes: sizes(t, d.size),
    heading-numbers: d.heading-numbers,
    columns: d.columns,
  )
}

/// Palette of the theme in force for another tone or accent, inside `context`.
#let palette(tone, accent) = resolve-colors(_doc.get().theme, tone, accent)

/// `fn(theme-now())` in context, for content that needs the theme.
#let themed(fn) = context fn(theme-now())

/// A heading's formatted number, or none when it has none or numbers are off.
#let heading-number(it) = {
  let d = _doc.get()
  if it.numbering == none or d.heading-numbers == "none" { return none }
  numbering(it.numbering, ..counter(heading).at(it.location()))
}

/// Whether this point is at the top of the page's body, as a heading that opens a page is.
#let at-page-top() = {
  let t = theme-now()
  here().position().y < (t.page.header-line + t.page.header-gap + 3pt).to-absolute()
}

/// Small label in the label face: tracked capitals, or as written, per `label-case`.
#let label-text(body, size: auto, fill: auto) = context {
  let t = theme-now()
  let upper-case = t.label-case == "upper"
  text(font: t.fonts.label, size: if size == auto { t.sizes.label } else { size },
    tracking: if upper-case { 0.12em } else { 0em }, weight: t.type.weights.label,
    fill: if fill == auto { t.colors.ink-mid } else { fill }, if upper-case { upper(body) } else { body })
}

/// Furniture slot: "n/N | sensitivity" in the label face.
#let folio() = context {
  let t = theme-now()
  text(font: t.fonts.label, size: t.sizes.label + 0.5pt, fill: t.colors.ink-mid)[
    #counter(page).display("1/1", both: true)#if t.sensitivity != none [ | #t.sensitivity]
  ]
}

/// Furniture slot: the level 1 heading in force on this page, with its number.
#let current-section() = context {
  let t = theme-now()
  let page = here().page()
  let sel = heading.where(level: 1)
  let on = query(sel).filter(h => h.location().page() == page)
  let hd = if on.len() > 0 { on.first() } else {
    let before = query(selector(sel).before(here()))
    if before.len() > 0 { before.last() } else { none }
  }
  if hd == none { return none }
  text(size: t.sizes.small, fill: t.colors.ink-mid, {
    if hd.numbering != none {
      text(font: t.fonts.label, numbering(hd.numbering, ..counter(heading).at(hd.location())))
      h(0.5em)
    }
    hd.body
  })
}

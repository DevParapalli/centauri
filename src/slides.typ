// Centauri decks: 16:9 and 4:3 slides on the same tokens and components as the
// documents. `centauri(kind: "deck")` switches to the deck scale (20pt body, k = 2).
//
// Design basis (see docs/deck-board.md): assertion–evidence content slides, one
// message per slide, minimal chrome (frame number and source line only), no
// textures or gradients, left-aligned text, one accent used for highlights.
//
// Output modes, chosen with `--input mode=...`:
//   slides  (default) one slide per page; a slide that overflows its page stops the build
//   handout A4 pages, two slides per page with their notes beneath
//   titles  A4 list of slide titles in order, for reviewing the argument ("ghost deck")

#import "make.typ": make, tone, _size, _accent
#import "tokens.typ": ink-on

#let _deck = state("centauri-deck", (projection: "light", accent: "indigo", label: none, date: none, presenter: none, aspect: "16:9", logos: (left: none, right: none), light: auto, bloom: true))
#let _slide-no = counter("centauri-slide")
#let _section = state("centauri-deck-section", none)
#let _slide-notes = state("centauri-slide-notes", none)

/// Page sizes follow the PowerPoint defaults so decks project and convert predictably.
#let aspects = ("16:9": (33.867cm, 19.05cm), "4:3": (25.4cm, 19.05cm))

#let make-kit(t) = {
  let base = make(t)
  let mono = t.fonts.mono
  let _tone = tone
  let pal = base.pal
  let palette = base.palette
  let S = base.size-now
  let mode = sys.inputs.at("mode", default: "slides")
  assert(mode in ("slides", "handout", "titles"), message: "centauri: mode must be slides, handout or titles")
  let margin = (x: 1.9cm, top: 2.1cm, bottom: 2.0cm)
  // Text measure shared by both aspects, so 4:3 and 16:9 set the same line lengths.
  let column = 24cm

  let W = t.deck-weight

  // Deterministic pseudo-random number in [0.12, 0.88] for slide n and channel k,
  // used to place the light source when a slide does not set one.
  let rand(n, k) = 0.12 + 0.76 * calc.fract(calc.abs(calc.sin(n * 12.9898 + k * 78.233)) * 43758.5453)

  // Grounds. Content slides: near-black with an accent bloom in dark projection,
  // off-white in light. Section slides: accent 500 in dark, accent 800 in light.
  // The bloom sits at the light source (x, y), each a ratio of the page from 0 to 1.
  let ground(q, kind) = {
    let r = q.ramp
    if kind == "section" {
      if q.mode == "dark" { (base: r.at("600"), glow: r.at("500"), strength: 70%, radius: 55%, ink: rgb("#FFFFFF")) }
      else { (base: r.at("800"), glow: r.at("600"), strength: 70%, radius: 55%, ink: auto) }
    } else {
      if q.mode == "dark" { (base: q.paper, glow: r.at("800"), strength: if kind == "cover" { 85% } else { 65% }, radius: if kind == "cover" { 60% } else { 48% }, ink: auto) }
      else { (base: q.panel, glow: r.at("100"), strength: if kind == "cover" { 90% } else { 60% }, radius: if kind == "cover" { 60% } else { 48% }, ink: auto) }
    }
  }

  let bloom-layer(g, light, on) = if on {
    place(top + left, rect(width: 100%, height: 100%, fill: gradient.radial(
      g.glow.transparentize(100% - g.strength), g.glow.transparentize(100%),
      center: (light.x * 100%, light.y * 100%), radius: g.radius, focal-radius: 0%)))
  }

  let frame-no(ink, n) = text(font: mono, size: S().label + 3pt, fill: ink, number-width: "tabular", if n < 10 { "0" + str(n) } else { str(n) })

  // Editorial frame: a hairline across the top with the deck name, section and date
  // above it, and a hairline low across the foot with the slide count and presenter
  // below it. Logos, when given, take the top left and top right slots.
  let frame(d, ink, rule, n, total, section, kind: "claim") = {
    let (w, h) = aspects.at(d.aspect)
    let meta(body) = text(size: S().label + 1pt, fill: ink, body)
    let row(y, l, c, r, inset: 0pt) = place(top + left, dx: margin.x + inset, dy: y, box(width: w - 2 * margin.x - 2 * inset,
      grid(columns: (1fr, 1fr, 1fr), align: (left + top, center + top, right + top), meta(l), meta(c), meta(r))))
    let count = [#(if n < 10 { "0" + str(n) } else { str(n) }) / #(if total < 10 { "0" + str(total) } else { str(total) })]
    row(0.65cm,
      if d.logos.left != none { box(height: 0.7cm, d.logos.left) } else { d.label },
      section,
      if d.logos.right != none { box(height: 0.7cm, d.logos.right) } else { d.date })
    place(top + left, dx: margin.x, dy: 1.3cm, line(length: w - 2 * margin.x, stroke: 0.5pt + rule))
    // Mirrors the top: rule 1.3cm from the edge, text row inside it.
    place(top + left, dx: margin.x, dy: h - 1.3cm, line(length: w - 2 * margin.x, stroke: 0.5pt + rule))
    // Footer text sits inset from the rule's ends. On cover slides the bottom right
    // stays empty so it never meets the large class numeral.
    row(h - 1.05cm, count, none, if kind != "cover" { d.presenter }, inset: 0.4cm)
  }

  // Plain text of a content value, for the headline lint.
  let plain(c) = if c == none { "" } else if type(c) == str { c } else if c.has("text") { c.text } else if c.has("children") { c.children.map(plain).join() } else if c.has("body") { plain(c.body) } else { "" }
  let lint-title(title) = {
    let p = plain(title).trim()
    if p.ends-with(".") { panic("centauri: slide title ends with a full stop: \"" + p + "\"") }
  }

  let deck(aspect: "16:9", projection: auto, tone: "light", accent: auto, label: none, title: none, author: (), lang: "en",
    date: none, presenter: none, logos: (left: none, right: none), light: auto, bloom: true, body) = {
    let projection = if projection == auto { tone } else { projection }
    assert(aspect in aspects, message: "centauri: aspect must be 16:9 or 4:3")
    assert(projection in ("light", "dark"), message: "centauri: projection must be light or dark")
    let accent = if accent == auto { t.accent } else { accent }
    assert(accent in t.palettes, message: "centauri: accent must be one of " + t.palettes.keys().join(", "))
    let (w, h) = aspects.at(aspect)
    let q = palette(accent, projection)
    let sz = t.scales.deck
    set document(title: title, author: author)
    set page(paper: "a4", margin: (x: 1.8cm, y: 1.6cm), fill: t.light.paper,
      footer: align(right, text(font: mono, size: 7pt, fill: t.light.ink-mid, context counter(page).display("1/1", both: true)))) if mode != "slides"
    set page(width: w, height: h, fill: ground(q, "claim").base, margin: margin, header: none, footer: none) if mode == "slides"
    set text(font: t.fonts.sans, size: sz.body, weight: if projection == "dark" { 380 } else { t.weight.body }, fill: q.ink-mid, lang: lang, number-type: "lining")
    set text(size: 10pt) if mode == "titles"
    set text(costs: (runt: 400%, widow: 200%, orphan: 200%))
    set par(leading: 0.62em, spacing: 1em)
    set strong(delta: t.weight.strong - t.weight.body)
    show strong: it => context text(fill: pal().ink-hi, it)
    set list(indent: 0em, body-indent: 0.6em, spacing: 0.8em, marker: context text(fill: pal().ink-low)[•])
    set enum(indent: 0em, body-indent: 0.6em, spacing: 0.8em)
    show link: it => context { set text(fill: pal().link); it }
    set raw(theme: base.code-themes.at(accent).at(projection))
    show raw: set text(font: mono, size: sz.small)
    show raw.where(block: true): it => context {
      let q = pal()
      set raw(theme: base.code-themes.at(q.accent-name).at(q.mode))
      block(width: 100%, fill: if q.mode == "light" { q.paper } else { q.panel.transparentize(20%) }, stroke: 0.5pt + q.hairline, radius: t.radius.m, inset: 14pt, it)
    }
    set table(stroke: (_, y) => (bottom: 0.5pt + q.hairline-soft), inset: (x: 8pt, y: 8pt))
    show table: set text(size: sz.small, number-width: "tabular")
    _size.update("deck")
    _tone.update(projection)
    _accent.update(accent)
    _deck.update((projection: projection, accent: accent, label: label, date: date, presenter: presenter, aspect: aspect, logos: logos, light: light, bloom: bloom))
    body
    // No auto-fit: a slide that runs onto a second page fails the build.
    if mode == "slides" {
      context {
        let starts = query(<centauri-slide-start>)
        let ends = query(<centauri-slide-end>)
        for (s, e) in starts.zip(ends) {
          if e.location().page() != s.location().page() {
            panic("centauri: slide " + str(s.value) + " overflows its page; cut the content or split the slide")
          }
        }
      }
    }
  }

  /// One entry point for every kind. `kind: "deck"` builds slides; any other kind a document.
  let centauri(kind: "report", aspect: "16:9", projection: auto, tone: "light", label: none, date: none, presenter: none, logos: (left: none, right: none), light: auto, bloom: true, ..args, body) = {
    if kind == "deck" {
      deck(aspect: aspect, projection: projection, tone: tone, label: label, date: date, presenter: presenter, logos: logos, light: light, bloom: bloom, ..args, body)
    } else {
      (base.centauri)(kind: kind, ..args, body)
    }
  }

  // Place one slide. `kind` and `title` feed the outline and the titles export.
  // `light` is the bloom's light source as (x: 0..1, y: 0..1); auto picks one per slide.
  let on-page(projection, accent, body, kind: "claim", title: none, source: none, chrome-on: true, light: auto) = {
    if title != none and kind not in ("statement", "quote") { lint-title(title) }
    _slide-no.step()
    // A section is identified by the frame number of its divider, so repeated titles stay distinct.
    if kind == "section" { context _section.update((title: title, n: _slide-no.get().first())) }
    context {
      let n = _slide-no.get().first()
      let d = _deck.get()
      let pj = if projection == auto { d.projection } else { projection }
      let a = if accent == auto { d.accent } else { accent }
      let q = palette(a, pj)
      let g = ground(q, kind)
      let lt = if light != auto { light } else if d.light != auto { d.light } else { (x: rand(n, 1), y: rand(n, 2)) }
      let sec = _section.get()
      let sec-title = if sec != none { sec.title }
      let ink = if kind == "section" { if g.ink == auto { ink-on(g.base) } else { g.ink } } else { q.ink-mid }
      let total = _slide-no.final().first()
      let fr = if chrome-on { frame(d, if kind == "section" { ink.transparentize(25%) } else { q.ink-low }, if kind == "section" { ink.transparentize(65%) } else { q.hairline }, n, total, if kind != "section" { sec-title }, kind: kind) }
      let meta = metadata((n: n, kind: kind, title: title, section: sec))
      let inner = {
        _tone.update(pj)
        _accent.update(a)
        set text(fill: q.ink-mid)
        body
        _tone.update(d.projection)
        _accent.update(d.accent)
      }
      let src = if source != none { place(bottom + left, dy: 0.35cm, text(size: S().label + 1pt, fill: q.ink-low)[Source: #source]) }
      if mode == "titles" {
        [#meta <centauri-slide>]
        if kind == "section" {
          block(above: 1.2em, below: 0.4em, text(weight: 650, fill: t.light.ink-hi, title))
        } else {
          grid(columns: (2.2em, 1fr), text(font: mono, fill: t.light.ink-low, str(n)),
            text(fill: t.light.ink-mid, if title != none { title } else { emph(kind) }))
        }
      } else if mode == "handout" {
        [#meta <centauri-slide>]
        let (w, h) = aspects.at(d.aspect)
        let fit = 17.4cm / w
        block(breakable: false, above: 0.6cm, below: 0.4cm, {
          scale(fit * 100%, reflow: true, origin: top + left,
            box(width: w, height: h, fill: g.base, stroke: 1pt + t.light.hairline, clip: true, {
              bloom-layer(g, lt, d.bloom)
              fr
              place(top + left, box(width: 100%, height: 100%, inset: margin, {
                _slide-notes.update(none)
                inner
                src
              }))
            }))
          context {
            let nt = _slide-notes.get()
            if nt != none { v(0.25cm); block(width: 100%, text(size: 9pt, fill: t.light.ink-mid, nt)) }
          }
        })
      } else {
        page(fill: g.base, background: { bloom-layer(g, lt, d.bloom); fr }, header: none, footer: none, {
          [#meta <centauri-slide>]
          [#metadata(n) <centauri-slide-start>]
          inner
          src
          [#metadata(n) <centauri-slide-end>]
        })
      }
    }
  }

  /// Accent-coloured emphasis for the words a title or statement turns on.
  // Emphasis inside text is carried by ink and weight. The accent is kept for grounds
  // and the emphasis line, because in Proxima an accent-coloured element reads as active.
  let hl(body) = context text(fill: pal().ink-hi, weight: t.weight.strong, body)

  let slide-title(q, body, size: auto) = block(width: column, below: 0.9em,
    text(size: if size == auto { S().h4 } else { size }, weight: W.h4, tracking: -0.012em, fill: q.ink-hi, par(leading: 0.42em, body)))

  // Emphasis line: a thick, round-ended accent line running from the cap height of the
  // first line to the baseline of the last. The other line type is the hairline divider.
  let emphasis(q, size, body, gap: 0.55em) = layout(bounds => {
    let set-text = text(size: size, top-edge: "cap-height", bottom-edge: "baseline", body)
    let thick = size * 0.11
    let m = measure(block(width: bounds.width - thick - gap.to-absolute(), set-text))
    grid(columns: (thick, 1fr), column-gutter: gap,
      rect(width: thick, height: m.height, radius: thick / 2, fill: q.link), set-text)
  })

  // Proxima primitives, restated for slides.
  let index-line(ink, rule, n, label) = grid(columns: (auto, 1fr, auto), column-gutter: 14pt, align: horizon,
    text(weight: 650, fill: ink, number-width: "tabular", n), line(length: 100%, stroke: 0.75pt + rule), text(fill: ink, label))
  let chip(ink, rule, body) = box(inset: (x: 10pt, y: 5pt), radius: t.radius.s, stroke: 0.75pt + rule,
    text(font: mono, size: S().label + 2pt, fill: ink, body))
  // Tonal tile: a solid card one or two steps off the ground, from the same ramp.
  let tile-fill(q) = if q.mode == "dark" { color.mix((q.ramp.at("900"), 55%), (q.paper, 45%), space: rgb) } else { color.mix((q.ramp.at("100"), 70%), (q.panel, 30%), space: rgb) }
  let tile(q, body, height: auto, inset: 18pt) = block(width: 100%, height: height, radius: 16pt, inset: inset, fill: tile-fill(q), body)
  let glass(ink, body, height: auto) = block(width: 100%, height: height, radius: t.radius.l, inset: (x: 16pt, top: 14pt, bottom: 16pt),
    fill: ink.transparentize(92%), stroke: 0.75pt + ink.transparentize(78%), body)

  /// Default content slide (assertion–evidence): a sentence title of at most two lines
  /// that states the takeaway, then one exhibit that supports it.
  let claim(title: none, source: none, projection: auto, accent: auto, body) = on-page(projection, accent, kind: "claim", title: title, source: source, context {
    let q = pal()
    if title != none { slide-title(q, title) }
    body
  })

  /// A chart or diagram carrying one message. The title interprets; the exhibit shows data only.
  let exhibit(title: none, source: none, projection: auto, accent: auto, body) = on-page(projection, accent, kind: "exhibit", title: title, source: source, context {
    let q = pal()
    if title != none { slide-title(q, title) }
    block(width: 100%, height: 1fr, align(center + horizon, body))
  })

  /// Opening slide inside the editorial frame: the title set large and light, fact
  /// chips beneath, and an optional class `number` set very large in a tone of the
  /// ground, cropped at the right edge. `side` runs up the left edge, for a
  /// classification such as "Internal".
  let title-slide(title: none, subtitle: none, facts: (), number: none, side: none, light: auto, projection: auto, accent: auto) = on-page(projection, accent, kind: "cover", title: title, light: light, context {
    let q = pal()
    let r = q.ramp
    if number != none {
      place(bottom + right, dx: 2.4cm, dy: 3.2cm,
        text(size: 400pt, weight: W.display, tracking: -0.05em, fill: if q.mode == "dark" { r.at("800").transparentize(35%) } else { r.at("200").transparentize(20%) }, number))
    }
    if side != none {
      place(top + left, dx: -1.35cm, dy: 0cm, rotate(-90deg, origin: top + left, reflow: true,
        text(size: S().label + 1pt, tracking: 0.08em, fill: q.ink-low, side)))
    }
    place(left + horizon, block(width: column, {
      text(size: S().h1, weight: W.display, tracking: -0.022em, fill: q.ink-hi, par(leading: 0.32em, title))
      if subtitle != none { v(0.8em); block(width: 80%, text(size: S().h5, fill: q.ink-mid, subtitle)) }
      if facts.len() > 0 { v(1.2em); facts.map(f => chip(q.ink-mid, q.hairline, f)).join(h(8pt)) }
    }))
  })

  /// Section divider on the accent ground. An index line gives the section's place in
  /// the deck, the title is set large and light, and glass cards preview the slides in
  /// the section, numbered as Proxima numbers a card set.
  let section-slide(number: none, title: none, subtitle: none, preview: 4, light: auto, projection: auto, accent: auto) = {
    on-page(projection, accent, kind: "section", title: title, light: light, context {
      let q = pal()
      let g = ground(q, "section")
      let ink = if g.ink == auto { ink-on(g.base) } else { g.ink }
      let soft = color.mix((ink, 72%), (g.base, 28%), space: rgb)
      let all = query(<centauri-slide>).map(m => m.value)
      let sections = all.filter(s => s.kind == "section")
      let here-n = _slide-no.get().first()
      let me = sections.position(s => s.n == here-n)
      let items = all.filter(s => s.section != none and s.section.n == here-n and s.kind not in ("section", "cover", "outline") and s.title != none)
      v(1fr)
      block(width: column, {
        text(size: S().small, fill: soft)[Section #(me + 1) of #sections.len()]
        v(0.2em)
        text(size: S().h1, weight: W.display, tracking: -0.022em, fill: ink, par(leading: 0.32em, title))
        if subtitle != none { v(0.7em); text(size: S().h5, fill: soft, subtitle) }
      })
      v(1fr)
      if preview > 0 and items.len() > 0 {
        let shown = items.slice(0, calc.min(preview, items.len()))
        let card(i, it) = {
          text(size: S().h5, weight: W.display, fill: ink, number-width: "tabular", if i < 9 { "0" + str(i + 1) } else { str(i + 1) })
          v(0.3em)
          text(size: S().small, fill: soft, par(leading: 0.5em, it.title))
        }
        // Cards share the height of the tallest, so the row reads as one set.
        layout(sz => {
          let gap = 0.5cm
          let w = (sz.width - gap * (shown.len() - 1)) / shown.len()
          let inner = w - 32pt
          let tallest = calc.max(..shown.enumerate().map(((i, it)) => measure(block(width: inner, card(i, it))).height))
          block(below: 0.1cm, grid(columns: (1fr,) * shown.len(), column-gutter: gap,
            ..shown.enumerate().map(((i, it)) => glass(ink, height: tallest + 30pt, card(i, it)))))
        })
      }
    })
  }

  /// Generated outline: the section slides of this deck, or with `depth: 2` every slide title
  /// under its section. Current section marked when `current` is set.
  let outline-slide(title: [What this session covers], current: none, projection: auto, accent: auto) = on-page(projection, accent, kind: "outline", title: title, context {
    let q = pal()
    slide-title(q, title)
    let slides = query(<centauri-slide>).map(m => m.value)
    let sections = slides.filter(s => s.kind == "section")
    let per = calc.min(4, calc.max(sections.len(), 1))
    v(1fr)
    grid(columns: (1fr,) * per, column-gutter: 0.5cm, row-gutter: 0.5cm, rows: 4.4cm,
      ..sections.enumerate().map(((i, s)) => {
        let count = slides.filter(c => c.section != none and c.section.n == s.n and c.kind not in ("section", "cover", "outline")).len()
        let now = current == i + 1
        let body = {
          text(size: S().h3, weight: W.display, fill: if current == none or now { q.ink-hi } else { q.ink-low }, number-width: "tabular", if i < 9 { "0" + str(i + 1) } else { str(i + 1) })
          v(1fr)
          text(size: S().h6, weight: W.h5, fill: if current == none or now { q.ink-hi } else { q.ink-low }, s.title)
          linebreak()
          text(size: S().small, fill: q.ink-low)[#count slides]
        }
        if now or current == none { tile(q, height: 100%, body) }
        else { block(width: 100%, height: 100%, radius: 16pt, inset: 18pt, stroke: 0.75pt + q.hairline, body) }
      }))
    v(1.2fr)
  })

  /// One short phrase at display size, set light beside an emphasis line. A pacing
  /// slide, not evidence. `hl[...]` marks the words that matter.
  let statement(sub: none, light: auto, projection: auto, accent: auto, body) = on-page(projection, accent, kind: "statement", light: light, context {
    let q = pal()
    align(left + horizon, block(width: 90%, {
      emphasis(q, S().h1, text(weight: W.h1, tracking: -0.022em, fill: q.ink-hi, par(leading: 0.42em, body)))
      if sub != none { v(1em); block(width: column, text(size: S().h5, fill: q.ink-mid, sub)) }
    }))
  })

  /// Quotation in the serif beside an emphasis line.
  let quote-slide(attribution: none, light: auto, projection: auto, accent: auto, body) = on-page(projection, accent, kind: "quote", light: light, context {
    let q = pal()
    align(left + horizon, block(width: column, {
      emphasis(q, S().h3, text(font: t.fonts.serif, style: "italic", fill: q.ink-hi, par(leading: 0.5em, body)))
      if attribution != none { v(0.9em); text(size: S().small, weight: t.weight.strong, fill: q.ink-mid, attribution) }
    }))
  })

  /// Terms and their explanations in rows, divided by hairlines. Use sparingly, for
  /// slides that define a small set of concepts in sentences.
  let explain(title: none, source: none, light: auto, projection: auto, accent: auto, ..rows) = on-page(projection, accent, kind: "explain", title: title, source: source, light: light, context {
    let q = pal()
    if title != none { slide-title(q, title) }
    let rows = rows.pos()
    grid(columns: (30%, 1fr), column-gutter: 1cm, row-gutter: 0pt,
      ..rows.enumerate().map(((i, r)) => {
        let cell(body) = block(width: 100%, inset: (y: 11pt), stroke: (top: if i == 0 { 0.75pt + q.ink-hi } else { 0.5pt + q.hairline }), body)
        (cell(text(size: S().h6, weight: W.h5, fill: q.ink-hi, r.at(0))), cell(r.at(1)))
      }).flatten())
  })


  /// Stacked stat tiles: a short label on the left, the number large and light on the
  /// right. Each item is (value, label).
  let stats(..items) = context {
    let q = pal()
    stack(spacing: 0.35cm, ..items.pos().map(((value, label)) => tile(q, inset: (x: 20pt, y: 14pt),
      grid(columns: (1fr, auto), align: (left + horizon, right + horizon), column-gutter: 1cm,
        text(size: S().small, weight: t.weight.strong, fill: q.ink-hi, label),
        text(size: S().h2, weight: W.display, tracking: -0.02em, fill: q.ink-hi, number-width: "tabular", value)))))
  }

  /// Rising columns: one rounded column per item, height proportional to `value`,
  /// the figure set inside the top and the label in an outlined pill at the base.
  /// Each item is (label, value) or (label, value, display). Tones alternate within
  /// the accent ramp; colour here encodes series, not emphasis.
  let columns-chart(height: 9cm, ..items) = context {
    let q = pal()
    let r = q.ramp
    let items = items.pos()
    let top = calc.max(..items.map(it => it.at(1)))
    let tones = if q.mode == "dark" { (r.at("800"), r.at("700")) } else { (r.at("200"), r.at("300")) }
    let ink = if q.mode == "dark" { q.ink-hi } else { r.at("950") }
    grid(columns: (1fr,) * items.len(), column-gutter: 0.45cm, align: bottom,
      ..items.enumerate().map(((i, it)) => {
        let hgt = height * it.at(1) / top
        stack(spacing: 0.25cm,
          block(width: 100%, height: hgt, radius: (top-left: 16pt, top-right: 16pt), fill: tones.at(calc.rem(i, 2)), inset: 14pt,
            text(size: S().h3, weight: W.display, fill: ink, number-width: "tabular", it.at(2, default: str(it.at(1))))),
          align(center, box(inset: (x: 10pt, y: 4pt), radius: t.radius.full, stroke: 0.75pt + q.hairline,
            text(size: S().label + 2pt, fill: q.ink-mid, it.at(0)))))
      }))
  }

  /// Horizontal bars with the value in a pill at the end of each bar. Each item is
  /// (label, value) or (label, value, display).
  let bars-chart(..items) = context {
    let q = pal()
    let r = q.ramp
    let items = items.pos()
    let top = calc.max(..items.map(it => it.at(1)))
    let tones = if q.mode == "dark" { (r.at("800"), r.at("700")) } else { (r.at("200"), r.at("300")) }
    grid(columns: (auto, 1fr), column-gutter: 0.5cm, row-gutter: 0.3cm, align: (right + horizon, left + horizon),
      ..items.enumerate().map(((i, it)) => (
        text(size: S().small, weight: t.weight.strong, fill: q.ink-mid, it.at(0)),
        layout(sz => box(width: calc.max(sz.width * it.at(1) / top, 2.4cm), height: 1.15cm, radius: 8pt, fill: tones.at(calc.rem(i, 2)), inset: (right: 6pt),
          align(right + horizon, box(inset: (x: 10pt, y: 3pt), radius: t.radius.full, fill: tile-fill(q),
            text(size: S().small, weight: t.weight.strong, fill: q.ink-hi, number-width: "tabular", it.at(2, default: str(it.at(1)))))))),
      )).flatten())
  }

  /// Split slide: a deep panel on the left carrying the title, tonal tiles on the right.
  /// Each item is (heading, body).
  let split(title: none, sub: none, light: auto, projection: auto, accent: auto, ..items) = on-page(projection, accent, kind: "split", title: title, light: light, context {
    let q = pal()
    let r = q.ramp
    let panel = if q.mode == "dark" { r.at("900") } else { r.at("800") }
    grid(columns: (36%, 1fr), column-gutter: 1cm, rows: 100%,
      block(width: 100%, height: 100%, radius: 18pt, fill: panel, inset: 22pt, align(left + horizon, {
        text(size: S().h3, weight: W.h2, tracking: -0.015em, fill: rgb("#FFFFFF"), par(leading: 0.4em, title))
        if sub != none { v(0.6em); text(size: S().small, fill: rgb("#FFFFFF").transparentize(25%), sub) }
      })),
      align(horizon, stack(spacing: 0.35cm, ..items.pos().enumerate().map(((i, it)) => tile(q, inset: (x: 18pt, y: 14pt), {
        text(size: S().h6, weight: W.h5, fill: q.ink-hi)[#(if i < 9 { "0" + str(i + 1) } else { str(i + 1) }) #h(0.4em) #it.at(0)]
        linebreak()
        text(size: S().small, fill: q.ink-mid, it.at(1))
      })))),
    )
  })

  /// One word or short phrase set to fill the column width, with a small title at the
  /// top left. A specimen slide: use it to put a single term in front of the room.
  let display-slide(title: none, sub: none, light: auto, projection: auto, accent: auto, body) = on-page(projection, accent, kind: "display", title: title, light: light, context {
    let q = pal()
    if title != none { text(size: S().h6, weight: W.h5, fill: q.ink-hi, title); if sub != none { linebreak(); text(size: S().small, fill: q.ink-mid, sub) } }
    block(width: 100%, height: 1fr, layout(sz => {
      let probe = text(size: 100pt, weight: W.h2, tracking: -0.03em, body)
      let wd = measure(probe).width
      let size = calc.min(100pt * (sz.width / wd), sz.height * 0.9)
      align(bottom + left, text(size: size, weight: W.h2, tracking: -0.03em, fill: q.ink-hi, top-edge: "cap-height", bottom-edge: "baseline", body))
    }))
  })

  /// Two options on a shared baseline. `left` and `right` are (heading, body). `pick` puts
  /// the accent on the option the title argues for.
  let compare(title: none, left: none, right: none, pick: none, source: none, projection: auto, accent: auto) = on-page(projection, accent, kind: "compare", title: title, source: source, context {
    let q = pal()
    if title != none { slide-title(q, title) }
    let dim = pick != none
    let panel(side, hi) = block(width: 100%, inset: (top: 14pt), stroke: (top: if hi { 2.5pt + q.ink-hi } else { 0.75pt + q.hairline }), {
      text(size: S().h5, weight: W.h5, fill: if hi or not dim { q.ink-hi } else { q.ink-low }, side.at(0))
      v(0.3em)
      text(fill: if hi or not dim { q.ink-mid } else { q.ink-low }, side.at(1))
    })
    grid(columns: (1fr, 1fr), column-gutter: 1.4cm, panel(left, pick == "left"), panel(right, pick == "right"))
  })

  /// Grid of numbers: tabular figures, numerals right-aligned, no vertical rules.
  let table-slide(title: none, columns: 2, header: none, align: auto, source: none, projection: auto, accent: auto, ..cells) = on-page(projection, accent, kind: "table", title: title, source: source, context {
    let q = pal()
    if title != none { slide-title(q, title) }
    let n = if type(columns) == int { columns } else { columns.len() }
    // Numbers right-aligned by default; pass align: left for tables of text.
    (base.data-table)(columns: columns, header: header, align: if align == auto { (x, _) => if x == 0 { left } else { right } } else { align }, ..cells)
  })

  /// Code listing of at most 15 lines. `highlight` takes line numbers set on an accent band.
  let code-slide(title: none, file: none, highlight: (), source: none, projection: auto, accent: auto, body) = on-page(projection, accent, kind: "code", title: title, source: source, context {
    let q = pal()
    if title != none { slide-title(q, title) }
    let band = q.ink-hi.transparentize(if q.mode == "light" { 92% } else { 88% })
    show raw.line: it => if it.number in highlight { box(fill: band, outset: (x: 14pt, y: 3pt), width: 100%, it) } else { it }
    if file != none { block(below: 0.4em, text(font: mono, size: S().label + 2pt, fill: q.ink-mid, file)) }
    body
  })

  /// Numbered sequence. `current` emphasises one step.
  let steps-slide(title: none, current: none, source: none, projection: auto, accent: auto, ..items) = on-page(projection, accent, kind: "steps", title: title, source: source, context {
    let q = pal()
    if title != none { slide-title(q, title) }
    let items = items.pos()
    grid(columns: (1fr,) * items.len(), column-gutter: 0.7cm,
      ..items.enumerate().map(((i, it)) => {
        let on = current == none or current == i + 1
        block(width: 100%, inset: (top: 12pt), stroke: (top: if current == i + 1 { 2.5pt + q.ink-hi } else { 0.75pt + q.hairline }), {
          text(size: S().h3, weight: W.display, fill: if on { q.ink-hi } else { q.ink-low }, number-width: "tabular", str(i + 1))
          v(0.2em)
          text(fill: if on { q.ink-mid } else { q.ink-low }, it)
        })
      }))
  })

  /// Training exercise: task, time box and expected output. Set in a second accent so
  /// exercises stand apart from content slides.
  let exercise(title: none, task: none, minutes: none, output: none, projection: auto, accent: auto) = context {
    let a = if accent != auto { accent } else {
      let now = _deck.get().accent
      if now == "ember" { "teal" } else { "ember" }
    }
    on-page(projection, a, kind: "exercise", title: title, context {
      let q = pal()
      if title != none { slide-title(q, title) }
      grid(columns: (1fr, auto), column-gutter: 1.4cm,
        {
          if task != none { task }
          if output != none {
            v(0.8em)
            block(inset: (top: 10pt), stroke: (top: 1pt + q.hairline), {
              text(size: S().small, weight: t.weight.strong, fill: q.ink-hi)[Expected output]
              linebreak()
              output
            })
          }
        },
        if minutes != none {
          align(right, {
            text(size: S().h1 * 1.272, weight: W.display, fill: q.ink-hi, number-width: "tabular", str(minutes))
            linebreak()
            text(size: S().small, fill: q.ink-mid)[minutes]
          })
        })
    })
  }

  /// Dense evidence behind the main argument. Smaller body size is permitted here.
  let appendix(title: none, source: none, projection: auto, accent: auto, body) = on-page(projection, accent, kind: "appendix", title: title, source: source, context {
    let q = pal()
    if title != none { slide-title(q, title, size: S().h5) }
    set text(size: S().small)
    body
  })

  /// Closing slide: next actions and a contact line.
  let close(title: [What to do next], actions: (), contact: none, projection: auto, accent: auto) = on-page(projection, accent, kind: "close", title: title, context {
    let q = pal()
    slide-title(q, title)
    for (i, a) in actions.enumerate() {
      block(above: 0.6em, grid(columns: (1.6em, 1fr), text(weight: t.weight.strong, fill: q.ink-low, str(i + 1)), a))
    }
    if contact != none { place(bottom + left, text(size: S().small, fill: q.ink-mid, contact)) }
  })

  /// A number with its label, for use inside any slide.
  let metric(value, label, note: none) = context {
    let q = pal()
    block({
      text(size: S().h2, weight: W.h2, tracking: -0.02em, fill: q.ink-hi, number-width: "tabular", value)
      linebreak()
      text(size: S().body, weight: t.weight.strong, fill: q.ink-hi, label)
      if note != none { linebreak(); text(size: S().small, fill: q.ink-mid, note) }
    })
  }

  /// Equal columns with a shared gutter. Pass `widths` for anything else.
  let cols(widths: auto, gutter: 1cm, ..items) = {
    let items = items.pos()
    grid(columns: if widths == auto { (1fr,) * items.len() } else { widths }, column-gutter: gutter, ..items)
  }

  /// Speaker notes: shown beneath the slide in handout mode, and on the slide with
  /// `--input notes=true`. Hidden otherwise.
  let notes(body) = {
    if mode == "handout" { _slide-notes.update(body) }
    else if sys.inputs.at("notes", default: "false") == "true" {
      context {
        let q = pal()
        place(bottom + left, dy: 1.3cm, block(width: 100%, fill: q.sky.fill, stroke: 0.5pt + q.sky.line, radius: t.radius.m, inset: 8pt,
          text(size: S().label + 2pt, fill: q.ink-hi, body)))
      }
    }
  }

  base + (
    centauri: centauri,
    slide: claim,
    claim: claim,
    exhibit: exhibit,
    title-slide: title-slide,
    section-slide: section-slide,
    outline-slide: outline-slide,
    statement: statement,
    quote-slide: quote-slide,
    explain: explain,
    stats: stats,
    tile: (body) => context tile(pal(), body),
    columns-chart: columns-chart,
    bars-chart: bars-chart,
    split: split,
    display-slide: display-slide,
    compare: compare,
    table-slide: table-slide,
    code-slide: code-slide,
    steps-slide: steps-slide,
    exercise: exercise,
    appendix: appendix,
    close: close,
    metric: metric,
    cols: cols,
    hl: hl,
    notes: notes,
  )
}

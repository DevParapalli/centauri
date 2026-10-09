#import "tokens.typ": contrast

/// Active page tone, "light" or "dark". Dark inside a dark cover.
#let tone = state("centauri-tone", "light")

#let _stage = state("centauri-stage", "draft")
#let _req-label = state("centauri-req-label", "Reference")
#let _todos = counter("centauri-todo")
#let _sidenotes = state("centauri-sidenotes", false)
#let _sn = counter("centauri-sidenote")
#let _parts = counter("centauri-part")
#let _margins = state("centauri-margins", (left: 2cm, right: 2cm))
/// Accent in force: none means the theme default. Change it with `use-accent` or per cover, slide or page.
#let _accent = state("centauri-accent", none)
/// Which type scale is in force: "document" or "deck".
#let _size = state("centauri-size", "document")

/// Defaults per document kind. Explicit arguments to `centauri` override them.
#let kinds = (
  report: (h1-pagebreak: true, orientation: "portrait", columns: 1, max-pages: none, sidenotes: false, h1-style: auto),
  rfp: (h1-pagebreak: true, orientation: "portrait", columns: 1, max-pages: none, sidenotes: false, h1-style: auto),
  spec: (h1-pagebreak: true, orientation: "portrait", columns: 1, max-pages: none, sidenotes: false, h1-style: auto),
  brief: (h1-pagebreak: false, orientation: "portrait", columns: 1, max-pages: 1, sidenotes: false, h1-style: "compact"),
  handout: (h1-pagebreak: false, orientation: "portrait", columns: 2, max-pages: none, sidenotes: false, h1-style: auto),
  handbook: (h1-pagebreak: true, orientation: "portrait", columns: 1, max-pages: none, sidenotes: true, h1-style: auto),
  wallchart: (h1-pagebreak: false, orientation: "landscape", columns: 1, max-pages: none, sidenotes: false, h1-style: auto),
)
#let _furniture = state("centauri-furniture", (
  header: (left: none, center: none, right: none),
  footer: (left: none, center: auto, right: none),
  sensitivity: none,
  header-rule: auto,
  footer-rule: auto,
  folio: auto,
))

#let _register-kinds = (
  assumption: (word: "Assumption", prefix: "A", tone: none),
  dependency: (word: "Dependency", prefix: "D", tone: none),
  decision: (word: "Decision", prefix: "DEC", tone: none),
  risk: (word: "Risk", prefix: "R", tone: "amber"),
  issue: (word: "Issue", prefix: "I", tone: "rose"),
)

#let _rule-keys = ("header-rule", "footer-rule")

/// Update page furniture from this point on. Keys: left, center, right. Values: content, none, auto, or tone => content.
/// `header-rule` and `footer-rule`: a stroke, none, or auto for the hairline. `folio`: a function
/// (page, total, sensitivity) => content for the footer centre's auto slot, or auto for "n/N | sensitivity".
/// Left out, each is kept.
// These arrive as named sinks so that leaving one out (keep) differs from passing auto (default).
#let furniture(header: (:), footer: (:), sensitivity: auto, ..rules) = {
  assert(rules.pos().len() == 0, message: "centauri: furniture takes named arguments only")
  for (k, v) in rules.named() {
    assert(k in _rule-keys or k == "folio", message: "centauri: furniture takes header, footer, sensitivity, header-rule, footer-rule and folio")
    if k == "folio" {
      assert(v == auto or type(v) == function, message: "centauri: folio must be a function (page, total, sensitivity) => content, or auto")
    } else {
      assert(v == auto or v == none or type(v) in (stroke, length, color, dictionary),
        message: "centauri: " + k + " must be a stroke, none or auto")
    }
  }
  _furniture.update(f => f + (
    header: f.header + header,
    footer: f.footer + footer,
    sensitivity: if sensitivity == auto { f.sensitivity } else { sensitivity },
  ) + rules.named())
}

#let _escape(s) = s.replace(regex("[\\\\^$.|?*+()\\[\\]{}]"), m => "\\" + m.text)

#let make(t) = {
  let p = t.light
  let mono = t.fonts.mono
  // `cover` shadows `tone` with its own parameter, so bind the state out here.
  let _tone = tone
  let accent-now() = { let a = _accent.get(); if a == none { t.accent } else { a } }
  let pal() = t.palettes.at(accent-now()).at(if _tone.get() == "dark" { "dark" } else { "light" })
  let palette(accent, tone) = t.palettes.at(accent).at(tone)
  let S() = t.scales.at(_size.get())

  assert(t.label-case in ("upper", "as-written"), message: "centauri: label-case must be upper or as-written")
  // Tracking only suits capitals, so labels set as written lose it.
  let caps(body) = if t.label-case == "upper" { upper(body) } else { body }
  let caps-track(em) = if t.label-case == "upper" { em } else { 0em }
  let label-text(q, body, size: auto) = context text(font: mono, size: if size == auto { S().label } else { size }, tracking: caps-track(0.12em), weight: t.weight.label, fill: q.ink-mid, caps(body))

  let tone-of(q, tone) = if tone == "mute" or tone == none {
    (text: q.ink-mid, fill: q.panel, line: q.hairline)
  } else if tone == "accent" {
    (text: q.accent-deep, fill: q.accent-fill, line: q.hairline)
  } else {
    q.at(tone)
  }

  // Running head: the level 1 heading in force on this page.
  let running-head(tone) = context {
    let page = here().page()
    let sel = std.heading.where(level: 1)
    let on = query(sel).filter(h => h.location().page() == page)
    let hd = if on.len() > 0 { on.first() } else {
      let before = query(selector(sel).before(here()))
      if before.len() > 0 { before.last() } else { none }
    }
    if hd == none { return none }
    let q = palette(accent-now(), if tone == "dark" { "dark" } else { "light" })
    text(size: S().small, fill: q.ink-mid, {
      if hd.numbering != none {
        text(font: mono, std.numbering(hd.numbering, ..counter(std.heading).at(hd.location())))
        h(0.5em)
      }
      hd.body
    })
  }

  // Slots take content, none, auto or a function of the tone. Auto is the running
  // head in the header centre and the folio in any footer slot.
  let slot(value, tone, q, f, is-footer, is-header-center: false) = {
    if type(value) == function { value(tone) } else if value == auto and is-header-center { running-head(tone) } else if value == auto and is-footer {
      if f.folio == auto {
        text(font: mono, size: S().label + 0.5pt, fill: q.ink-mid)[
          #counter(page).display("1/1", both: true)#if f.sensitivity != none [ | #f.sensitivity]
        ]
      } else {
        (f.folio)(counter(page).get().first(), counter(page).final().first(), f.sensitivity)
      }
    } else if value == auto { none } else { value }
  }

  let row(f, slots, tone, q, footer) = grid(
    columns: (1fr, 1fr, 1fr),
    align: (left + horizon, center + horizon, right + horizon),
    slot(slots.left, tone, q, f, footer),
    slot(slots.center, tone, q, f, footer, is-header-center: not footer),
    slot(slots.right, tone, q, f, footer),
  )

  // Header and footer both read furniture as it stood at the top of the page.
  // Page 1's header is laid out before the document's first furniture update takes
  // effect, so the document's own settings are passed in as `first` and applied there.
  let with-first(f, first) = if first == none { f } else { f + (
    header: f.header + first.header,
    footer: f.footer + first.footer,
    sensitivity: if first.sensitivity == auto { f.sensitivity } else { first.sensitivity },
  ) + first.rules }

  let rule-stroke(r, q) = if r == auto { 0.5pt + q.hairline } else { r }

  let header-for(q, tone, first: none) = context {
    [#metadata(none) <centauri-page-top>]
    let f = _furniture.get()
    if here().page() == 1 { f = with-first(f, first) }
    set text(fill: q.ink-mid, size: S().small)
    row(f, f.header, tone, q, false)
    if f.header-rule != none {
      v(-4pt)
      line(length: 100%, stroke: rule-stroke(f.header-rule, q))
    }
  }

  let footer-for(q, tone, first: none) = context {
    let page = here().page()
    let tops = query(<centauri-page-top>).filter(m => m.location().page() == page)
    let f = if tops.len() > 0 { _furniture.at(tops.first().location()) } else { _furniture.get() }
    if page == 1 { f = with-first(f, first) }
    set text(fill: q.ink-mid, size: S().small)
    if f.footer-rule != none {
      line(length: 100%, stroke: rule-stroke(f.footer-rule, q))
      v(-4pt)
    }
    row(f, f.footer, tone, q, true)
  }

  let kv-in(q, pairs) = {
    let n = pairs.len()
    table(
      columns: (32%, 1fr),
      stroke: (_, y) => (bottom: if y + 1 == n { none } else { 0.5pt + q.hairline-soft }),
      inset: (x: 0pt, y: 6pt),
      align: (left + top, left + top),
      ..pairs.map(((k, v)) => (label-text(q, k), text(fill: q.ink-hi, v))).flatten(),
    )
  }

  // Syntax highlighting generated from the palette, so code follows the accent and the tone.
  let code-theme(q) = {
    let entry(scope, colour, style: none) = (
      "<dict><key>scope</key><string>" + scope + "</string><key>settings</key><dict><key>foreground</key><string>"
        + colour.to-hex() + "</string>" + if style != none { "<key>fontStyle</key><string>" + style + "</string>" } else { "" }
        + "</dict></dict>"
    )
    let rules = (
      "<dict><key>settings</key><dict><key>foreground</key><string>" + q.ink-hi.to-hex() + "</string></dict></dict>",
      entry("comment, punctuation.definition.comment", q.ink-low, style: "italic"),
      entry("keyword, storage, keyword.operator.word", q.accent-deep),
      entry("string, string.quoted, punctuation.definition.string", q.mint.text),
      entry("constant.numeric, constant.language, constant.character", q.amber.text),
      entry("entity.name.function, support.function, meta.function-call", q.sky.text),
      entry("entity.name.type, entity.name.class, support.type, support.class", q.charts.at(3)),
      entry("variable.parameter, meta.attribute", q.ink-mid),
      entry("invalid", q.rose.text),
    )
    bytes("<?xml version=\"1.0\" encoding=\"UTF-8\"?><plist version=\"1.0\"><dict><key>settings</key><array>" + rules.join() + "</array></dict></plist>")
  }
  let code-themes = (:)
  for (name, pp) in t.palettes { code-themes.insert(name, (light: code-theme(pp.light), dark: code-theme(pp.dark))) }

  // Serif is reserved for quotations and the drop cap.
  let serif(body, size: auto) = context text(font: t.fonts.serif, style: "italic", weight: 400, size: if size == auto { S().body } else { size }, tracking: 0.005em, body)

  let centauri(
    kind: "report",
    accent: auto,
    title: none,
    author: (),
    keywords: (),
    date: auto,
    lang: "en",
    region: none,
    paper: "a4",
    orientation: auto,
    columns: auto,
    max-pages: auto,
    sidenotes: auto,
    stage: "draft",
    lint: (),
    numbering: "1.1",
    h1-pagebreak: auto,
    h1-style: auto,
    heading-numbers: "inline",
    header: (:),
    footer: (:),
    sensitivity: none,
    header-rule: auto,
    footer-rule: auto,
    folio: auto,
    req-label: "Reference",
    body,
  ) = {
    let stage = sys.inputs.at("stage", default: stage)
    assert(kind in kinds, message: "centauri: kind must be one of " + kinds.keys().join(", "))
    assert(paper in ("a4", "us-letter"), message: "centauri: paper must be a4 or us-letter")
    let d = kinds.at(kind)
    let pick(v, key) = if v == auto { d.at(key) } else { v }
    let orientation = pick(orientation, "orientation")
    let columns = pick(columns, "columns")
    let max-pages = pick(max-pages, "max-pages")
    let sidenotes = pick(sidenotes, "sidenotes")
    let h1-pagebreak = pick(h1-pagebreak, "h1-pagebreak")
    let h1-style = pick(h1-style, "h1-style")
    assert(orientation in ("portrait", "landscape"), message: "centauri: orientation must be portrait or landscape")
    // Sidenotes need a wide outer margin; other kinds keep 2cm and fall back to footnotes.
    let margins = if sidenotes { (left: 2cm, right: 5.4cm) } else { (left: 2cm, right: 2cm) }
    assert(stage in ("draft", "review", "final"), message: "centauri: stage must be draft, review or final")
    let accent = if accent == auto { t.accent } else { accent }
    assert(accent in t.palettes, message: "centauri: accent must be one of " + t.palettes.keys().join(", "))
    assert(h1-style in (auto, "banner", "rule", "compact"), message: "centauri: h1-style must be auto, banner, rule or compact")
    assert(heading-numbers in ("inline", "hang", "none"), message: "centauri: heading-numbers must be inline, hang or none")
    let p = palette(accent, "light")
    let sz = t.scales.document
    for (_, pp) in t.palettes { for q in (pp.light, pp.dark) {
      for g in (q.paper, q.cover) {
        assert(contrast(q.link, g) >= 4.5, message: "centauri: link colour " + q.link.to-hex() + " is below 4.5:1 on " + g.to-hex())
      }
    } }

    set document(title: title, author: author, keywords: keywords, date: date)
    set text(font: t.fonts.sans, size: sz.body, weight: t.weight.body, fill: p.ink-mid, lang: lang, region: region, number-type: "lining")
    show heading: set text(number-width: "tabular")
    // Typesetting rules: no single word alone on a line, no stranded lines.
    set text(costs: (runt: 400%, widow: 200%, orphan: 200%))
    set par(justify: false, leading: 0.72em, spacing: 1.15em)
    set strong(delta: t.weight.strong - t.weight.body)
    set list(indent: 0.4em, body-indent: 0.6em, marker: text(fill: p.ink-low)[•])
    set enum(indent: 0.4em, body-indent: 0.6em)

    set page(
      paper: paper,
      flipped: orientation == "landscape",
      columns: columns,
      margin: (top: 2.7cm, bottom: 2.3cm, left: margins.left, right: margins.right),
      header-ascent: 35%,
      footer-descent: 35%,
      header: header-for(p, "light", first: (header: header, footer: footer, sensitivity: sensitivity, rules: (header-rule: header-rule, footer-rule: footer-rule, folio: folio))),
      footer: footer-for(p, "light", first: (header: header, footer: footer, sensitivity: sensitivity, rules: (header-rule: header-rule, footer-rule: footer-rule, folio: folio))),
      background: if stage == "draft" {
        place(center + horizon, rotate(-35deg, text(size: sz.watermark, weight: 600, fill: color.mix((p.ink-hi, 5%), (p.paper, 95%), space: rgb), tracking: 0.05em)[DRAFT]))
      },
    )

    _stage.update(stage)
    _size.update("document")
    _accent.update(accent)
    _sidenotes.update(sidenotes)
    _margins.update(margins)
    _req-label.update(req-label)
    furniture(header: header, footer: footer, sensitivity: sensitivity, header-rule: header-rule, footer-rule: footer-rule, folio: folio)

    set heading(numbering: numbering)
    show heading: set text(fill: p.ink-hi)
    // Heading numbers are set at the heading's own size and weight: in the accent for
    // level 1, in low ink below. `heading-numbers: "hang"` outdents them into the margin.
    let with-number(it, size, weight, num-fill, title, hang: heading-numbers == "hang") = {
      let num = if it.numbering != none and heading-numbers != "none" {
        std.numbering(it.numbering, ..counter(heading).at(it.location()))
      }
      if num == none { return title }
      let n = text(size: size, weight: weight, fill: num-fill, number-width: "tabular", num)
      if hang {
        let w = measure(n).width
        pad(left: -w - 0.55em, grid(columns: (w, 1fr), column-gutter: 0.55em, n, title))
      } else {
        grid(columns: (auto, 1fr), column-gutter: 0.5em, n, title)
      }
    }

    show heading.where(level: 1): it => {
      if h1-pagebreak { pagebreak(weak: true) }
      let q = pal()
      // A level 1 heading that opens a page becomes a banner across the page; one that
      // falls mid-page sits under a rule. Multi-column pages always use the rule.
      let at-top = h1-pagebreak or here().position().y < (2.7cm + 3pt).to-absolute()
      let style = if h1-style != auto { h1-style } else if columns > 1 or not at-top { "rule" } else { "banner" }
      let title = text(size: S().h1, weight: t.weight.h1, tracking: -0.01em, fill: q.ink-hi, it.body)
      if style == "banner" {
        let field = color.mix((q.accent, 9%), (q.paper, 91%), space: rgb)
        block(width: 100%, above: 0pt, below: 1.8em, breakable: false, fill: field,
          outset: (left: margins.left, right: margins.right), inset: (y: 1.15cm),
          stroke: (bottom: 1.5pt + q.link), {
            align(center, block(width: 76%, align(center, {
              let num = if it.numbering != none and heading-numbers != "none" {
                std.numbering(it.numbering, ..counter(heading).at(it.location()))
              }
              if num != none [#text(size: S().h1, weight: t.weight.body, fill: q.link, number-width: "tabular", num)#h(0.45em)]
              title
            })))
          })
      } else if style == "compact" {
        // Same size as the other styles, without the band or rule, for pages that need the space.
        block(above: 1.2em, below: 0.6em, width: 100%, sticky: true,
          with-number(it, S().h1, t.weight.body, q.link, title))
      } else {
        block(above: 1.6em, below: 1.2em, width: 100%, {
          line(length: 100%, stroke: 0.75pt + q.ink-hi)
          v(0.5em)
          with-number(it, S().h1, t.weight.body, q.link, title)
        })
      }
    }
    show heading.where(level: 2): it => block(above: 1.8em, below: 0.8em, sticky: true,
      with-number(it, S().h2, t.weight.h2, p.ink-low, text(size: S().h2, weight: t.weight.h2, tracking: -0.01em, it.body)))
    show heading.where(level: 3): it => block(above: 1.4em, below: 0.6em, sticky: true,
      with-number(it, S().h3, t.weight.h3, p.ink-low, text(size: S().h3, weight: t.weight.h3, it.body)))
    show heading.where(level: 4): it => block(above: 1.2em, below: 0.55em, sticky: true,
      with-number(it, S().h4, t.weight.h4, p.ink-low, text(size: S().h4, weight: t.weight.h4, it.body)))
    show heading.where(level: 5): it => block(above: 1.1em, below: 0.5em, sticky: true,
      with-number(it, S().h5, t.weight.h5, p.ink-low, text(size: S().h5, weight: t.weight.h5, it.body)))
    show heading.where(level: 6): it => block(above: 1em, below: 0.45em, sticky: true,
      with-number(it, S().h6, t.weight.h6, p.ink-low, text(size: S().h6, weight: t.weight.h6, it.body)))

    set outline(indent: auto, title: [Contents])
    show outline.entry.where(level: 1): set block(above: 1em)
    show outline.entry.where(level: 1): set text(weight: 500, fill: p.ink-hi)

    show link: it => context { set text(fill: pal().link); it }
    set raw(theme: code-themes.at(accent).light)
    show raw: set text(font: mono, size: sz.small)
    show raw.where(block: true): it => context {
      let q = pal()
      set raw(theme: code-themes.at(q.accent-name).at(q.mode))
      block(width: 100%, fill: q.panel, stroke: 0.5pt + q.hairline-soft, radius: t.radius.m, inset: 9pt, it)
    }

    // Block quotations are one of the two places the serif appears.
    show quote.where(block: true): it => context {
      let q = pal()
      block(above: 1.3em, below: 1.3em, inset: (left: 12pt, y: 2pt), stroke: (left: 1.5pt + q.accent-deep), {
        serif(size: S().h5, text(fill: q.ink-hi, it.body))
        if it.attribution != none {
          v(0.3em)
          label-text(q, it.attribution)
        }
      })
    }

    set table(stroke: (_, y) => (bottom: 0.5pt + p.hairline-soft), inset: (x: 6pt, y: 6pt))
    show table: set text(size: sz.small + 0.5pt, number-width: "tabular")

    show figure.caption: it => context {
      let q = pal()
      block(width: 100%, align(left, text(size: S().small, fill: q.ink-mid, {
        label-text(q, [#it.supplement #it.counter.display(it.numbering)])
        h(0.7em)
        it.body
      })))
    }

    show figure: it => {
      let kind = if type(it.kind) == str and it.kind.starts-with("centauri-") { it.kind.slice(9) } else { none }
      if kind == none or kind not in _register-kinds { return it }
      let spec = _register-kinds.at(kind)
      context {
        let q = pal()
        let s = tone-of(q, spec.tone)
        let id = std.numbering(it.numbering, ..it.counter.at(it.location()))
        block(width: 100%, breakable: false, above: 1em, below: 1em, inset: (x: 11pt, y: 9pt), radius: t.radius.m,
          fill: if spec.tone == none { q.panel } else { s.fill },
          stroke: 0.5pt + (if spec.tone == none { q.hairline } else { s.line }),
          align(left, {
            text(font: mono, size: S().label + 0.5pt, tracking: caps-track(0.18em), fill: if spec.tone == none { q.ink-mid } else { s.text }, caps[#spec.word #text(weight: 500, fill: if spec.tone == none { q.accent-deep } else { s.text }, id)])
            linebreak()
            text(fill: q.ink-hi, it.caption.body)
          }),
        )
      }
    }

    show: body => if lint.len() == 0 { body } else {
      let pattern = regex(lint.map(_escape).join("|"))
      show pattern: it => if stage == "final" {
        panic("centauri: lint match \"" + it.text + "\" is not allowed at stage final")
      } else {
        context {
          let q = pal()
          highlight(fill: q.rose.fill, stroke: 0.5pt + q.rose.line, text(fill: q.rose.text, it))
        }
      }
      body
    }

    body

    context {
      let open = _todos.final().first()
      if stage == "final" and open > 0 {
        panic("centauri: " + str(open) + " unresolved todo placeholder(s) at stage final")
      }
      let pages = counter(page).final().first()
      if max-pages != none and pages > max-pages {
        panic("centauri: " + str(pages) + " pages, but kind " + kind + " allows " + str(max-pages) + "; cut content or pass max-pages")
      }
    }
  }

  /// Full-page cover. `accent` overrides the document accent for this page only.
  let cover(
    tone: "light",
    accent: auto,
    title: none,
    subtitle: none,
    meta: (),
    heading: false,
    furniture: true,
    bloom: true,
    ..rest,
  ) = {
    assert(rest.named().len() == 0, message: "centauri: cover has no parameter " + rest.named().keys().join(", ") + " (the eyebrow was removed in 0.2.0)")
    let body = rest.pos().at(0, default: none)
    assert(tone in ("light", "dark"), message: "centauri: cover tone must be light or dark")
    assert(accent == auto or accent in t.palettes, message: "centauri: accent must be auto or one of " + t.palettes.keys().join(", "))
    context {
      let doc-accent = accent-now()
      let a = if accent == auto { doc-accent } else { accent }
      let q = palette(a, tone)
      let fill = if bloom {
        gradient.radial(color.mix((q.accent, if tone == "dark" { 24% } else { 16% }), (q.cover, 100% - if tone == "dark" { 24% } else { 16% }), space: rgb), q.cover, center: (8%, 4%), radius: 95%)
      } else { q.cover }
      page(
        fill: fill,
        background: none,
        footer: none,
        header: if furniture { header-for(q, tone) } else { none },
      )[
        #_tone.update(tone)
        #_accent.update(a)
        #set text(fill: q.ink-mid)
        #show link: set text(fill: q.link)
        #show std.heading: it => text(size: S().display, weight: t.weight.h1, tracking: -0.015em, fill: q.ink-hi, it.body)
        #v(1fr)
        #if title != none {
          set par(leading: 0.4em)
          if heading { std.heading(level: 1, title) } else {
            text(size: S().display, weight: t.weight.h1, tracking: -0.015em, fill: q.ink-hi, title)
          }
        }
        #if subtitle != none {
          v(0.9em)
          text(size: S().h4, fill: q.ink-mid, subtitle)
        }
        #if body != none {
          v(1.2em)
          block(width: 78%, body)
        }
        #v(2fr)
        #if meta.len() > 0 {
          line(length: 100%, stroke: 0.5pt + q.hairline)
          kv-in(q, meta)
        }
        #_tone.update("light")
        #_accent.update(doc-accent)
      ]
    }
  }

  /// Switch the accent from this point on.
  let use-accent(name) = {
    assert(name in t.palettes, message: "centauri: accent must be one of " + t.palettes.keys().join(", "))
    _accent.update(name)
  }

  /// Set `body` in another accent, then return to the accent that was in force.
  let with-accent(name, body) = {
    assert(name in t.palettes, message: "centauri: accent must be one of " + t.palettes.keys().join(", "))
    context {
      let before = accent-now()
      _accent.update(name)
      body
      _accent.update(before)
    }
  }

  // Everything after it is an annex: heading numbers restart, level 1 in the first pattern and
  // lower levels in the second. A title draws a divider page first, in the style of `part`.
  let annexes(title: none, subtitle: none, word: "Annex", numbering: ("A", "A.1"), body) = {
    assert(type(numbering) == array and numbering.len() == 2, message: "centauri: annexes numbering takes two patterns, level 1 and below")
    if title != none {
      pagebreak(weak: true)
      context {
        let q = pal()
        page(header: none, footer: none, background: none, {
          set align(left + horizon)
          text(size: S().display, weight: t.weight.h1, tracking: -0.015em, fill: q.ink-hi, title)
          if subtitle != none { v(0.8em); text(size: S().h4, fill: q.ink-mid, subtitle) }
        })
      }
    }
    counter(std.heading).update(0)
    // The supplement is the word a cross-reference prints before the number, as in "Annex A".
    set std.heading(supplement: word, numbering: (..n) => {
      let n = n.pos()
      std.numbering(if n.len() == 1 { numbering.first() } else { numbering.last() }, ..n)
    })
    body
  }

  let pill(tone: "mute", dot: true, body) = context {
    let s = tone-of(pal(), tone)
    box(inset: (x: 6pt, y: 2.4pt), outset: (y: 0.6pt), radius: t.radius.full, fill: s.fill, stroke: 0.5pt + s.line,
      text(size: S().label + 0.5pt, weight: 500, tracking: 0.02em, fill: s.text, {
        if dot { box(baseline: -0.22em, circle(radius: 1.7pt, fill: s.text)); h(3.5pt) }
        body
      }))
  }

  let status-words = (
    compliant: ("Compliant", "mint"),
    partial: ("Partial", "amber"),
    exception: ("Exception", "rose"),
    noted: ("Noted", "sky"),
  )

  let data-table(columns: 1, align: auto, header: none, ..cells) = context {
    let q = pal()
    let n = if type(columns) == int { columns } else { columns.len() }
    let cells = cells.pos()
    let h = if header == none { 0 } else { 1 }
    let last = h + calc.ceil(cells.len() / n) - 1
    table(
      columns: columns,
      align: if align == auto { left + top } else { align },
      stroke: (_, y) => (bottom: if y == last { none } else if y < h { 0.75pt + q.hairline } else { 0.5pt + q.hairline-soft }),
      ..if header != none { (table.header(..header.map(c => label-text(q, c))),) },
      ..cells.enumerate().map(((i, c)) => if calc.rem(i, n) == 0 { text(fill: q.ink-hi, c) } else { c }),
    )
  }

  let register(kind) = body => {
    let spec = _register-kinds.at(kind)
    figure(kind: "centauri-" + kind, supplement: spec.word, numbering: n => spec.prefix + str(n), caption: body, outlined: false, [])
  }

  // ---- Long-form and reference components -------------------------------

  let pull-quote(attribution: none, body) = context {
    let q = pal()
    block(above: 1.6em, below: 1.6em, inset: (left: 14pt, y: 3pt), stroke: (left: 1.5pt + q.accent-deep), breakable: false, {
      set par(leading: 0.5em)
      serif(size: S().h3, text(fill: q.ink-hi, body))
      if attribution != none { v(0.5em); label-text(q, attribution) }
    })
  }

  let epigraph(attribution: none, body) = context {
    let q = pal()
    align(right, block(width: 62%, above: 1em, below: 2em, align(left, {
      serif(size: S().h5, text(fill: q.ink-hi, body))
      if attribution != none { v(0.4em); label-text(q, attribution) }
    })))
  }

  // Drop cap for the opening paragraph of a long-form piece. `body` is a plain
  // string so the paragraph can be split where the capital ends.
  let drop-cap(lines: 3, gap: 4pt, body) = {
    assert(type(body) == str, message: "centauri: drop-cap takes the paragraph as a string")
    let first = body.clusters().first()
    let words = body.clusters().slice(1).join().split(" ")
    context {
      let q = pal()
      let leading = par.leading.to-absolute()
      let line-h = measure(text("X")).height
      let cap-h = line-h * lines + leading * (lines - 1)
      let cap = text(font: t.fonts.serif, size: cap-h * 1.38, fill: q.ink-hi, top-edge: "cap-height", bottom-edge: "baseline", first)
      layout(size => {
        let cw = measure(cap).width + gap
        let avail = size.width - cw
        let height-of(n) = measure(block(width: avail, words.slice(0, n).join(" "))).height
        let n = words.len()
        let k = 0
        while k < n and height-of(k + 1) <= cap-h + 0.2 * line-h { k += 1 }
        // Stop at a line boundary so the rest continues on a fresh line.
        while k > 0 and k < n and height-of(k) == height-of(k + 1) { k -= 1 }
        let beside = words.slice(0, k).join(" ")
        let rest = words.slice(k).join(" ")
        grid(columns: (cw, 1fr), row-gutter: 0pt, box(cap), beside)
        v(-leading * 0.2)
        par(rest)
      })
    }
  }

  let sidenote(body) = context {
    if not _sidenotes.get() { return footnote(body) }
    _sn.step()
    context {
      let q = pal()
      let n = _sn.get().first()
      let pos = here().position()
      let m = _margins.get()
      let x = page.width - m.right + 0.5cm
      super(text(font: mono, fill: q.accent-deep, str(n)))
      box(width: 0pt, place(top + left, dx: x - pos.x, dy: -0.75em,
        block(width: m.right - 1.2cm, text(size: S().small, fill: q.ink-mid, {
          text(font: mono, fill: q.accent-deep, str(n))
          h(4pt)
          body
        }))))
    }
  }

  // Terms sorted and grouped by first letter. Each entry is (term, definition).
  let glossary(..entries) = context {
    let q = pal()
    let items = entries.pos().sorted(key: e => lower(if type(e.at(0)) == str { e.at(0) } else { repr(e.at(0)) }))
    let groups = (:)
    for e in items {
      let key = upper(if type(e.at(0)) == str { e.at(0).clusters().first() } else { "#" })
      groups.insert(key, groups.at(key, default: ()) + (e,))
    }
    for (letter, group) in groups {
      block(breakable: false, above: 0.9em, below: 0.9em, grid(
        columns: (1.6em, 1fr), column-gutter: 10pt,
        text(font: mono, size: S().h5, fill: q.accent-deep, letter),
        grid(columns: (30%, 1fr), column-gutter: 12pt, row-gutter: 7pt,
          ..group.map(((term, def)) => (text(weight: t.weight.h6, fill: q.ink-hi, term), def)).flatten()),
      ))
    }
  }

  let revision-history(..rows) = data-table(
    columns: (auto, auto, auto, 1fr),
    header: ([Version], [Date], [Author], [Change]),
    ..rows.pos().flatten(),
  )

  // Numbered list of information the author needs from someone else.
  let request-list(..rows) = data-table(
    columns: (auto, 1fr, auto, auto),
    header: ([No.], [Request], [Owner], [Needed by]),
    ..rows.pos().enumerate().map(((i, r)) => (str(i + 1), ..r)).flatten(),
  )

  // Furniture slot value: the level 1 heading in force on this page.
  let current-section = running-head

  // Part divider for handbooks: a full page that groups the chapters after it.
  let part(title, subtitle: none, accent: auto) = {
    _parts.step()
    pagebreak(weak: true)
    context {
      let q = palette(if accent == auto { accent-now() } else { accent }, "light")
      page(header: none, footer: none, background: none, {
        set align(left + horizon)
        text(font: mono, size: S().h4, fill: q.link, "Part " + std.numbering("I", _parts.get().first()))
        v(0.5em)
        text(size: S().display, weight: t.weight.h1, tracking: -0.015em, fill: q.ink-hi, title)
        if subtitle != none { v(0.8em); text(size: S().h4, fill: q.ink-mid, subtitle) }
      })
    }
  }

  // Letter: letterhead, recipient, date, subject, body, closing.
  let letter(
    sender: none,
    contact: (),
    recipient: none,
    date: datetime.today().display("[day] [month repr:long] [year]"),
    subject: none,
    closing: [Yours sincerely,],
    signature: none,
    paper: "a4",
    lang: "en",
    body,
  ) = {
    assert(paper in ("a4", "us-letter"), message: "centauri: paper must be a4 or us-letter")
    let q = t.light
    let sz = t.scales.document
    set document(title: subject)
    set text(font: t.fonts.sans, size: sz.body, weight: t.weight.body, fill: q.ink-mid, lang: lang)
    set par(leading: 0.72em, spacing: 1.15em)
    set strong(delta: t.weight.strong - t.weight.body)
    show link: set text(fill: q.link)
    set page(paper: paper, margin: (top: 2.2cm, bottom: 2.3cm, x: 2.4cm),
      footer: context if counter(page).final().first() > 1 {
        align(right, text(font: mono, size: sz.label + 0.5pt, fill: q.ink-mid, counter(page).display("1/1", both: true)))
      })
    if sender != none { text(size: sz.h4, weight: t.weight.h4, fill: q.ink-hi, sender) }
    if contact.len() > 0 {
      linebreak()
      text(font: mono, size: sz.label + 0.5pt, fill: q.ink-mid, contact.join("  ·  "))
    }
    v(0.4em)
    line(length: 100%, stroke: 0.5pt + q.hairline)
    v(1.4em)
    grid(columns: (1fr, auto), if recipient != none { text(fill: q.ink-hi, recipient) }, text(fill: q.ink-mid, date))
    v(1.6em)
    if subject != none { text(weight: t.weight.strong, fill: q.ink-hi, subject); v(0.6em) }
    body
    v(1.4em)
    closing
    if signature != none { v(2.6em); text(weight: t.weight.strong, fill: q.ink-hi, signature) }
  }

  (
    theme: t,
    tone: tone,
    centauri: centauri,
    cover: cover,
    annexes: annexes,
    serif: serif,
    pull-quote: pull-quote,
    epigraph: epigraph,
    drop-cap: drop-cap,
    sidenote: sidenote,
    glossary: glossary,
    revision-history: revision-history,
    request-list: request-list,
    current-section: current-section,
    part: part,
    use-accent: use-accent,
    with-accent: with-accent,
    palette: palette,
    accent-now: accent-now,
    size-now: S,
    letter: letter,
    code-themes: code-themes,
    label-text: label-text,
    pal: pal,

    todo: body => {
      _todos.step()
      context {
        let q = pal()
        box(fill: q.amber.fill, stroke: 0.5pt + q.amber.line, radius: 3pt, inset: (x: 3pt), outset: (y: 2.5pt), text(fill: q.ink-hi)[\[#body\]])
      }
    },
    // Deliberate gap, so it is neutral rather than amber, and stays visible at every stage.
    tba: body => context {
      let q = pal()
      box(fill: q.panel, stroke: 0.5pt + q.hairline, radius: 3pt, inset: (x: 3pt), outset: (y: 2.5pt), text(fill: q.ink-mid)[\[#body\]])
    },
    note: body => context if _stage.get() == "draft" {
      let q = pal()
      block(width: 100%, radius: t.radius.m, fill: q.sky.fill, stroke: 0.5pt + q.sky.line, inset: (x: 11pt, y: 8pt), breakable: true,
        text(size: S().small, fill: q.ink-mid)[#text(fill: q.sky.text, weight: t.weight.strong)[Drafting note.] #body])
    },
    req: body => context {
      let q = pal()
      block(above: 0.4em, below: 1em,
        text(size: S().small, fill: q.ink-mid)[#text(weight: t.weight.strong, _req-label.get()) #h(0.3em) #text(font: mono, body)])
    },

    chip: body => context {
      let q = pal()
      box(inset: (x: 4.5pt, y: 2pt), outset: (y: 0.8pt), radius: 5pt, fill: q.panel, stroke: 0.5pt + q.hairline-soft,
        text(font: mono, size: S().label + 0.5pt, fill: q.ink-mid, body))
    },
    pill: pill,
    status: word => {
      let (label, tone) = status-words.at(lower(word))
      pill(tone: tone, label)
    },
    delta: (direction: "up", body) => context {
      let q = pal()
      let s = if direction == "up" { q.mint } else { q.rose }
      box(inset: (x: 5pt, y: 1.8pt), outset: (y: 0.6pt), radius: t.radius.full, fill: s.fill, text(size: S().label + 1pt, weight: 550, fill: s.text, body))
    },
    callout: (tone: "amber", title: none, body) => context {
      let q = pal()
      let s = tone-of(q, tone)
      block(width: 100%, radius: t.radius.m, fill: s.fill, stroke: 0.5pt + s.line, inset: (x: 11pt, y: 9pt), breakable: false,
        grid(columns: (auto, 1fr), column-gutter: 8pt,
          text(weight: 600, fill: s.text)[!],
          text(size: S().small + 0.5pt)[#if title != none { text(weight: t.weight.strong, fill: s.text, title) + " " }#body]))
    },
    rule-note: body => context {
      let q = pal()
      block(above: 0.8em, below: 0.8em, inset: (left: 8pt, y: 2pt), stroke: (left: 1.5pt + q.accent-deep),
        text(font: mono, size: S().small - 0.5pt, fill: q.ink-mid, body))
    },
    card: body => context {
      let q = pal()
      block(width: 100%, radius: t.radius.l, stroke: 0.5pt + q.hairline, inset: 14pt, body)
    },
    kpi: (label, value, foot: none) => context {
      let q = pal()
      block(width: 100%, radius: t.radius.l, stroke: 0.5pt + q.hairline, inset: 13pt, breakable: false, stack(
        spacing: 8pt,
        label-text(q, label),
        text(size: S().kpi, weight: t.weight.kpi, tracking: -0.01em, fill: q.ink-hi, number-width: "tabular", value),
        block(height: 1.4em, text(size: S().small, fill: q.ink-mid, if foot == none { [] } else { foot })),
      ))
    },

    kv: (..pairs) => context kv-in(pal(), pairs.pos()),
    data-table: data-table,
    qa-table: (..rows) => data-table(
      columns: (auto, auto, 1fr),
      header: ([No.], [Reference], [Question]),
      ..rows.pos().enumerate().map(((i, r)) => (str(i + 1), r.at(0), r.at(1))).flatten(),
    ),
    compliance-matrix: (..rows) => data-table(
      columns: (auto, 1fr, auto, 1fr),
      header: ([Ref], [Requirement], [Status], [Response]),
      ..rows.pos().map(((r, q, s, a)) => {
        let (label, tone) = status-words.at(lower(s))
        (r, q, pill(tone: tone, label), a)
      }).flatten(),
    ),
    sig-block: (..parties) => context {
      let q = pal()
      grid(
        columns: (1fr, 1fr),
        column-gutter: 24pt,
        row-gutter: 24pt,
        ..parties.pos().map(party => block(breakable: false, {
          text(weight: t.weight.strong, fill: q.ink-hi, party)
          v(0.6em)
          for field in ("Name", "Title", "Signature", "Date") {
            grid(columns: (28%, 1fr), align: (left + bottom, left + bottom),
              label-text(q, field), block(height: 18pt, width: 100%, stroke: (bottom: 0.5pt + q.hairline)))
            v(2pt)
          }
        })),
      )
    },

    assumption: register("assumption"),
    dependency: register("dependency"),
    decision: register("decision"),
    risk: register("risk"),
    issue: register("issue"),
    register-table: kind => context {
      let q = pal()
      let entries = query(figure.where(kind: "centauri-" + kind))
      if entries.len() == 0 { return text(fill: q.ink-mid)[No entries.] }
      data-table(
        columns: (auto, 1fr, auto),
        align: (left + top, left + top, right + top),
        header: ([ID], [Statement], [Page]),
        ..entries.map(f => (
          link(f.location(), std.numbering(f.numbering, ..f.counter.at(f.location()))),
          f.caption.body,
          str(counter(page).at(f.location()).first()),
        )).flatten(),
      )
    },
  )
}

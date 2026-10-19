// Centauri's documents: the `centauri` template, page furniture, covers and the components.
// Everything reads the theme through `theme-now()`; src/theme.typ is Centauri's own.

#import "tokens.typ": contrast
#import "runtime.typ": tone as tone-state, _accent, _doc, _todos, resolve-colors, palette, sizes, furniture-on, theme-now, label-text
#import "theme.typ": centauri-theme
#import "schema.typ": validate

#let _rule-keys = ("header-rule", "footer-rule")
#let _slot-keys = ("left", "center", "right")
#let _register-kinds = (assumption: none, dependency: none, decision: none, risk: "caution", issue: "danger")

#let _rule-ok(v) = v == auto or v == none or type(v) in (stroke, length, color, dictionary)

/// Change page furniture from the next page on. `header` and `footer` take any of left,
/// center and right: content, none, or a function of no arguments called in context.
/// `header-rule` and `footer-rule` take a stroke, none, or auto for the theme's hairline.
/// `sensitivity` must be one of the theme's levels when it lists them. Left out, each is kept.
// Rules arrive as named sinks so that leaving one out (keep) differs from passing auto (default).
#let furniture(header: (:), footer: (:), sensitivity: auto, ..rules) = {
  assert(rules.pos().len() == 0, message: "centauri: furniture takes named arguments only")
  for (k, v) in rules.named() {
    assert(k in _rule-keys, message: "centauri: furniture takes header, footer, sensitivity, header-rule and footer-rule")
    assert(_rule-ok(v), message: "centauri: " + k + " must be a stroke, none or auto")
  }
  for (row, slots) in (header: header, footer: footer) {
    for k in slots.keys() { assert(k in _slot-keys, message: "centauri: furniture " + row + " slots are left, center and right") }
  }
  let change = (header: header, footer: footer) + rules.named()
  if sensitivity != auto {
    change.insert("sensitivity", sensitivity)
    context {
      let ls = _doc.get().theme.sensitivity.levels
      assert(ls == none or sensitivity == none or sensitivity in ls,
        message: "centauri: sensitivity " + repr(sensitivity) + " is not one of the theme's levels")
    }
  }
  [#metadata(change) <centauri-furniture>]
}

#let _escape(s) = s.replace(regex("[\\\\^$.|?*+()\\[\\]{}]"), m => "\\" + m.text)

#let _slot(v) = if type(v) == function { v() } else { v }

#let _row(slots) = grid(
  columns: (1fr, 1fr, 1fr),
  align: (left + horizon, center + horizon, right + horizon),
  _slot(slots.left), _slot(slots.center), _slot(slots.right),
)

#let _rule-stroke(r, t) = if r == auto { t.strokes.hairline + t.colors.hairline } else { r }

#let _header() = context {
  let t = theme-now()
  let f = furniture-on(_doc.get().theme, here().page())
  set text(fill: t.colors.ink-mid, size: t.sizes.small)
  _row(f.header)
  if f.header-rule != none {
    v(-4pt)
    line(length: 100%, stroke: _rule-stroke(f.header-rule, t))
  }
}

#let _footer() = context {
  let t = theme-now()
  let f = furniture-on(_doc.get().theme, here().page())
  set text(fill: t.colors.ink-mid, size: t.sizes.small)
  if f.footer-rule != none {
    line(length: 100%, stroke: _rule-stroke(f.footer-rule, t))
    v(-4pt)
  }
  _row(f.footer)
}

// Syntax highlighting generated from the palette, so code follows the accent and the tone.
#let _code-theme(q) = {
  let entry(scope, colour, style: none) = (
    "<dict><key>scope</key><string>" + scope + "</string><key>settings</key><dict><key>foreground</key><string>"
      + colour.to-hex() + "</string>" + if style != none { "<key>fontStyle</key><string>" + style + "</string>" } else { "" }
      + "</dict></dict>"
  )
  let rules = (
    "<dict><key>settings</key><dict><key>foreground</key><string>" + q.ink-hi.to-hex() + "</string></dict></dict>",
    entry("comment, punctuation.definition.comment", q.ink-low, style: "italic"),
    entry("keyword, storage, keyword.operator.word", q.accent-deep),
    entry("string, string.quoted, punctuation.definition.string", q.success.text),
    entry("constant.numeric, constant.language, constant.character", q.caution.text),
    entry("entity.name.function, support.function, meta.function-call", q.info.text),
    entry("entity.name.type, entity.name.class, support.type, support.class", q.charts.at(3)),
    entry("variable.parameter, meta.attribute", q.ink-mid),
    entry("invalid", q.danger.text),
  )
  bytes("<?xml version=\"1.0\" encoding=\"UTF-8\"?><plist version=\"1.0\"><dict><key>settings</key><array>" + rules.join() + "</array></dict></plist>")
}

// Every palette the theme can produce: its own colours and each accent, light and dark.
#let _palettes(t) = {
  let names = (none,) + if t.accents == none { () } else { t.accents.keys() }
  names.map(a => ("light", "dark").map(tn => resolve-colors(t, tn, a))).flatten()
}

#let _accent-ok(t, a) = {
  assert(a == none or (t.accents != none and a in t.accents),
    message: if t.accents == none { "centauri: this theme has no accents" } else {
      "centauri: accent must be one of " + t.accents.keys().join(", ")
    })
}

/// Checks every document and deck runs on its theme before it is used.
#let _check(t, accent) = {
  validate(t)
  _accent-ok(t, accent)
  for q in _palettes(t) {
    for g in (q.paper, q.cover) {
      assert(contrast(q.link, g) >= 4.5, message: "centauri: link colour " + q.link.to-hex() + " is below 4.5:1 on " + g.to-hex())
    }
  }
}

#let _tone-of(q, tn) = if tn == "mute" or tn == none {
  (text: q.ink-mid, fill: q.panel, line: q.hairline)
} else if tn == "accent" {
  (text: q.accent-deep, fill: q.accent-fill, line: q.hairline)
} else {
  q.at(tn)
}

/// The document template. `theme` defaults to Centauri's own.
#let _document(
  theme: auto,
  accent: auto,
  title: none,
  author: (),
  keywords: (),
  date: auto,
  lang: "en",
  region: none,
  paper: "a4",
  orientation: "portrait",
  columns: 1,
  stage: "draft",
  lint: (),
  numbering: "1.1",
  heading-numbers: "inline",
  body,
) = {
  let t = if theme == auto { centauri-theme } else { theme }
  let stage = sys.inputs.at("stage", default: stage)
  let accent = if accent == auto { none } else { accent }
  assert(paper in ("a4", "us-letter"), message: "centauri: paper must be a4 or us-letter")
  assert(orientation in ("portrait", "landscape"), message: "centauri: orientation must be portrait or landscape")
  assert(type(columns) == int and columns >= 1, message: "centauri: columns must be a whole number from 1")
  assert(stage in ("draft", "review", "final"), message: "centauri: stage must be draft, review or final")
  assert(heading-numbers in ("inline", "hang", "none"), message: "centauri: heading-numbers must be inline, hang or none")
  _check(t, accent)
  let doc = (theme: t, stage: stage, size: "document", heading-numbers: heading-numbers, columns: columns)
  let p = resolve-colors(t, "light", accent)
  let sz = sizes(t, "document")
  let g = t.page
  let w = t.type.weights

  set document(title: title, author: author, keywords: keywords, date: date)
  set text(font: t.fonts.body, size: sz.body, weight: w.body, fill: p.ink-mid, lang: lang, region: region, number-type: "lining")
  show heading: set text(number-width: "tabular")
  // Typesetting rules: no single word alone on a line, no stranded lines.
  set text(costs: (runt: 400%, widow: 200%, orphan: 200%))
  set par(justify: false, leading: 0.72em, spacing: 1.15em)
  set strong(delta: w.strong - w.body)
  set list(indent: 0.4em, body-indent: 0.6em, marker: text(fill: p.ink-low)[•])
  set enum(indent: 0.4em, body-indent: 0.6em)

  set page(
    paper: paper,
    flipped: orientation == "landscape",
    columns: columns,
    margin: (top: g.header-line + g.header-gap, bottom: g.footer-line + g.footer-gap, left: g.left, right: g.right),
    // The header's rule sits at its foot, raised `header-gap` above the body; the footer's
    // rule at its head, lowered `footer-gap` below it.
    header-ascent: g.header-gap,
    footer-descent: g.footer-gap,
    // The accent is left to the body: `use-accent` would otherwise be undone on every page.
    header: { _doc.update(doc); _header() },
    footer: _footer(),
    background: if stage == "draft" {
      place(center + horizon, rotate(-35deg, text(size: sz.watermark, weight: 600,
        fill: color.mix((p.ink-hi, 5%), (p.paper, 95%), space: rgb), tracking: 0.05em, t.words.draft)))
    },
  )

  set heading(numbering: numbering)
  show heading: it => context (t.at("h" + str(calc.min(it.level, 6))))(it)

  set outline(indent: auto, title: t.words.contents)
  show outline.entry.where(level: 1): set block(above: 1em)
  show outline.entry.where(level: 1): set text(weight: 500, fill: p.ink-hi)

  show link: it => context { set text(fill: theme-now().colors.link); it }
  set raw(theme: _code-theme(p))
  show raw: set text(font: t.fonts.code, size: sz.small)
  show raw.where(block: true): it => context {
    set raw(theme: _code-theme(theme-now().colors))
    (t.elements.raw)(it)
  }
  show quote.where(block: true): it => context (t.elements.quote)(it)
  show footnote.entry: it => context (t.elements.footnote)(it)

  set table(stroke: (_, y) => (bottom: t.strokes.hairline + p.hairline-soft), inset: (x: 6pt, y: 6pt))
  show table: set text(size: sz.small + 0.5pt, number-width: "tabular")

  show figure.caption: it => context (t.elements.caption)(it)

  // Register cards: the word and prefix come from the theme, so references read "Risk R1".
  show: body => t.words.registers.pairs().fold(body, (b, (k, r)) => {
    show figure.where(kind: "centauri-" + k): set figure(supplement: r.word, numbering: n => r.prefix + str(n))
    b
  })
  show figure: it => {
    let kind = if type(it.kind) == str and it.kind.starts-with("centauri-") { it.kind.slice(9) } else { none }
    if kind == none or kind not in _register-kinds { return it }
    let tn = _register-kinds.at(kind)
    context {
      let t = theme-now()
      let q = t.colors
      let s = _tone-of(q, tn)
      let upper-case = t.label-case == "upper"
      let id = std.numbering(it.numbering, ..it.counter.at(it.location()))
      block(width: 100%, breakable: false, above: 1em, below: 1em, inset: (x: 11pt, y: 9pt), radius: t.radius.m,
        fill: if tn == none { q.panel } else { s.fill },
        stroke: t.strokes.hairline + (if tn == none { q.hairline } else { s.line }),
        align(left, {
          let word = [#it.supplement #text(weight: 500, fill: if tn == none { q.accent-deep } else { s.text }, id)]
          text(font: t.fonts.label, size: t.sizes.label + 0.5pt, tracking: if upper-case { 0.18em } else { 0em },
            fill: if tn == none { q.ink-mid } else { s.text }, if upper-case { upper(word) } else { word })
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
        let q = theme-now().colors
        highlight(fill: q.danger.fill, stroke: t.strokes.hairline + q.danger.line, text(fill: q.danger.text, it))
      }
    }
    body
  }

  _doc.update(doc)
  _accent.update(accent)
  body

  context {
    let open = _todos.final().first()
    if stage == "final" and open > 0 {
      panic("centauri: " + str(open) + " unresolved todo placeholder(s) at stage final")
    }
  }
}

#let _kv(q, t, pairs) = {
  let n = pairs.len()
  table(
    columns: (32%, 1fr),
    stroke: (_, y) => (bottom: if y + 1 == n { none } else { t.strokes.hairline + q.hairline-soft }),
    inset: (x: 0pt, y: 6pt),
    align: (left + top, left + top),
    ..pairs.map(((k, v)) => (label-text(k), text(fill: q.ink-hi, v))).flatten(),
  )
}

/// Full-page cover. Its place in the document makes it a front cover, a divider or a back
/// cover. `accent` overrides the document accent for this page only. `backdrop` is drawn
/// behind the page: auto for the theme's, none, content (an image, say), or a function of no
/// arguments called in context with this page's tone.
#let cover(
  tone: "light",
  accent: auto,
  title: none,
  subtitle: none,
  meta: (),
  heading: false,
  furniture: true,
  backdrop: auto,
  ..rest,
) = {
  assert(rest.named().len() == 0, message: "centauri: cover has no parameter " + rest.named().keys().join(", "))
  let body = rest.pos().at(0, default: none)
  assert(tone in ("light", "dark"), message: "centauri: cover tone must be light or dark")
  context {
    let t = theme-now()
    let doc-accent = _accent.get()
    let a = if accent == auto { doc-accent } else { accent }
    _accent-ok(t, a)
    let q = palette(tone, a)
    let s = t.sizes
    let w = t.type.weights
    let set-tone = { tone-state.update(tone); _accent.update(a) }
    let bd = if backdrop == auto { t.elements.backdrop } else { backdrop }
    page(
      fill: q.cover,
      // The background and header are laid out before the body, so each sets the tone itself.
      background: { set-tone; if type(bd) == function { context bd() } else { bd } },
      footer: none,
      header: if furniture { set-tone; _header() } else { none },
    )[
      #set-tone
      #set text(fill: q.ink-mid)
      #show link: set text(fill: q.link)
      #show std.heading: it => text(font: t.fonts.heading, size: s.display, weight: w.h1, tracking: -0.015em, fill: q.ink-hi, it.body)
      #v(1fr)
      #if title != none {
        set par(leading: 0.4em)
        if heading { std.heading(level: 1, title) } else {
          text(font: t.fonts.heading, size: s.display, weight: w.h1, tracking: -0.015em, fill: q.ink-hi, title)
        }
      }
      #if subtitle != none {
        v(0.9em)
        text(size: s.h4, fill: q.ink-mid, subtitle)
      }
      #if body != none {
        v(1.2em)
        block(width: 78%, body)
      }
      #v(2fr)
      #if meta.len() > 0 {
        line(length: 100%, stroke: t.strokes.hairline + q.hairline)
        _kv(q, t, meta)
      }
      #tone-state.update("light")
      #_accent.update(doc-accent)
    ]
  }
}

/// Switch the accent from this point on.
#let use-accent(name) = {
  context _accent-ok(theme-now(), name)
  _accent.update(name)
}

/// Set `body` in another accent, then return to the accent that was in force.
#let with-accent(name, body) = context {
  _accent-ok(theme-now(), name)
  let before = _accent.get()
  _accent.update(name)
  body
  _accent.update(before)
}

/// Everything after it is an annex: heading numbers restart, level 1 in the first pattern and
/// lower levels in the second, and a reference prints `word` (the theme's by default) first.
#let annexes(word: auto, numbering: ("A", "A.1"), body) = {
  assert(type(numbering) == array and numbering.len() == 2, message: "centauri: annexes numbering takes two patterns, level 1 and below")
  counter(std.heading).update(0)
  let pattern = (..n) => {
    let n = n.pos()
    std.numbering(if n.len() == 1 { numbering.first() } else { numbering.last() }, ..n)
  }
  if word == auto {
    context {
      set std.heading(supplement: theme-now().words.annex, numbering: pattern)
      body
    }
  } else {
    set std.heading(supplement: word, numbering: pattern)
    body
  }
}

#let kv(..pairs) = context { let t = theme-now(); _kv(t.colors, t, pairs.pos()) }

#let pill(tone: "mute", dot: true, body) = context {
  let t = theme-now()
  let s = _tone-of(t.colors, tone)
  box(inset: (x: 6pt, y: 2.4pt), outset: (y: 0.6pt), radius: t.radius.full, fill: s.fill, stroke: t.strokes.hairline + s.line,
    text(size: t.sizes.label + 0.5pt, weight: 500, tracking: 0.02em, fill: s.text, {
      if dot { box(baseline: -0.22em, circle(radius: 1.7pt, fill: s.text)); h(3.5pt) }
      body
    }))
}

#let _status-tones = (compliant: "success", partial: "caution", exception: "danger", noted: "info")

/// A compliance status as a pill: compliant, partial, exception or noted.
#let status(word) = {
  let key = lower(word)
  assert(key in _status-tones, message: "centauri: status must be one of " + _status-tones.keys().join(", "))
  context pill(tone: _status-tones.at(key), theme-now().words.status.at(key))
}

#let data-table(columns: 1, align: auto, header: none, ..cells) = context {
  let t = theme-now()
  let q = t.colors
  let n = if type(columns) == int { columns } else { columns.len() }
  let cells = cells.pos()
  let h = if header == none { 0 } else { 1 }
  let last = h + calc.ceil(cells.len() / n) - 1
  table(
    columns: columns,
    align: if align == auto { left + top } else { align },
    stroke: (_, y) => (bottom: if y == last { none } else if y < h { t.strokes.rule + q.hairline } else { t.strokes.hairline + q.hairline-soft }),
    ..if header != none { (table.header(..header.map(c => label-text(c))),) },
    ..cells.enumerate().map(((i, c)) => if calc.rem(i, n) == 0 { text(fill: q.ink-hi, c) } else { c }),
  )
}

#let _register(kind) = body => figure(kind: "centauri-" + kind, caption: body, outlined: false, [])

#let assumption = _register("assumption")
#let dependency = _register("dependency")
#let decision = _register("decision")
#let risk = _register("risk")
#let issue = _register("issue")

#let register-table(kind) = context {
  let t = theme-now()
  let entries = query(figure.where(kind: "centauri-" + kind))
  if entries.len() == 0 { return text(fill: t.colors.ink-mid, t.words.no-entries) }
  data-table(
    columns: (auto, 1fr, auto),
    align: (left + top, left + top, right + top),
    header: t.words.tables.register-table,
    ..entries.map(f => (
      link(f.location(), std.numbering(f.numbering, ..f.counter.at(f.location()))),
      f.caption.body,
      str(counter(page).at(f.location()).first()),
    )).flatten(),
  )
}

#let _serif(body, size: auto) = context {
  let t = theme-now()
  text(font: t.fonts.quote, style: "italic", weight: 400, size: if size == auto { t.sizes.body } else { size }, tracking: 0.005em, body)
}

#let pull-quote(attribution: none, body) = context {
  let t = theme-now()
  let q = t.colors
  block(above: 1.6em, below: 1.6em, inset: (left: 14pt, y: 3pt), stroke: (left: t.strokes.emphasis + q.accent-deep), breakable: false, {
    set par(leading: 0.5em)
    _serif(size: t.sizes.h3, text(fill: q.ink-hi, body))
    if attribution != none { v(0.5em); label-text(attribution) }
  })
}

#let epigraph(attribution: none, body) = context {
  let t = theme-now()
  align(right, block(width: 62%, above: 1em, below: 2em, align(left, {
    _serif(size: t.sizes.h5, text(fill: t.colors.ink-hi, body))
    if attribution != none { v(0.4em); label-text(attribution) }
  })))
}

// Drop cap for the opening paragraph of a long-form piece. `body` is a plain
// string so the paragraph can be split where the capital ends.
#let drop-cap(lines: 3, gap: 4pt, body) = {
  assert(type(body) == str, message: "centauri: drop-cap takes the paragraph as a string")
  let first = body.clusters().first()
  let words = body.clusters().slice(1).join().split(" ")
  context {
    let t = theme-now()
    let leading = par.leading.to-absolute()
    let line-h = measure(text("X")).height
    let cap-h = line-h * lines + leading * (lines - 1)
    let cap = text(font: t.fonts.quote, size: cap-h * 1.38, fill: t.colors.ink-hi, top-edge: "cap-height", bottom-edge: "baseline", first)
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

// Terms sorted and grouped by first letter. Each entry is (term, definition).
#let glossary(..entries) = context {
  let t = theme-now()
  let items = entries.pos().sorted(key: e => lower(if type(e.at(0)) == str { e.at(0) } else { repr(e.at(0)) }))
  let groups = (:)
  for e in items {
    let key = upper(if type(e.at(0)) == str { e.at(0).clusters().first() } else { "#" })
    groups.insert(key, groups.at(key, default: ()) + (e,))
  }
  for (letter, group) in groups {
    block(breakable: false, above: 0.9em, below: 0.9em, grid(
      columns: (1.6em, 1fr), column-gutter: 10pt,
      text(font: t.fonts.label, size: t.sizes.h5, fill: t.colors.accent-deep, letter),
      grid(columns: (30%, 1fr), column-gutter: 12pt, row-gutter: 7pt,
        ..group.map(((term, def)) => (text(weight: t.type.weights.h6, fill: t.colors.ink-hi, term), def)).flatten()),
    ))
  }
}

#let revision-history(..rows) = context data-table(
  columns: (auto, auto, auto, 1fr),
  header: theme-now().words.tables.revision-history,
  ..rows.pos().flatten(),
)

// Numbered list of information the author needs from someone else.
#let request-list(..rows) = context data-table(
  columns: (auto, 1fr, auto, auto),
  header: theme-now().words.tables.request-list,
  ..rows.pos().enumerate().map(((i, r)) => (str(i + 1), ..r)).flatten(),
)

#let qa-table(..rows) = context data-table(
  columns: (auto, auto, 1fr),
  header: theme-now().words.tables.qa-table,
  ..rows.pos().enumerate().map(((i, r)) => (str(i + 1), r.at(0), r.at(1))).flatten(),
)

#let compliance-matrix(..rows) = context data-table(
  columns: (auto, 1fr, auto, 1fr),
  header: theme-now().words.tables.compliance-matrix,
  ..rows.pos().map(((r, q, s, a)) => (r, q, status(s), a)).flatten(),
)

#let sig-block(..parties) = context {
  let t = theme-now()
  let q = t.colors
  grid(
    columns: (1fr, 1fr),
    column-gutter: 24pt,
    row-gutter: 24pt,
    ..parties.pos().map(party => block(breakable: false, {
      text(weight: t.type.weights.strong, fill: q.ink-hi, party)
      v(0.6em)
      for field in t.words.sig-block {
        grid(columns: (28%, 1fr), align: (left + bottom, left + bottom),
          label-text(field), block(height: 18pt, width: 100%, stroke: (bottom: t.strokes.hairline + q.hairline)))
        v(2pt)
      }
    })),
  )
}

/// Placeholder for missing content, in caution brackets. The build stops at stage final while any remain.
#let todo(body) = {
  _todos.step()
  context {
    let q = theme-now().colors
    box(fill: q.caution.fill, stroke: 0.5pt + q.caution.line, radius: 3pt, inset: (x: 3pt), outset: (y: 2.5pt), text(fill: q.ink-hi)[\[#body\]])
  }
}

// Deliberate gap, so it is neutral rather than caution, and stays visible at every stage.
#let tba(body) = context {
  let q = theme-now().colors
  box(fill: q.panel, stroke: 0.5pt + q.hairline, radius: 3pt, inset: (x: 3pt), outset: (y: 2.5pt), text(fill: q.ink-mid)[\[#body\]])
}

#let note(body) = context {
  let t = theme-now()
  if t.stage != "draft" { return }
  let q = t.colors
  block(width: 100%, radius: t.radius.m, fill: q.info.fill, stroke: t.strokes.hairline + q.info.line, inset: (x: 11pt, y: 8pt), breakable: true,
    text(size: t.sizes.small, fill: q.ink-mid)[#text(fill: q.info.text, weight: t.type.weights.strong, t.words.drafting-note) #body])
}

/// A draft-only remark beside the point it is placed at. It takes no space, so nothing moves
/// when `review` and `final` drop it, and it never stops a build.
#let warn(body) = context {
  let t = theme-now()
  if t.stage != "draft" { return }
  let remark = text(size: t.sizes.label, fill: t.colors.danger.text, hyphenate: false, body)
  // The remark keeps its own width: inside the zero-width box it would break after every word.
  box(width: 0pt, height: 0pt, place(top + left, dy: 0.3em, box(width: measure(remark).width, remark)))
}

#let req(body) = context {
  let t = theme-now()
  block(above: 0.4em, below: 1em,
    text(size: t.sizes.small, fill: t.colors.ink-mid)[#text(weight: t.type.weights.strong, t.words.req) #h(0.3em) #text(font: t.fonts.label, body)])
}

#let chip(body) = context {
  let t = theme-now()
  box(inset: (x: 4.5pt, y: 2pt), outset: (y: 0.8pt), radius: 5pt, fill: t.colors.panel, stroke: t.strokes.hairline + t.colors.hairline-soft,
    text(font: t.fonts.label, size: t.sizes.label + 0.5pt, fill: t.colors.ink-mid, body))
}

#let delta(direction: "up", body) = context {
  let t = theme-now()
  let s = if direction == "up" { t.colors.success } else { t.colors.danger }
  box(inset: (x: 5pt, y: 1.8pt), outset: (y: 0.6pt), radius: t.radius.full, fill: s.fill, text(size: t.sizes.label + 1pt, weight: 550, fill: s.text, body))
}

#let callout(tone: "caution", title: none, body) = context {
  let t = theme-now()
  let s = _tone-of(t.colors, tone)
  block(width: 100%, radius: t.radius.m, fill: s.fill, stroke: t.strokes.hairline + s.line, inset: (x: 11pt, y: 9pt), breakable: false,
    grid(columns: (auto, 1fr), column-gutter: 8pt,
      text(weight: 600, fill: s.text)[!],
      text(size: t.sizes.small + 0.5pt)[#if title != none { text(weight: t.type.weights.strong, fill: s.text, title) + " " }#body]))
}

#let rule-note(body) = context {
  let t = theme-now()
  block(above: 0.8em, below: 0.8em, inset: (left: 8pt, y: 2pt), stroke: (left: t.strokes.emphasis + t.colors.accent-deep),
    text(font: t.fonts.label, size: t.sizes.small - 0.5pt, fill: t.colors.ink-mid, body))
}

#let card(body) = context {
  let t = theme-now()
  block(width: 100%, radius: t.radius.l, stroke: t.strokes.hairline + t.colors.hairline, inset: 14pt, body)
}

#let kpi(label, value, foot: none) = context {
  let t = theme-now()
  let q = t.colors
  block(width: 100%, radius: t.radius.l, stroke: t.strokes.hairline + q.hairline, inset: 13pt, breakable: false, stack(
    spacing: 8pt,
    label-text(label),
    text(size: t.sizes.kpi, weight: t.type.weights.kpi, tracking: -0.01em, fill: q.ink-hi, number-width: "tabular", value),
    block(height: 1.4em, text(size: t.sizes.small, fill: q.ink-mid, if foot == none { [] } else { foot })),
  ))
}

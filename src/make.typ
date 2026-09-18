#import "tokens.typ": contrast

/// Active page tone, "light" or "dark". Dark inside a dark cover.
#let tone = state("centauri-tone", "light")

#let _stage = state("centauri-stage", "draft")
#let _req-label = state("centauri-req-label", "Reference")
#let _section-word = state("centauri-section-word", "Section")
#let _todos = counter("centauri-todo")
#let _furniture = state("centauri-furniture", (
  header: (left: none, center: none, right: none),
  footer: (left: none, center: auto, right: none),
  sensitivity: none,
))

#let _register-kinds = (
  assumption: (word: "Assumption", prefix: "A", tone: none),
  dependency: (word: "Dependency", prefix: "D", tone: none),
  decision: (word: "Decision", prefix: "DEC", tone: none),
  risk: (word: "Risk", prefix: "R", tone: "amber"),
  issue: (word: "Issue", prefix: "I", tone: "rose"),
)

/// Update page furniture from this point on. Keys: left, center, right. Values: content, none, auto, or tone => content.
#let furniture(header: (:), footer: (:), sensitivity: auto) = _furniture.update(f => (
  header: f.header + header,
  footer: f.footer + footer,
  sensitivity: if sensitivity == auto { f.sensitivity } else { sensitivity },
))

#let _escape(s) = s.replace(regex("[\\\\^$.|?*+()\\[\\]{}]"), m => "\\" + m.text)

#let make(t) = {
  let p = t.light
  let mono = t.fonts.mono
  // `cover` shadows `tone` with its own parameter, so bind the state out here.
  let _tone = tone
  let pal() = if _tone.get() == "dark" { t.dark } else { t.light }

  let label-text(q, body, size: t.size.label) = text(font: mono, size: size, tracking: 0.16em, weight: 400, fill: q.ink-mid, upper(body))

  let tone-of(q, tone) = if tone == "mute" or tone == none {
    (text: q.ink-mid, fill: q.panel, line: q.hairline)
  } else if tone == "accent" {
    (text: q.accent-deep, fill: q.accent-fill, line: q.hairline)
  } else {
    q.at(tone)
  }

  let eyebrow-in(q, ..parts) = {
    let parts = parts.pos()
    text(font: mono, size: t.size.label + 0.5pt, tracking: 0.22em, fill: q.ink-mid, upper[
      ( #text(fill: q.link, weight: 500, parts.first())#for part in parts.slice(1) [ · #part] )
    ])
  }

  let slot(value, tone, q, sensitivity, is-footer-center) = {
    if type(value) == function { value(tone) } else if value == auto and is-footer-center {
      text(font: mono, size: t.size.label + 0.5pt, fill: q.ink-mid)[
        #counter(page).display("1/1", both: true)#if sensitivity != none [ | #sensitivity]
      ]
    } else if value == auto { none } else { value }
  }

  let row(f, slots, tone, q, footer) = grid(
    columns: (1fr, 1fr, 1fr),
    align: (left + horizon, center + horizon, right + horizon),
    slot(slots.left, tone, q, f.sensitivity, false),
    slot(slots.center, tone, q, f.sensitivity, footer),
    slot(slots.right, tone, q, f.sensitivity, false),
  )

  // Header and footer both read furniture as it stood at the top of the page.
  let header-for(q, tone) = context {
    [#metadata(none) <centauri-page-top>]
    let f = _furniture.get()
    set text(fill: q.ink-mid, size: t.size.small)
    row(f, f.header, tone, q, false)
    v(-4pt)
    line(length: 100%, stroke: 0.5pt + q.hairline)
  }

  let footer-for(q, tone) = context {
    let page = here().page()
    let tops = query(<centauri-page-top>).filter(m => m.location().page() == page)
    let f = if tops.len() > 0 { _furniture.at(tops.first().location()) } else { _furniture.get() }
    set text(fill: q.ink-mid, size: t.size.small)
    line(length: 100%, stroke: 0.5pt + q.hairline)
    v(-4pt)
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

  let serif-em(body) = text(font: t.fonts.serif, style: "italic", weight: 400, tracking: 0.005em, body)

  let centauri(
    title: none,
    author: (),
    keywords: (),
    date: auto,
    lang: "en",
    region: none,
    paper: "a4",
    stage: "draft",
    lint: (),
    numbering: "1.1",
    section-word: "Section",
    h1-pagebreak: true,
    header: (:),
    footer: (:),
    sensitivity: none,
    req-label: "Reference",
    body,
  ) = {
    let stage = sys.inputs.at("stage", default: stage)
    assert(stage in ("draft", "review", "final"), message: "centauri: stage must be draft, review or final")
    for q in (t.light, t.dark) {
      for g in (q.paper, q.cover) {
        assert(contrast(q.link, g) >= 4.5, message: "centauri: link colour " + q.link.to-hex() + " is below 4.5:1 on " + g.to-hex())
      }
    }

    set document(title: title, author: author, keywords: keywords, date: date)
    set text(font: t.fonts.sans, size: t.size.body, weight: t.weight.body, fill: p.ink-mid, lang: lang, region: region, number-type: "lining")
    set par(justify: false, leading: 0.72em, spacing: 1.15em)
    set strong(delta: t.weight.strong - t.weight.body)
    set list(indent: 0.4em, body-indent: 0.6em, marker: text(fill: p.ink-low)[•])
    set enum(indent: 0.4em, body-indent: 0.6em)

    set page(
      paper: paper,
      margin: (top: 2.7cm, bottom: 2.3cm, x: 2cm),
      header-ascent: 35%,
      footer-descent: 35%,
      header: header-for(p, "light"),
      footer: footer-for(p, "light"),
      background: if stage == "draft" {
        place(center + horizon, rotate(-35deg, text(size: t.size.watermark, weight: 600, fill: color.mix((p.ink-hi, 5%), (p.paper, 95%), space: rgb), tracking: 0.05em)[DRAFT]))
      },
    )

    _stage.update(stage)
    _req-label.update(req-label)
    _section-word.update(section-word)
    furniture(header: header, footer: footer, sensitivity: sensitivity)

    set heading(numbering: numbering)
    show heading: set text(fill: p.ink-hi)
    show heading.where(level: 1): it => {
      if h1-pagebreak { pagebreak(weak: true) }
      block(above: 0.4em, below: 1.3em, width: 100%, {
        if it.numbering != none {
          context eyebrow-in(p, _section-word.get() + " " + std.numbering(it.numbering, ..counter(heading).at(it.location())))
          v(-0.2em)
        }
        text(size: t.size.h1, weight: t.weight.h1, tracking: -0.015em, it.body)
      })
    }
    show heading.where(level: 2): it => block(above: 1.8em, below: 0.8em, sticky: true, {
      if it.numbering != none {
        text(font: mono, size: t.size.small, fill: p.ink-mid, std.numbering(it.numbering, ..counter(heading).at(it.location())))
        h(0.7em)
      }
      text(size: t.size.h2, weight: t.weight.h2, tracking: -0.01em, it.body)
    })
    show heading.where(level: 3): it => block(above: 1.4em, below: 0.6em, sticky: true, {
      if it.numbering != none {
        text(font: mono, size: t.size.small - 0.5pt, fill: p.ink-mid, std.numbering(it.numbering, ..counter(heading).at(it.location())))
        h(0.6em)
      }
      text(size: t.size.h3, weight: t.weight.h3, it.body)
    })

    set outline(indent: auto, title: [Contents])
    show outline.entry.where(level: 1): set block(above: 1em)
    show outline.entry.where(level: 1): set text(weight: 500, fill: p.ink-hi)

    show link: it => context { set text(fill: pal().link); it }
    set raw(theme: none)
    show raw: set text(font: mono, size: 8.5pt)
    show raw.where(block: true): it => context {
      let q = pal()
      block(width: 100%, fill: q.panel, stroke: 0.5pt + q.hairline-soft, radius: t.radius.m, inset: 9pt, it)
    }

    set table(stroke: (_, y) => (bottom: 0.5pt + p.hairline-soft), inset: (x: 6pt, y: 6pt))
    show table: set text(size: t.size.small + 0.5pt, number-width: "tabular")

    show figure.caption: it => context {
      let q = pal()
      block(width: 100%, align(left, text(size: t.size.small, fill: q.ink-mid, {
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
            text(font: mono, size: t.size.label + 0.5pt, tracking: 0.18em, fill: if spec.tone == none { q.ink-mid } else { s.text }, upper[#spec.word #text(weight: 500, fill: if spec.tone == none { q.accent-deep } else { s.text }, id)])
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
    }
  }

  let cover(
    tone: "light",
    eyebrow: none,
    title: none,
    subtitle: none,
    meta: (),
    heading: false,
    furniture: true,
    bloom: auto,
    ..rest,
  ) = {
    let body = rest.pos().at(0, default: none)
    assert(tone in ("light", "dark"), message: "centauri: cover tone must be light or dark")
    let q = if tone == "dark" { t.dark } else { t.light }
    let bloom = if bloom == auto { tone == "dark" } else { bloom }
    let fill = if bloom {
      gradient.radial(color.mix((q.accent, 24%), (q.cover, 76%), space: rgb), q.cover, center: (8%, 4%), radius: 95%)
    } else { q.cover }

    page(
      fill: fill,
      background: none,
      footer: none,
      header: if furniture { header-for(q, tone) } else { none },
    )[
      #_tone.update(tone)
      #set text(fill: q.ink-mid)
      #show link: set text(fill: q.link)
      #show std.heading: it => text(size: t.size.cover - 6pt, weight: t.weight.h1, tracking: -0.015em, fill: q.ink-hi, it.body)
      #v(1fr)
      #if eyebrow != none or heading {
        if eyebrow != none { eyebrow-in(q, ..if type(eyebrow) == array { eyebrow } else { (eyebrow,) }) } else {
          context {
            let h = query(selector(std.heading).after(here())).first()
            if h.numbering != none {
              eyebrow-in(q, _section-word.get() + " " + std.numbering(h.numbering, ..counter(std.heading).at(h.location())))
            }
          }
        }
        v(0.6em)
      }
      #if title != none {
        set par(leading: 0.4em)
        if heading { std.heading(level: 1, title) } else {
          text(size: t.size.cover, weight: t.weight.h1, tracking: -0.015em, fill: q.ink-hi, title)
        }
      }
      #if subtitle != none {
        v(0.9em)
        text(size: 13pt, fill: q.ink-mid, subtitle)
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
    ]
  }

  let annexes(body) = {
    counter(std.heading).update(0)
    _section-word.update("Annex")
    set std.heading(numbering: (..n) => {
      let n = n.pos()
      if n.len() == 1 { std.numbering("A", ..n) } else { std.numbering("A.1", ..n) }
    })
    body
  }

  let pill(tone: "mute", dot: true, body) = context {
    let s = tone-of(pal(), tone)
    box(inset: (x: 6pt, y: 2.4pt), outset: (y: 0.6pt), radius: t.radius.full, fill: s.fill, stroke: 0.5pt + s.line,
      text(size: t.size.label + 0.5pt, weight: 500, tracking: 0.02em, fill: s.text, {
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

  (
    theme: t,
    tone: tone,
    centauri: centauri,
    cover: cover,
    annexes: annexes,
    serif-em: serif-em,
    eyebrow: (..parts) => context eyebrow-in(pal(), ..parts),

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
        text(size: t.size.small, fill: q.ink-mid)[#text(fill: q.sky.text, weight: t.weight.strong)[Drafting note.] #body])
    },
    req: body => context {
      let q = pal()
      block(above: 0.4em, below: 1em,
        text(font: mono, size: t.size.label + 0.5pt, fill: q.ink-mid)[( #text(tracking: 0.16em, upper(_req-label.get())) · #body )])
    },

    chip: body => context {
      let q = pal()
      box(inset: (x: 4.5pt, y: 2pt), outset: (y: 0.8pt), radius: 5pt, fill: q.panel, stroke: 0.5pt + q.hairline-soft,
        text(font: mono, size: t.size.label + 0.5pt, fill: q.ink-mid, body))
    },
    pill: pill,
    status: word => {
      let (label, tone) = status-words.at(lower(word))
      pill(tone: tone, label)
    },
    delta: (direction: "up", body) => context {
      let q = pal()
      let s = if direction == "up" { q.mint } else { q.rose }
      box(inset: (x: 5pt, y: 1.8pt), outset: (y: 0.6pt), radius: t.radius.full, fill: s.fill, text(size: t.size.label + 1pt, weight: 550, fill: s.text, body))
    },
    callout: (tone: "amber", title: none, body) => context {
      let q = pal()
      let s = tone-of(q, tone)
      block(width: 100%, radius: t.radius.m, fill: s.fill, stroke: 0.5pt + s.line, inset: (x: 11pt, y: 9pt), breakable: false,
        grid(columns: (auto, 1fr), column-gutter: 8pt,
          text(weight: 600, fill: s.text)[!],
          text(size: t.size.small + 0.5pt)[#if title != none { text(weight: t.weight.strong, fill: s.text, title) + " " }#body]))
    },
    rule-note: body => context {
      let q = pal()
      block(above: 0.8em, below: 0.8em, inset: (left: 8pt, y: 2pt), stroke: (left: 1.5pt + q.accent-deep),
        text(font: mono, size: t.size.small - 0.5pt, fill: q.ink-mid, body))
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
        text(size: t.size.kpi, weight: t.weight.kpi, tracking: -0.01em, fill: q.ink-hi, number-width: "tabular", value),
        block(height: 1.4em, text(size: t.size.small, fill: q.ink-mid, if foot == none { [] } else { foot })),
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

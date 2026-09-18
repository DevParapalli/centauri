#import "/lib.typ": *

#let t = theme()

// Placeholder marks. Real documents pass image(...) or a tone => image(...) function.
#let mark(name) = tone => {
  let q = if tone == "dark" { t.dark } else { t.light }
  box(inset: (x: 7pt, y: 3.5pt), radius: 999pt, stroke: 0.5pt + q.ink-low,
    text(font: t.fonts.mono, size: 6.5pt, tracking: 0.18em, fill: q.ink-mid, upper(name)))
}

#let swatch(c) = box(width: 16pt, height: 9pt, radius: 2pt, fill: c, stroke: 0.5pt + t.light.hairline, baseline: 1.5pt)
#let ratio(a, b) = str(calc.round(contrast(a, b), digits: 2)) + ":1"

#show: centauri.with(
  title: "Centauri showcase",
  author: "Devansh Parapalli",
  keywords: ("centauri", "proxima", "typst"),
  stage: "draft",
  lint: ("\u{2014}",),
  header: (left: mark("Logo left"), right: mark("Logo right")),
  sensitivity: "Public",
  req-label: "Reference",
)

#cover(
  eyebrow: ("Centauri", "Print design system"),
  title: [Centauri #serif-em[showcase]],
  subtitle: [Light-first print design system derived from Proxima.],
  meta: (
    ([Version], [0.1.0]),
    ([Stage], [draft by default; override with `--input stage=review` or `final`]),
    ([Fonts], [Outfit, Instrument Serif, IBM Plex Mono (OFL-1.1)]),
    ([Licence], [MIT]),
    ([Compiler], [Typst 0.15]),
  ),
)[
  This document exercises every component in Centauri 0.1.0. Each section states what the component does, then renders it.
]

#outline(depth: 2)

= Page furniture

Every inner page has three slots above the header rule and three below the footer rule. Each slot takes content, `none`, `auto`, or a function of the page tone, so a logo can swap between light and dark versions on covers.

#data-table(
  columns: (auto, 1fr, 1fr, 1fr),
  header: ([Row], [Left], [Center], [Right]),
  [Header], [Logo], [Empty], [Logo],
  [Footer], [Empty], [`auto`: page as 1/N, then the sensitivity label], [Empty],
)

Set the starting furniture on the template. Change it at any point with `furniture()`; keys not passed keep their current value. An update takes effect from the next page header and footer.

```typ
#show: centauri.with(
  lint: ("\u{2014}",),
  header: (left: image("our-logo.svg", height: 14pt), right: image("group.svg", height: 18pt)),
  sensitivity: "Internal",
)

#furniture(
  footer: (left: image("client.svg", height: 11pt), right: [Prepared for Example Client RFP response]),
  sensitivity: "Confidential",
)
```

The next page applies that client configuration, with a placeholder standing in for the client logo.

#furniture(
  footer: (left: mark("Client logo"), right: [Prepared for Example Client RFP response]),
  sensitivity: "Confidential",
)
#pagebreak()

== Client configuration in effect

This page shows the client logo slot at bottom left, the access note at bottom right, and the sensitivity label after the page number. The configuration stays in force until the next `furniture()` call. The components section below restores the default footer.

#kv(
  ([Header left], [Logo slot]),
  ([Header right], [Logo slot]),
  ([Footer left], [Client logo]),
  ([Footer center], [`auto`: 1/N | Confidential]),
  ([Footer right], [Prepared for Example Client RFP response]),
)

#furniture(footer: (left: none, right: none), sensitivity: "Public")

#cover(tone: "dark", title: [Components], heading: true)[
  Covers take a light or dark tone per call and can appear anywhere. With `heading: true` the title becomes a numbered level 1 heading, listed in the contents.

  Components read the active tone from `tone`, so they carry the dark palette here without taking an argument.

  #kpi([Services up], [31 / 33], foot: [The same component, dark palette])

  #pill(tone: "mint")[Healthy] #h(4pt) #pill(tone: "amber")[Degraded] #h(4pt) #status("compliant") #h(4pt) #chip[INC-20417]
]

== Typography

Outfit carries all text at weight 380 for body and 480 to 540 for headings. IBM Plex Mono sets labels, identifiers and machine output. Instrument Serif appears at most once per page, through #serif-em[serif-em]. Body copy uses #strong[strong emphasis] sparingly, and links such as #link("https://typst.app")[typst.app] take the contrast-checked link colour.

#eyebrow("Eyebrow", "Context")

- Lists use a quiet marker in the low ink colour.
- Facts such as ports, sizes and IDs use a chip: #chip[5432] #chip[INC-20417] #chip[n2-standard-8]
- Inline code reads as `typst compile --font-path fonts showcase.typ`.

#rule-note[A rule note sets supporting detail in mono beside an accent rule.]

#req[RFP §2.1, §4.3]

=== Third-level heading

Level 3 headings sit in the body size at a heavier weight. Numbering uses the `numbering` parameter; `section-word` sets the word in the level 1 eyebrow.

== Colour and contrast

Neutrals lean blue and one saturated accent owns emphasis. Alpha tokens from Proxima are flattened onto their ground so every fill is opaque in print.

#data-table(
  columns: (1fr, auto, auto, auto, auto),
  header: ([Token], [Light], [], [Dark], []),
  ..("paper", "cover", "panel", "ink-hi", "ink-mid", "ink-low", "hairline", "accent", "accent-deep", "link").map(k => (
    raw(k),
    swatch(t.light.at(k)), raw(t.light.at(k).to-hex()),
    swatch(t.dark.at(k)), raw(t.dark.at(k).to-hex()),
  )).flatten(),
)

Link colour is chosen per accent as the first of accent, accent-deep and ink that reaches 4.5:1 on both the page and the cover ground. Compilation stops if a theme override breaks that.

#data-table(
  columns: (auto, auto, 1fr, auto, auto, 1fr),
  align: (left, left, left, right, left, right),
  header: ([Accent], [Light link], [], [Page / cover], [Dark link], [Ratio]),
  ..accents.keys().map(a => {
    let th = theme(accent: a)
    (
      raw(a),
      swatch(th.light.link), raw(th.light.link.to-hex()),
      ratio(th.light.link, th.light.paper) + " / " + ratio(th.light.link, th.light.cover),
      swatch(th.dark.link), ratio(th.dark.link, th.dark.paper),
    )
  }).flatten(),
)

State text is darkened toward ink when needed so every pill reaches 4.5:1 on its own fill.

#data-table(
  columns: (auto, auto, auto, 1fr),
  align: (left, left, left, right),
  header: ([State], [Sample], [Meaning], [Text on fill]),
  ..(("mint", "Fine"), ("amber", "Look at this soon"), ("rose", "Broken or destructive"), ("sky", "Information")).map(((k, m)) => (
    raw(k), pill(tone: k)[#m], m, ratio(t.light.at(k).text, t.light.at(k).fill),
  )).flatten(),
)

Pick an accent by building the components from a theme:

```typ
#import "@preview/centauri:0.1.0": make, theme
#let (centauri, cover, pill, ..rest) = make(theme(accent: "teal"))
```

== Status and emphasis

Every state colour carries a word and a dot. Rose is reserved for broken or destructive states.

#pill(tone: "mint")[Healthy] #h(4pt) #pill(tone: "amber")[Degraded] #h(4pt) #pill(tone: "rose")[Down] #h(4pt) #pill(tone: "sky")[Scheduled] #h(4pt) #pill(tone: "mute")[Archived] #h(4pt) #pill(tone: "accent")[Selected]

Compliance words map to fixed tones: #status("compliant") #h(3pt) #status("partial") #h(3pt) #status("exception") #h(3pt) #status("noted")

#grid(
  columns: (1fr, 1fr, 1fr),
  column-gutter: 10pt,
  kpi([Services up], [31 / 33], foot: [#delta(direction: "down")[2 down] across 4 hosts]),
  kpi([Cost run rate], [\$18.4k], foot: [#delta[−6.1%] month on month]),
  kpi([P1 incidents], [0], foot: [Last 30 days]),
)

#callout(tone: "amber", title: [Heads up.])[Callouts hold one short message with a bold lead.]
#callout(tone: "sky", title: [For information.])[Sky marks neutral information.]
#callout(tone: "mint", title: [Confirmed.])[Mint confirms that something is fine.]
#callout(tone: "rose", title: [Blocked.])[Rose is kept for failures and destructive actions.]

#card[
  A card groups related content inside a hairline border at the large radius. It has no fill, so it prints cleanly on white paper.
]

== Tables

`data-table` sets mono header labels, a hairline under the header and soft separators between rows. The header repeats when a table breaks across pages, and numbers use tabular figures.

#data-table(
  columns: (1fr, auto, auto, auto),
  align: (left, right, right, right),
  header: ([Workstream], [FTE], [Offshore], [Monthly cost]),
  [Observability platform], [6.0], [80%], [\$41,200],
  [Incident management], [4.5], [70%], [\$33,850],
  [Tooling and automation], [2.0], [90%], [\$12,400],
  [Total], [12.5], [78%], [\$87,450],
)

`kv` lists label and value pairs.

#kv(
  ([Submitted to], [Example Client, Global Procurement]),
  ([Bid validity], [180 days from the submission deadline (RFP §0.10)]),
  ([Contact], [#link("mailto:hey@parapalli.dev")[hey\@parapalli.dev]]),
)

A `figure` caption sets the supplement and number in mono above the caption text, left aligned, below the content. A `data-table` resolves its palette in a context block, so Typst cannot see the table inside it; pass `kind: table` to have the figure counted and labelled as a table.

#figure(
  kind: table,
  supplement: [Table],
  data-table(
    columns: (1fr, auto, auto),
    align: (left, left, right),
    header: ([Region], [Cover], [Engineers]),
    [EU], [24x7], [14],
    [US], [24x7], [11],
    [APJ], [Business hours], [6],
  ),
  caption: [Coverage by region.],
)

#figure(
  block(width: 100%, inset: (y: 4pt), grid(
    columns: t.light.charts.len() * (1fr,),
    column-gutter: 5pt,
    ..t.light.charts.map(c => rect(width: 100%, height: 22pt, radius: 2pt, fill: c, stroke: none)),
  )),
  caption: [The five chart colours, held in `charts` on each palette.],
)

`qa-table` numbers clarification questions.

#qa-table(
  ([RFP §3.2], [Does the managed capacity include weekend on-call cover, or is it priced separately?]),
  ([Appendix B, row 14], [Confirm whether the monthly volume figures are averages or peaks.]),
)

`compliance-matrix` pairs each requirement with a status and a response pointer.

#compliance-matrix(
  ([4.1], [24x7 monitoring of production estates], "compliant", [Section 2.2]),
  ([4.2], [Named engineer per region], "partial", [Named leads for EU and US; APJ covered from EU]),
  ([4.7], [On-site presence at client headquarters], "exception", [Remote delivery with quarterly visits]),
  ([4.9], [Quarterly service review], "noted", [Annex B]),
)

== Registers

Registers are numbered per kind, can be referenced with labels, and are collected into register tables in the annex. Assumption, dependency and decision entries are neutral; risk uses amber and issue uses rose.

#assumption[Client provides read access to existing dashboards within two weeks of contract signature.] <asm-access>

#dependency[Single sign-on integration depends on the client identity team completing the SAML metadata exchange.] <dep-sso>

#decision[Delivery management cost is embedded in each workstream price rather than priced separately.] <dec-dm>

#risk[Alert volume exceeds the sizing baseline in the first quarter, which delays noise reduction.] <risk-volume>

#issue[Historical incident data before 2025 is unavailable for trend analysis.] <iss-history>

References resolve to the register ID: pricing relies on @asm-access and @dec-dm, and @risk-volume is mitigated through the tooling workstream.

#cover(tone: "light", title: [Drafting controls], heading: true)[
  A light section cover, placed mid-document. Stages, placeholders and lint keep unfinished material from reaching a submitted version.
]

== Stages

The stage comes from `--input stage=...` when given, otherwise from the `stage` parameter.

#data-table(
  columns: (auto, 1fr, 1fr, 1fr),
  header: ([Behaviour], [draft], [review], [final]),
  [Watermark], [Shown], [Hidden], [Hidden],
  [Drafting notes], [Shown], [Hidden], [Hidden],
  [Open `todo`], [Highlighted], [Highlighted], [Compilation fails],
  [Lint matches], [Highlighted], [Highlighted], [Compilation fails],
  [Link contrast below 4.5:1], [Compilation fails], [Compilation fails], [Compilation fails],
)

== Placeholders and notes

`todo` marks information still to be supplied, for example a price of #todo[monthly price, EUR] per engineer. `tba` marks a deliberate gap the reader is meant to see, such as service levels #tba[to be agreed at SOW stage]; it is not counted.

#note[Drafting notes carry guidance for authors. They render only at stage draft.]

== Lint

The `lint` parameter lists strings that must not appear. This document forbids the em dash. The next sentence contains one — so draft and review highlight it, and a final build fails.

#show: annexes

= Register tables

== Assumptions
#register-table("assumption")

== Dependencies
#register-table("dependency")

== Decisions
#register-table("decision")

== Risks and issues
#register-table("risk")
#register-table("issue")

= Signatures

#sig-block([For the supplier], [For Example Client])

#cover(
  tone: "dark",
  eyebrow: ("End", "Centauri 0.1.0"),
  title: [Thank #serif-em[you]],
  meta: (
    ([Source], [Centauri, derived from the #link("https://proxima.parapalli.dev","proxima.parapalli.dev") design system]),
    ([Contact], [#link("mailto:hey@parapalli.dev")[hey\@parapalli.dev]]),
  ),
)

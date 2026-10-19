# Centauri 0.4.0 reference

This document is the complete reference for authoring with Centauri. It is written for people and for AI agents that generate Centauri documents and decks, and for anyone building a brand package on Centauri. Every name that `lib.typ` exports has its own `###` entry below; `tests/run.py` fails when an export is undocumented or a documented name is not exported.

The key words MUST, MUST NOT, SHOULD, SHOULD NOT and MAY are to be interpreted as described in RFC 2119.

- Design rationale for decks is in [`deck-board.md`](deck-board.md). It explains why; this file states what.
- The top-level [`README.md`](../README.md) is the overview. Where the two differ, this file is authoritative.

## Contents

1. [Setup](#1-setup)
2. [Build rules](#2-build-rules)
3. [Documents](#3-documents)
4. [Document components](#4-document-components)
5. [Decks](#5-decks)
6. [Slides](#6-slides)
7. [Slide helpers](#7-slide-helpers)
8. [Themes](#8-themes)
9. [Recipes](#9-recipes)
10. [Authoring checklist](#10-authoring-checklist)

---

## 1. Setup

### Import

```typ
#import "@preview/centauri:0.4.0": *
```

Against a checkout, import the entry file and set `--root` to a directory that contains both the document and the checkout:

```typ
#import "/centauri/lib.typ": *
```

### Fonts

Documents MUST be compiled with the theme's fonts available. Without them Typst substitutes other fonts and page breaks change.

```sh
typst compile --font-path fonts document.typ
```

Centauri's own theme sets Atkinson Hyperlegible Next (text and headings), Atkinson Hyperlegible Mono (labels and code) and Newsreader (quotations, drop caps). All are OFL-1.1 and ship in `fonts/` of the source repository. A brand theme names its own faces in `fonts`, and its documents are compiled with the brand's font path.

### Compile-time inputs

| Input | Values | Applies to | Effect |
|---|---|---|---|
| `stage` | `draft`, `review`, `final` | documents | Overrides the `stage:` argument. |
| `mode` | `slides` (default), `handout`, `titles` | decks | Output mode; see [Decks](#5-decks). |
| `notes` | `true`, `false` (default) | decks, `slides` mode | Shows speaker notes on the slides. |

```sh
typst compile --font-path fonts --input stage=final report.typ
typst compile --font-path fonts --input mode=handout deck.typ deck-handout.pdf
```

---

## 2. Build rules

Centauri stops the build rather than produce a document that breaks its rules. An author or agent MUST treat each of these as a hard constraint and change the content, not the rule.

| Condition | Error text contains | Fix |
|---|---|---|
| `todo[...]` remains at stage `final` | `unresolved todo placeholder(s)` | Resolve every `todo`. Use `tba` for a deliberate gap. |
| A `lint` string appears at stage `final` | `lint match` | Remove the text. |
| A slide's content runs onto a second page | `overflows its page` | Cut the content or split the slide. Sizes never shrink to fit. |
| A slide title ends with a full stop | `ends with a full stop` | Remove the full stop. |
| A theme puts a link colour below 4.5:1 on the page or cover | `below 4.5:1` | Choose a darker link colour. |
| A theme key is misspelled, or a written-out theme leaves one out | `unknown theme key`, `theme is missing` | Use the keys in [Themes](#8-themes). |
| A sensitivity is not one of the theme's `levels` | `is not one of the theme's levels` | Use a listed level. |
| An accent is asked of a theme without it | `has no accents`, `accent must be one of` | Use one of the theme's accents. |
| An argument is outside its allowed values | `must be` | Use a listed value. |

A clean build SHOULD also produce no warnings. A warning such as `document did not converge` indicates a defect in Centauri, not in the document, and SHOULD be reported.

---

## 3. Documents

A document is set up once with a show rule. `kind` defaults to `"document"`.

```typ
#show: centauri.with(title: "Quarterly review", stage: "review")
```

Where the content goes is the author's: a level 1 heading does not start a page, so a document that wants one per page puts `#pagebreak()` before it. Covers, dividers and back covers are [`cover`](#cover) calls placed where they belong.

### `centauri`

The single entry point. `kind` is `"document"` (the default) or `"deck"`; any other value stops the build. With `kind: "deck"` it takes the arguments in [Decks](#5-decks); otherwise these:

| Argument | Default | Values and effect |
|---|---|---|
| `theme` | `auto` | A theme dictionary; `auto` is [`centauri-theme`](#centauri-theme). See [Themes](#8-themes). |
| `accent` | `auto` | One of the theme's `accents`; `auto` keeps the theme's own colours. |
| `title` | `none` | Document metadata title. It is not printed; use [`cover`](#cover) for a printed title. |
| `author` | `()` | Metadata. |
| `keywords` | `()` | Metadata. |
| `date` | `auto` | Metadata date. |
| `lang`, `region` | `"en"`, `none` | Text language and region. |
| `paper` | `"a4"` | `"a4"` or `"us-letter"`. |
| `orientation` | `"portrait"` | `"portrait"` or `"landscape"`. |
| `columns` | `1` | Number of text columns. |
| `stage` | `"draft"` | `"draft"`, `"review"` or `"final"`. See [Stages](#stages). |
| `lint` | `()` | Array of strings that MUST NOT appear at stage `final`; highlighted in the danger tone before that. |
| `numbering` | `"1.1"` | Heading numbering pattern, or `none`. |
| `heading-numbers` | `"inline"` | `"inline"`, `"hang"` (outdented into the margin) or `"none"`. |

Page furniture, sensitivity, margins, fonts and words come from the theme; a document changes them by passing `theme: extend(...)` or, for furniture, with [`furniture`](#furniture).

### Headings

Each level is drawn by the theme's `h1` to `h6` function; levels below 6 use `h6`. Centauri's own:

- Level 1 that opens a page: a **banner**, a tinted band across the full page width with the number and title centred and an accent rule beneath.
- Level 1 that falls mid-page, or any level 1 heading in a multi-column layout: a **rule**, under a full-width line, with its number beside it.
- Levels 2 to 6: plain headings. Their numbers are set at the heading's own size and weight in low ink.

### Stages

| Stage | Watermark | [`note`](#note), [`warn`](#warn) | [`todo`](#todo) | `lint` matches |
|---|---|---|---|---|
| `draft` | the theme's `draft` word across each page | shown | caution tone | highlighted |
| `review` | none | hidden | caution tone | highlighted |
| `final` | none | hidden | build stops | build stops |

### Page furniture

Inner pages carry left, centre and right slots above the header rule and below the footer rule. The theme's `furniture` sets them from page 1; [`furniture`](#furniture) changes them later. Each slot takes content, `none`, or a function of no arguments, called in context, which MAY read [`theme-now`](#theme-now). Centauri's theme prints [`folio`](#folio) in the footer centre and leaves the other slots empty.

A rule sits under the header and above the footer. `header-rule` and `footer-rule` take a stroke (`1pt + black`), `none` to drop the rule, or `auto` for the theme's hairline in the page's hairline colour. Any other value stops the build.

The theme's `page` places the rules and the body: see [Themes](#8-themes).

### `furniture`

`furniture(header: (:), footer: (:), sensitivity: auto, header-rule:, footer-rule:)`

Changes slots, rules and the sensitivity from the next page on. Keys given replace the current value; keys left out are kept, and `auto` restores a rule's default. A call made anywhere on a page takes effect on the page after it, for the header, the footer and [`theme-now`](#theme-now) alike. A sensitivity outside the theme's `levels` stops the build.

```typ
#furniture(footer: (left: [Client copy]), sensitivity: "Confidential")
```

### `folio`

Slot function: the page as `n/N`, then ` | ` and the sensitivity in force when there is one, in the label face. Place it with `footer: (center: folio)`. A brand writes its own as any function of no arguments, such as `() => [#theme-now().sensitivity | #counter(page).get().first()]`.

### `current-section`

Slot function: the level 1 heading in force on the page, with its number. It MAY be used in any slot: `furniture(header: (center: current-section))`.

### `tone`

State holding the active page tone, `"light"` or `"dark"`. It is `"dark"` inside a dark [`cover`](#cover). [`theme-now`](#theme-now) reports it as `tone`.

```typ
#context if tone.get() == "dark" [On a dark ground.]
```

### Accents

A theme MAY carry named accents in `accents`. The accent MAY then be set for the whole document (`centauri(accent:)`), for one cover or slide (`accent:` on that call), from a point onward ([`use-accent`](#use-accent)), or for one passage ([`with-accent`](#with-accent)). A theme with `accents: none` has one set of colours, and asking it for an accent stops the build.

### `use-accent`

`use-accent(name)`

Switches the accent from this point on, across pages. In a deck, the accent returns to the deck accent at the next slide; set `accent:` on each slide instead.

### `with-accent`

`with-accent(name, body)`

Sets `body` in another accent, then returns to the accent that was in force.

### `cover`

`cover(tone: "light", accent: auto, title: none, subtitle: none, meta: (), heading: false, furniture: true, backdrop: auto)[body]`

A full page. Where it is placed decides its role: a front cover, a section or annex divider, or a back cover.

| Argument | Effect |
|---|---|
| `tone` | `"light"` or `"dark"` ground. Components inside read the cover's tone. |
| `accent` | Accent for this page only. |
| `title` | Set at display size in the heading face. |
| `subtitle` | Set beneath the title. |
| `meta` | Array of `(label, value)` pairs, printed as a key–value list at the foot of the page. |
| `heading` | `true` makes the title a numbered level 1 heading, listed in the outline. |
| `furniture` | `false` removes the header. Covers never carry a footer. |
| `backdrop` | Drawn behind the page. `auto` is the theme's `backdrop` element (Centauri's is an accent bloom); `none` leaves the flat cover ground; content such as `image("wave.png", width: 100%)` is placed at the top left; a function of no arguments is called in context with the cover's tone in force. |
| `body` | Optional content beneath the subtitle, at 78% width. |

Passing an unknown named argument stops the build.

```typ
#cover(tone: "dark", title: [Quarterly review], subtitle: [Q3 2026], meta: (([Owner], [Platform team]), ([Status], [Draft])))[]
```

### `annexes`

`#show: annexes` or `#show: annexes.with(word: auto, numbering: ("A", "A.1"))`

Everything after it is an annex. Heading numbers restart: level 1 headings take the first pattern (`A`, `B`, …) and lower levels the second (`A.1`, `A.2`, …). It draws nothing; a divider is a [`cover`](#cover) placed before it.

| Argument | Effect |
|---|---|
| `word` | What a reference to an annex heading prints before its number: `@key` reads "Annex A". `auto` takes the theme's `words.annex`. |
| `numbering` | Two numbering patterns: level 1, then lower levels. Anything else stops the build. |

```typ
#cover(title: [Appendices], backdrop: none)
#show: annexes.with(word: "Appendix", numbering: ("I", "I.a"))
```

---

## 4. Document components

All components in this section also work inside slides, and read their colours, faces and words from the theme. Tones used by several components are `"mute"` (or `none`), `"accent"`, `"success"`, `"caution"`, `"danger"` and `"info"`.

### `todo`

`todo[body]`

Placeholder for missing content, in caution brackets. The build stops at stage `final` while any remain.

### `tba`

`tba[body]`

A deliberate, agreed gap, in neutral brackets. Visible at every stage and never stops the build.

### `note`

`note[body]`

Drafting note in an info block, led by the theme's `drafting-note` word. Printed at stage `draft` only.

### `warn`

`warn[body]`

A small remark in the danger tone, placed just below the point it is called at. It takes no space, so nothing moves when it is dropped, and it never stops a build. Printed at stage `draft` only. For flagging a known breach of a brand rule next to the thing that breaks it.

### `req`

`req[identifier]`

Small line citing a requirement: the theme's `req` word, then the identifier in the label face.

### `chip`

`chip[body]`

Small label in a panel box, for codes and identifiers.

### `pill`

`pill(tone: "mute", dot: true)[body]`

Rounded status label in one of the tones, with a leading dot unless `dot: false`.

### `status`

`status(word)`

A `pill` for a compliance status. `word` is `"compliant"` (success), `"partial"` (caution), `"exception"` (danger) or `"noted"` (info); case does not matter. The printed word comes from the theme's `words.status`.

### `delta`

`delta(direction: "up")[body]`

Change indicator: success for `"up"`, danger for `"down"`.

### `callout`

`callout(tone: "caution", title: none)[body]`

Boxed message with a `!` marker, in one of the tones. It does not break across pages.

### `rule-note`

`rule-note[body]`

Note in the label face beside an accent line, for rules, conventions or code-adjacent remarks.

### `card`

`card[body]`

Outlined block with rounded corners.

### `kpi`

`kpi(label, value, foot: none)`

Outlined block with a label, the value at h1 size in tabular figures, and an optional foot line. Place several in a `grid` to form a row.

### `kv`

`kv(..pairs)`

Key–value list. Each pair is `(label, value)`; labels are set as small labels.

```typ
#kv(([Owner], [Platform team]), ([Due], [30 September]))
```

### `data-table`

`data-table(columns: 1, align: auto, header: none, ..cells)`

Table with hairline rows and no vertical rules. `header` is an array of cells, set as small labels. The first column is set in high ink. `align` defaults to left and top; it takes any Typst table alignment, including a function `(x, y) => alignment`.

```typ
#data-table(columns: 3, header: ([Item], [2025], [2026]), align: (x, _) => if x == 0 { left } else { right },
  [Tickets], [120], [96],
  [Hours], [40], [31])
```

### `qa-table`

`qa-table(..rows)`

Numbered clarification questions. Each row is `(reference, question)`.

### `compliance-matrix`

`compliance-matrix(..rows)`

RFP compliance table. Each row is `(ref, requirement, status, response)`; `status` is a word accepted by [`status`](#status).

### `sig-block`

`sig-block(..parties)`

Two-column signature block with the theme's `sig-block` lines (Name, Title, Signature and Date) under each party name.

### `revision-history`

`revision-history(..rows)`

Each row is `(version, date, author, change)`.

### `request-list`

`request-list(..rows)`

Numbered list of information needed from others. Each row is `(request, owner, needed-by)`.

### `assumption`

`assumption[statement]`

Numbered register entry `A1`, `A2`, … in a panel block. Collected by [`register-table`](#register-table). The word and prefix of every register come from the theme's `words.registers`.

### `dependency`

`dependency[statement]` — register entry `D1`, `D2`, ….

### `decision`

`decision[statement]` — register entry `DEC1`, `DEC2`, ….

### `risk`

`risk[statement]` — register entry `R1`, `R2`, …, in the caution tone.

### `issue`

`issue[statement]` — register entry `I1`, `I2`, …, in the danger tone.

### `register-table`

`register-table(kind)`

Table of every entry of one register in the document, with linked ID, statement and page. `kind` is `"assumption"`, `"dependency"`, `"decision"`, `"risk"` or `"issue"`. Prints the theme's `no-entries` words when there are none.

### `pull-quote`

`pull-quote(attribution: none)[body]`

Large quotation in the quote face beside an accent line.

### `epigraph`

`epigraph(attribution: none)[body]`

Short quotation set to the right, for the opening of a chapter.

### `drop-cap`

`drop-cap(lines: 3, gap: 4pt, body)`

Opening paragraph with a capital in the quote face spanning `lines` lines. `body` MUST be a plain string, not content.

### `glossary`

`glossary(..entries)`

Terms sorted and grouped by first letter. Each entry is `(term, definition)`; `term` SHOULD be a string so it sorts correctly.

Figures and tables captioned with Typst's `figure` are drawn by the theme's `caption` element; Centauri's sets a label, such as `FIGURE 1` or `TABLE 1`, before the caption. Footnotes go at the foot of their page with Typst's `footnote`, drawn by the theme's `footnote` element.

### `fit-logo`

`fit-logo(logo, height: auto, max-width: auto)`

Scales an image, a box or any content down until it fits `height` and `max-width`, keeping its proportions; a logo already within both is left at its size. For partner and client logos that MUST NOT exceed the host brand's own.

### `logo-line`

`logo-line(body, height: auto, max-width: auto)`

Every image and box in `body` is fitted as `fit-logo` does, then centred halfway up the capitals of the text around it instead of sitting on the baseline. A box with equal top and bottom insets keeps its own text on the same centre line.

```typ
#logo-line(height: 0.8cm)[Prepared for #image("client.svg") Client name]
```

---

## 5. Decks

```typ
#show: centauri.with(kind: "deck", aspect: "16:9", accent: "teal", label: "Class 1", date: "September 2026", presenter: "Platform team", title: "Class 1")
```

With `kind: "deck"`, `centauri` takes:

| Argument | Default | Values and effect |
|---|---|---|
| `theme` | `auto` | A theme dictionary; `auto` is [`centauri-theme`](#centauri-theme). |
| `aspect` | `"16:9"` | `"16:9"` (33.867 × 19.05cm) or `"4:3"` (25.4 × 19.05cm). |
| `projection` | `auto` | `"light"` or `"dark"`. `auto` takes `tone`. |
| `tone` | `"light"` | Used when `projection` is `auto`. |
| `accent` | `auto` | One of the theme's accents; `auto` keeps the theme's own colours. Slides without `accent:` use it. |
| `label` | `none` | Top left of every slide, such as the series name. |
| `date` | `none` | Top right of every slide. Any content. |
| `presenter` | `none` | Bottom right of every slide except the title slide. |
| `logos` | `(left: none, right: none)` | Content, such as `image(...)`, that replaces `label` or `date` in the top corners. |
| `light` | `auto` | Bloom light source `(x: 0..1, y: 0..1)` for every slide. `auto` picks a fixed point per slide from its number, so builds are reproducible. |
| `bloom` | `true` | `false` removes the accent bloom. |
| `title`, `author`, `lang` | `none`, `()`, `"en"` | Metadata and language. |

Document-only arguments (`stage`, `lint`, `paper` and so on) MUST NOT be passed to a deck; the build stops on them.

### Grounds

- `projection: "dark"`: content slides sit on near-black with an accent bloom; section slides sit on the accent's 600 step.
- `projection: "light"`: content slides sit on off-white with a faint bloom; section slides sit on the accent's 800 step.

### Frame

Every slide carries a hairline near the top and one near the foot.

- Above the top line: `label` (or the left logo), the current section title in the centre (omitted on section slides), and `date` (or the right logo).
- Below the foot line: the slide count as `NN / TT` on the left and `presenter` on the right.
- A `source:` line, where a slide takes one, sits at the bottom left of the content area after the theme's `words.deck.source`.

### Output modes

| `--input mode=` | Output |
|---|---|
| `slides` (default) | One slide per page at the chosen aspect. A slide that overflows stops the build. |
| `handout` | A4 pages; each slide is scaled to the text width with its [`notes`](#notes) beneath. |
| `titles` | A4 list of slide titles in order, grouped by section, for reviewing the argument before writing content. |

### Slide text

- The body size is fixed for the whole deck. Text MUST be changed to fit a slide; sizes never shrink.
- Titles MUST be in sentence case and MUST NOT end with a full stop (the build stops). Slide titles SHOULD be a sentence stating the takeaway, at most two lines.
- Titles and statements are set within a text column of 24cm on 16:9 and 21.6cm on 4:3.
- Weight falls as size rises: display and h1 are set light (300–320), small headings heavier (560–650).

### Per-slide overrides

Every slide takes `projection:` and `accent:`, which apply to that slide only. Slides listed with a `light:` argument also take a bloom light source.

---

## 6. Slides

### `title-slide`

`title-slide(title: none, subtitle: none, facts: (), number: none, side: none, light: auto, projection: auto, accent: auto)`

Opening slide. The title is set large and light; `facts` is an array of short content set as chips; `number` is set very large in a tone of the ground and cropped at the bottom right; `side` runs up the left edge, such as a classification.

### `outline-slide`

`outline-slide(title: [What this session covers], current: none, projection: auto, accent: auto)`

Generated from the deck's section slides: one tile per section with its number, title and slide count, up to four per row. `current: n` highlights section `n` and dims the rest.

### `section-slide`

`section-slide(number: none, title: none, subtitle: none, preview: 4, light: auto, projection: auto, accent: auto)`

Divider on the accent ground. It prints `Section n of m`, the title large and light, the subtitle, and up to `preview` glass cards listing the titled slides in the section. Cards share the height of the tallest title. `preview: 0` removes the cards. `number` is accepted but not printed; the section's place is computed.

### `claim`

`claim(title: none, source: none, projection: auto, accent: auto)[body]`

Default content slide (assertion–evidence): a sentence title stating the takeaway, then one exhibit that supports it.

### `slide`

Alias of [`claim`](#claim).

### `exhibit`

`exhibit(title: none, source: none, projection: auto, accent: auto)[body]`

One chart or diagram, centred in the space under the title. The title interprets; the exhibit shows data only and SHOULD NOT carry its own title.

### `statement`

`statement(sub: none, light: auto, projection: auto, accent: auto)[body]`

One short phrase at h1 size beside the emphasis line, with an optional smaller line beneath. A pacing slide, not evidence. Mark key words with [`hl`](#hl). Exempt from the full-stop rule.

### `quote-slide`

`quote-slide(attribution: none, light: auto, projection: auto, accent: auto)[body]`

Quotation in the serif beside the emphasis line. Exempt from the full-stop rule.

### `explain`

`explain(title: none, source: none, light: auto, projection: auto, accent: auto, ..rows)`

Terms and explanations in rows divided by hairlines. Each row is `(term, explanation)`. SHOULD be used sparingly.

### `compare`

`compare(title: none, left: none, right: none, pick: none, source: none, projection: auto, accent: auto)`

Two options on a shared baseline. `left` and `right` are `(heading, body)`. `pick: "left"` or `"right"` marks the option the title argues for and dims the other.

### `split`

`split(title: none, sub: none, light: auto, projection: auto, accent: auto, ..items)`

A deep accent panel on the left carrying the title and `sub`, and numbered tonal tiles on the right. Each item is `(heading, body)`.

### `display-slide`

`display-slide(title: none, sub: none, light: auto, projection: auto, accent: auto)[body]`

One word or short phrase scaled to fill the column, with a small title at the top left.

### `table-slide`

`table-slide(title: none, columns: 2, header: none, align: auto, source: none, projection: auto, accent: auto, ..cells)`

A [`data-table`](#data-table) under a slide title. By default the first column is left-aligned and the rest right-aligned, for numbers. Tables of text MUST pass `align: left`; any Typst table alignment is accepted.

```typ
#table-slide(title: [Four tickets from this month], columns: 2, header: ([Ticket], [Summary]), align: left,
  [T-1], [Disk full on the build agent],
  [T-2], [Login loop after a password reset])
```

### `code-slide`

`code-slide(title: none, file: none, highlight: (), source: none, projection: auto, accent: auto)[body]`

A code listing of at most 15 lines, given as a raw block. `file` prints a file name above it; `highlight` is an array of line numbers set on a band.

### `steps-slide`

`steps-slide(title: none, current: none, source: none, projection: auto, accent: auto, ..items)`

Numbered sequence in columns. `current: n` emphasises step `n` and dims the others.

### `exercise`

`exercise(title: none, task: none, minutes: none, output: none, projection: auto, accent: auto)`

Training exercise: the task, an "Expected output" block, and the time box set large on the right. Pass `accent:` to set exercises apart from content slides.

### `appendix`

`appendix(title: none, source: none, projection: auto, accent: auto)[body]`

Dense evidence behind the main argument, with a smaller title and small body text.

### `close`

`close(title: [What to do next], actions: (), contact: none, projection: auto, accent: auto)`

Closing slide: numbered next actions and a contact line at the bottom. A deck SHOULD NOT end on "Questions?" or "Thank you".

---

## 7. Slide helpers

These go inside slide bodies.

### `hl`

`hl[body]`

Emphasis for the words a title or statement turns on: high ink and strong weight.

### `metric`

`metric(value, label, note: none)`

A number at h2 size with its label and an optional note.

### `stats`

`stats(..items)`

Stacked tiles, each with a short label on the left and the value large on the right. Each item is `(value, label)`.

### `tile`

`tile[body]`

Plain tonal card in a tone of the deck accent.

```typ
#cols(tile[*Run 1* \ Baseline rules.], tile[*Run 2* \ Trained model.])
```

### `cols`

`cols(widths: auto, gutter: 1cm, ..items)`

Equal columns with a shared gutter; `widths` takes any Typst column sizes.

### `columns-chart`

`columns-chart(height: 9cm, ..items)`

Rising columns with the figure inside the top and the label in a pill at the base. Each item is `(label, value)` or `(label, value, display)`, where `display` replaces the printed value. Tones alternate within the accent ramp.

### `bars-chart`

`bars-chart(..items)`

Horizontal bars with the value in a pill at the end of each bar. Each item is `(label, value)` or `(label, value, display)`. A bar is never narrower than 2.4cm, so its pill fits; a very small value therefore reads slightly longer than its true length, and the pill carries the exact figure.

### `notes`

`notes[body]`

Speaker notes for the slide it follows. Printed beneath the slide in `handout` mode and on the slide with `--input notes=true`; hidden otherwise.

---

## 8. Themes

A theme is one dictionary: colours, faces, sizes, strokes, page geometry, the heading and element functions, the starting furniture, the sensitivity levels and the words. Centauri supplies the rules (stages, gates, numbering, furniture state) and its own theme, [`centauri-theme`](#centauri-theme). A brand package overrides that theme with [`extend`](#extend) and passes the result as `theme:`:

```typ
#import "@preview/centauri:0.4.0": *
#let brand = extend(centauri-theme, (
  fonts: (heading: ("Newsreader 16pt",)),
  sensitivity: (default: "Internal", levels: ("Public", "Internal", "Confidential")),
  words: (annex: "Schedule"),
))
#show: centauri.with(theme: brand, stage: "review")
= Body
```

`examples/lol/` is a complete brand package built this way.

### Keys

| Key | Holds |
|---|---|
| `colors` | `light` and `dark` palettes, each with the colour names below. |
| `accents` | Named accents, each `(light: (...), dark: (...))` setting any of the colour names on top of `colors`; or `none`. Replaced whole by an override, never merged. |
| `fonts` | `body`, `heading`, `label` (small labels, folios, chips), `code` (raw text) and `quote` (quotations, drop caps): each an array of family names. |
| `type` | `document` and `deck`, each `(body: size, k: steps)`; `ratio` (φ in Centauri's theme); `weights` (`body`, `strong`, `h1`–`h6`, `kpi`, `label`) and `deck-weights` (`display`, `h1`–`h6`). Sizes follow `size(hN) = body × ratio^((6 − N) / k)`, so h6 is body size. |
| `strokes` | `hairline`, `rule` and `emphasis`: widths. Colours come from `colors`. |
| `page` | `left`, `right`: side margins. `header-line`: distance from the top edge to the header rule. `header-gap`: from that rule to the body. `footer-line`: distance from the bottom edge to the footer rule. `footer-gap`: from the body to that rule. |
| `h1` … `h6` | Functions of the heading element, called in context. |
| `elements` | `quote` (block quotes), `raw` (code blocks), `caption` (figure captions), `footnote` (footnote entries): functions of the element, called in context. `backdrop`: a function of no arguments drawing a cover's backdrop. |
| `furniture` | `header` and `footer` (`left`, `center`, `right` slots), `header-rule`, `footer-rule`: the furniture from page 1. |
| `sensitivity` | `default` (`none` or a value) and `levels` (`none`, or an array of every value a document may use). |
| `words` | `contents`, `draft`, `annex`, `drafting-note`, `no-entries`, `req`; `status` (one word per compliance status); `registers` (`word` and `prefix` per register); `tables` (header cells per table component); `sig-block` (signature lines); `deck` (`section`, `of`, `slides`, `minutes`, `expected-output`, `source`). |
| `label-case` | `"upper"` sets small labels in tracked capitals; `"as-written"` keeps the author's case without tracking. |
| `radius` | `s`, `m`, `l`, `full`. |

Colour names, in each of `light` and `dark`:

- Grounds: `paper` (the page), `cover` (covers), `panel` (raised blocks).
- Ink: `ink-hi`, `ink-mid` (body text), `ink-low`.
- Lines: `hairline`, `hairline-soft`.
- Accent: `accent`, `accent-deep`, `accent-ink` (text on an accent fill), `accent-fill`, `link`, `charts` (five series colours), `ramp` (tones `"50"` to `"950"`), `chart-neutral`.
- States: `success`, `caution`, `danger`, `info`, each `(text:, fill:, line:)`.

Every `link` MUST reach 4.5:1 on its `paper` and `cover`, in every accent; the build stops otherwise.

### Writing a heading or element function

The function receives the element and returns content. It is called in context, so it reads the theme with [`theme-now`](#theme-now) directly; [`heading-number`](#heading-number) and [`at-page-top`](#at-page-top) give what a heading needs beyond the theme.

```typ
#import "@preview/centauri:0.4.0": *
#let h1(it) = {
  let t = theme-now()
  block(above: 1.6em, below: 1em, sticky: true, text(font: t.fonts.heading, size: t.sizes.h1, fill: t.colors.ink-hi)[
    #heading-number(it) #it.body
  ])
}
#show: centauri.with(theme: extend(centauri-theme, (h1: h1)))
= A heading
```

### `centauri-theme`

Centauri's own theme: Proxima's colours in four accents (indigo by default, then teal, ember and lime), Atkinson Hyperlegible and Newsreader, the banner and rule level 1 headings, and an accent bloom behind covers.

### `extend`

`extend(base, overrides)`

`base` with `overrides` merged in, dictionary by dictionary: `extend(centauri-theme, (fonts: (heading: ("X",))))` changes the heading face and keeps every other face. A key `base` does not have stops the build and names the key. `accents` is replaced whole.

### `theme-now`

`theme-now()`, inside `context`.

The theme in force at this point, with `colors` resolved to one palette for the page's tone and accent, and these added:

| Key | Value |
|---|---|
| `tone` | `"light"` or `"dark"`. |
| `accent` | The accent in force, or `none`. |
| `stage` | `"draft"`, `"review"` or `"final"`. |
| `sensitivity` | The sensitivity in force on this page. |
| `sizes` | `body`, `small`, `label`, `h1`–`h6`, `display`, `kpi`, `watermark` for the document or deck scale. |
| `heading-numbers` | The document's `heading-numbers`. |
| `columns` | The document's column count. |

It stops the build when no `centauri` show rule is in force.

### `themed`

`themed(fn)`

Shorthand for `context fn(theme-now())`.

```typ
#themed(t => rect(width: 1cm, height: 0.5cm, fill: t.colors.panel))
```

### `palette`

`palette(tone, accent)`, inside `context`.

The theme's palette for another tone or accent: `palette("dark", none).paper`.

### `heading-number`

`heading-number(it)`, inside `context`.

A heading's formatted number, or `none` when it has none or `heading-numbers` is `"none"`.

### `at-page-top`

`at-page-top()`, inside `context`.

Whether this point is at the top of the page's body, as a heading that opens a page is.

### `label-text`

`label-text(body, size: auto, fill: auto)`

A small label in the theme's label face and `label-case`, as captions and table headers are set.

### `ramp`

`ramp(hex)`

Tonal ramp from 50 (lightest) to 950 (darkest), built in OKLCH at constant hue. Keys are strings: `ramp("#5B5BD6").at("700")`.

### `ink-on`

`ink-on(ground, dark: rgb("#1B1D2E"), light: rgb("#EFF0F8"))`

Returns whichever ink has the higher contrast on `ground`.

### `over`

`over(fg, alpha, ground)`

`fg` at `alpha` (0 to 1) laid over `ground`, flattened to one opaque colour, for fills that print the same in every PDF viewer.

### `contrast`

`contrast(a, b)`

WCAG 2 contrast ratio between two colours, from 1 to 21.

### `luminance`

`luminance(colour)`

WCAG 2 relative luminance.

### `aspects`

Dictionary of slide sizes: `"16:9"` and `"4:3"`, each `(width, height)`.

---

## 9. Recipes

### One-page brief

```typ
#import "@preview/centauri:0.4.0": *
#show: centauri.with(accent: "teal", title: "Capstone proposal", theme: extend(centauri-theme, (
  furniture: (header: (left: [Capstone proposal], right: [AI Builder Track])),
  sensitivity: (default: "Internal"),
)))

= Capstone proposal
#kv(([Team], [Three people]), ([Due], [30 September]))

== Problem
One paragraph.

== Approach
One paragraph.

#risk[The labelled data set may be too small.]
```

### Report

```typ
#import "@preview/centauri:0.4.0": *
#show: centauri.with(title: "Quarterly review", theme: extend(centauri-theme, (
  furniture: (header: (center: current-section)),
  sensitivity: (default: "Internal"),
)))

#cover(tone: "dark", title: [Quarterly review], subtitle: [Q3 2026], meta: (([Owner], [Platform team]),))[]
#outline()

#pagebreak()
= Summary
#grid(columns: 3, column-gutter: 10pt, kpi([Tickets], [96], foot: [#delta[−20%] vs Q2]), kpi([Hours], [31]), kpi([Uptime], [99.9%]))

#pagebreak()
= Risks
#register-table("risk")

#cover(tone: "dark", title: [Annexes], furniture: false)
#show: annexes
= Revision history
#revision-history(([0.1], [1 Sep], [DP], [First draft]))
```

### Letter

A letter is a document: the theme's furniture carries the letterhead, and the body is set with the components.

```typ
#import "@preview/centauri:0.4.0": *
#show: centauri.with(stage: "review", numbering: none, theme: extend(centauri-theme, (
  furniture: (header: (left: [*Platform team* · team\@example.com]), footer: (center: none)),
)))

Ms A. Rao #h(1fr) 3 October 2026

*Renewal terms*

Body of the letter.

Yours sincerely,
#sig-block([Platform team])
```

### Deck

```typ
#import "@preview/centauri:0.4.0": *
#show: centauri.with(kind: "deck", accent: "ember", label: "Class 1", date: "Week 1", presenter: "Platform team")

#title-slide(title: [What AI actually is], subtitle: [Four eras and a first call.], facts: ([90 min], [Workshop]))
#outline-slide()
#section-slide(title: [Start from the problem])
#claim(title: [One ticket can be routed four ways, each with its own cost], source: [Illustrative])[
  #cols(tile[*Rules* \ A person writes every decision.], tile[*Model* \ Learned from labelled history.])
]
#exhibit(title: [Accuracy rises with each method, cost rises faster])[
  #columns-chart(height: 7cm, ([Rules], 61, [61%]), ([TF-IDF], 84, [84%]), ([LLM], 91, [91%]))
]
#notes[Ask the room which they would build first.]
#exercise(title: [Route four tickets by hand], task: [Assign each ticket a queue.], minutes: 10, output: [A four-row table.], accent: "teal")
#close(actions: ([Read the handout], [Bring one real ticket]))
```

---

## 10. Authoring checklist

An author or agent generating Centauri source SHOULD check each item before compiling.

1. The import is the only import; every component comes from it, or from the brand package built on it.
2. The document sets exactly one `#show: centauri.with(...)`, or the brand's equivalent.
3. A level 1 heading that should open a page has a `#pagebreak()` before it.
4. A document that must fit a page count is cut to fit; nothing checks the count for you.
5. No `todo` remains in a document meant for stage `final`; deliberate gaps use `tba`.
6. Slide titles are sentences in sentence case, at most two lines, with no final full stop.
7. Each slide carries one message and one exhibit; a second exhibit becomes a second slide.
8. Tables of text on slides pass `align: left`.
9. Per-slide accents are set with `accent:` on the slide, not with `use-accent`.
10. Charts and exhibits carry no title of their own; the slide title interprets them.
11. The build is compiled with the theme's font path and finishes with no errors and no warnings.

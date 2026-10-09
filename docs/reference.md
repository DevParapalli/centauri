# Centauri 0.2.0 reference

This document is the complete reference for authoring with Centauri. It is written for people and for AI agents that generate Centauri documents and decks. Every name that `lib.typ` exports has its own `###` entry below; `tests/run.sh` fails when an export is undocumented or a documented name is not exported.

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
8. [Theme and tokens](#8-theme-and-tokens)
9. [Recipes](#9-recipes)
10. [Authoring checklist](#10-authoring-checklist)

---

## 1. Setup

### Import

```typ
#import "@preview/centauri:0.2.0": *
```

Against a checkout, import the entry file and set `--root` to a directory that contains both the document and the checkout:

```typ
#import "/centauri/lib.typ": *
```

### Fonts

Documents MUST be compiled with Centauri's fonts available. Without them Typst substitutes other fonts and page breaks change.

```sh
typst compile --font-path fonts document.typ
```

The faces are Atkinson Hyperlegible Next (text), Atkinson Hyperlegible Mono (code, labels) and Newsreader (quotations, drop caps). All are OFL-1.1 and ship in `fonts/`.

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
| A document is longer than its `max-pages` (a `brief` allows 1) | `pages, but kind … allows` | Cut content, or pass `max-pages`. |
| `todo[...]` remains at stage `final` | `unresolved todo placeholder(s)` | Resolve every `todo`. Use `tba` for a deliberate gap. |
| A `lint` string appears at stage `final` | `lint match` | Remove the text. |
| A slide's content runs onto a second page | `overflows its page` | Cut the content or split the slide. Sizes never shrink to fit. |
| A slide title ends with a full stop | `ends with a full stop` | Remove the full stop. |
| A theme override puts the link colour below 4.5:1 on the page or cover | `below 4.5:1` | Choose a darker link colour. |
| An argument is outside its allowed values | `must be` | Use a listed value. |

A clean build SHOULD also produce no warnings. A warning such as `document did not converge` indicates a defect in Centauri, not in the document, and SHOULD be reported.

---

## 3. Documents

A document is any `kind` other than `deck`. It is set up once with a show rule:

```typ
#show: centauri.with(kind: "report", title: "Quarterly review", sensitivity: "Internal")
```

### `centauri`

The single entry point for documents and decks. With `kind: "deck"` it builds slides and takes the arguments in [Decks](#5-decks); otherwise it takes these:

| Argument | Default | Values and effect |
|---|---|---|
| `kind` | `"report"` | A key of [`kinds`](#kinds). Selects the defaults marked *kind* below. |
| `accent` | theme default (`"indigo"`) | `"indigo"`, `"teal"`, `"ember"`, `"lime"`. |
| `title` | `none` | Document metadata title. It is not printed; use [`cover`](#cover) for a printed title. |
| `author` | `()` | Metadata. |
| `keywords` | `()` | Metadata. |
| `date` | `auto` | Metadata date. |
| `lang`, `region` | `"en"`, `none` | Text language and region. |
| `paper` | `"a4"` | `"a4"` or `"us-letter"`. |
| `orientation` | *kind* | `"portrait"` or `"landscape"`. |
| `columns` | *kind* | Number of text columns. |
| `max-pages` | *kind* | Integer or `none`. The build stops when the document is longer. |
| `sidenotes` | *kind* | `true` widens the right margin to 5.4cm and sets [`sidenote`](#sidenote) there; `false` turns sidenotes into footnotes. |
| `stage` | `"draft"` | `"draft"`, `"review"` or `"final"`. See [Stages](#stages). |
| `lint` | `()` | Array of strings that MUST NOT appear at stage `final`; highlighted in rose before that. |
| `numbering` | `"1.1"` | Heading numbering pattern, or `none`. |
| `h1-pagebreak` | *kind* | `true` starts each level 1 heading on a new page. |
| `h1-style` | *kind* | `auto`, `"banner"`, `"rule"`, `"compact"`. See [Headings](#headings). |
| `heading-numbers` | `"inline"` | `"inline"`, `"hang"` (outdented into the margin) or `"none"`. |
| `header` | `(:)` | Header slots; see [Page furniture](#page-furniture). |
| `footer` | `(:)` | Footer slots. |
| `sensitivity` | `none` | Label printed after the page number, such as `"Internal"`. |
| `req-label` | `"Reference"` | Word printed before a [`req`](#req) identifier. |

Passing `auto` for a *kind* argument uses the kind's default.

### `kinds`

Dictionary of per-kind defaults. Explicit arguments to `centauri` override them.

| Kind | Orientation | Columns | `h1-pagebreak` | `h1-style` | `max-pages` | `sidenotes` |
|---|---|---|---|---|---|---|
| `report`, `rfp`, `spec` | portrait | 1 | `true` | `auto` | `none` | `false` |
| `brief` | portrait | 1 | `false` | `"compact"` | 1 | `false` |
| `handout` | portrait | 2 | `false` | `auto` | `none` | `false` |
| `handbook` | portrait | 1 | `true` | `auto` | `none` | `true` |
| `wallchart` | landscape | 1 | `false` | `auto` | `none` | `false` |

`deck` is handled separately and is not a key of `kinds`.

### Headings

- Level 1, `h1-style: auto`: a heading that opens a page is set as a **banner**, a tinted band across the full page width with the number and title centred and an accent rule beneath. A heading that falls mid-page, or any level 1 heading in a multi-column layout, is set as a **rule**: under a full-width line, with its number beside it.
- Level 1, `h1-style: "compact"`: the heading keeps the h1 size and sets its number beside it, with no band and no line, and tight spacing. It is the default for `brief` and SHOULD be used wherever page space matters.
- Level 1, `h1-style: "banner"`, `"rule"` or `"compact"`: every level 1 heading takes that treatment.
- Levels 2 to 6 are plain headings. Their numbers are set at the heading's own size and weight in low ink.

### Stages

| Stage | Watermark | [`note`](#note) | [`todo`](#todo) | `lint` matches |
|---|---|---|---|---|
| `draft` | `DRAFT` across each page | shown | amber | highlighted |
| `review` | none | hidden | amber | highlighted |
| `final` | none | hidden | build stops | build stops |

### Page furniture

Inner pages carry left, centre and right slots above the header rule and below the footer rule. Each slot takes content, `none`, `auto`, or a function of the page tone (`tone => content`).

- Header centre: empty by default. `auto` prints the running head, the level 1 heading in force on the page.
- Footer centre: `auto` by default, which prints the page as `n/N` followed by ` | ` and the sensitivity label when one is set.
- Other slots: `auto` prints nothing.

Slots given to `centauri(header:, footer:, sensitivity:)` apply from page 1, whatever the page opens with.

### `furniture`

`furniture(header: (:), footer: (:), sensitivity: auto)`

Changes slots from this point on. Keys given replace the current value; keys left out are kept. Header and footer read the furniture as it stands at the top of each page, so a change takes effect on the next page.

```typ
#furniture(footer: (left: [Client copy]), sensitivity: "Confidential")
```

### `current-section`

A slot value that prints the level 1 heading in force, with its number. `header: (center: auto)` gives the same result in the header centre; `current-section` MAY be used in any slot.

```typ
#show: centauri.with(kind: "handbook", header: (right: current-section))
```

### `tone`

State holding the active page tone, `"light"` or `"dark"`. It is `"dark"` inside a dark [`cover`](#cover). Read it in `context`:

```typ
#context if tone.get() == "dark" [On a dark ground.]
```

### Accents

The accent MAY be set for the whole document (`centauri(accent:)`), for one cover, part or slide (`accent:` on that call), from a point onward ([`use-accent`](#use-accent)), or for one passage ([`with-accent`](#with-accent)). The link colour of every accent reaches 4.5:1 on both the page and the cover ground.

### `use-accent`

`use-accent(name)`

Switches the accent from this point on. In a deck, the accent returns to the deck accent at the next slide; set `accent:` on each slide instead.

### `with-accent`

`with-accent(name, body)`

Sets `body` in another accent, then returns to the accent that was in force.

### `cover`

`cover(tone: "light", accent: auto, title: none, subtitle: none, meta: (), heading: false, furniture: true, bloom: true)[body]`

A full page that MAY appear anywhere in a document.

| Argument | Effect |
|---|---|
| `tone` | `"light"` or `"dark"` ground. Components inside read the cover's tone. |
| `accent` | Accent for this page only. |
| `title` | Set at display size. |
| `subtitle` | Set beneath the title. |
| `meta` | Array of `(label, value)` pairs, printed as a key–value list at the foot of the page. |
| `heading` | `true` makes the title a numbered level 1 heading, listed in the outline. |
| `furniture` | `false` removes the header. Covers never carry a footer. |
| `bloom` | `false` prints a flat ground instead of the accent bloom. |
| `body` | Optional content beneath the subtitle, at 78% width. |

`cover` has no eyebrow argument; passing an unknown named argument stops the build.

```typ
#cover(tone: "dark", title: [Quarterly review], subtitle: [Q3 2026], meta: (([Owner], [Platform team]), ([Status], [Draft])))[]
```

### `part`

`part(title, subtitle: none, accent: auto)`

A full-page divider numbered `Part I`, `Part II`, and so on, for grouping chapters in a handbook. Starts on a new page and carries no furniture.

### `annexes`

`#show: annexes`

Everything after it is an annex: level 1 headings are numbered `A`, `B`, … and lower levels `A.1`, `A.2`, ….

### `letter`

`letter(sender: none, contact: (), recipient: none, date: today, subject: none, closing: [Yours sincerely,], signature: none, paper: "a4", lang: "en")[body]`

A separate template for correspondence, used as a show rule instead of `centauri`. `contact` is an array of strings joined with ` · ` under the sender. Page numbers appear only when the letter runs past one page.

```typ
#show: letter.with(sender: [Platform team], contact: ("team@example.com",), recipient: [Ms A. Rao], subject: [Renewal terms], signature: [D. Parapalli])
Body of the letter.
```

---

## 4. Document components

All components in this section also work inside slides. Tones used by several components are `"mute"` (or `none`), `"accent"`, `"mint"`, `"amber"`, `"rose"` and `"sky"`.

### `todo`

`todo[body]`

Placeholder for missing content, in amber brackets. The build stops at stage `final` while any remain.

### `tba`

`tba[body]`

A deliberate, agreed gap, in neutral brackets. Visible at every stage and never stops the build.

### `note`

`note[body]`

Drafting note in a sky-blue block. Printed at stage `draft` only.

### `req`

`req[identifier]`

Small line citing a requirement: the `req-label` word, then the identifier in mono.

### `chip`

`chip[body]`

Small mono label in a panel box, for codes and identifiers.

### `pill`

`pill(tone: "mute", dot: true)[body]`

Rounded status label in one of the tones, with a leading dot unless `dot: false`.

### `status`

`status(word)`

A `pill` for a compliance status. `word` is `"compliant"` (mint), `"partial"` (amber), `"exception"` (rose) or `"noted"` (sky); case does not matter.

### `delta`

`delta(direction: "up")[body]`

Change indicator: mint for `"up"`, rose for `"down"`.

### `callout`

`callout(tone: "amber", title: none)[body]`

Boxed message with a `!` marker, in one of the tones. It does not break across pages.

### `rule-note`

`rule-note[body]`

Mono note beside an accent line, for rules, conventions or code-adjacent remarks.

### `card`

`card[body]`

Outlined block with rounded corners.

### `kpi`

`kpi(label, value, foot: none)`

Outlined block with a mono label, the value at h1 size in tabular figures, and an optional foot line. Place several in a `grid` to form a row.

### `kv`

`kv(..pairs)`

Key–value list. Each pair is `(label, value)`; labels are set in small mono capitals.

```typ
#kv(([Owner], [Platform team]), ([Due], [30 September]))
```

### `data-table`

`data-table(columns: 1, align: auto, header: none, ..cells)`

Table with hairline rows and no vertical rules. `header` is an array of cells, set as small mono capitals. The first column is set in high ink. `align` defaults to left and top; it takes any Typst table alignment, including a function `(x, y) => alignment`.

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

Two-column signature block with Name, Title, Signature and Date lines under each party name.

### `revision-history`

`revision-history(..rows)`

Each row is `(version, date, author, change)`.

### `request-list`

`request-list(..rows)`

Numbered list of information needed from others. Each row is `(request, owner, needed-by)`.

### `assumption`

`assumption[statement]`

Numbered register entry `A1`, `A2`, … in a panel block. Collected by [`register-table`](#register-table).

### `dependency`

`dependency[statement]` — register entry `D1`, `D2`, ….

### `decision`

`decision[statement]` — register entry `DEC1`, `DEC2`, ….

### `risk`

`risk[statement]` — register entry `R1`, `R2`, …, in amber.

### `issue`

`issue[statement]` — register entry `I1`, `I2`, …, in rose.

### `register-table`

`register-table(kind)`

Table of every entry of one register in the document, with linked ID, statement and page. `kind` is `"assumption"`, `"dependency"`, `"decision"`, `"risk"` or `"issue"`. Prints "No entries." when there are none.

### `pull-quote`

`pull-quote(attribution: none)[body]`

Large serif quotation beside an accent line.

### `epigraph`

`epigraph(attribution: none)[body]`

Short serif quotation set to the right, for the opening of a chapter.

### `drop-cap`

`drop-cap(lines: 3, gap: 4pt, body)`

Opening paragraph with a serif capital spanning `lines` lines. `body` MUST be a plain string, not content.

### `sidenote`

`sidenote[body]`

A numbered note in the outer margin when `sidenotes` is on (the `handbook` default); a footnote otherwise.

### `glossary`

`glossary(..entries)`

Terms sorted and grouped by first letter. Each entry is `(term, definition)`; `term` SHOULD be a string so it sorts correctly.

Figures and tables captioned with Typst's `figure` get a mono label, such as `FIGURE 1` or `TABLE 1`, before the caption.

---

## 5. Decks

```typ
#show: centauri.with(kind: "deck", aspect: "16:9", accent: "teal", label: "Class 1", date: "September 2026", presenter: "Platform team", title: "Class 1")
```

With `kind: "deck"`, `centauri` takes:

| Argument | Default | Values and effect |
|---|---|---|
| `aspect` | `"16:9"` | `"16:9"` (33.867 × 19.05cm) or `"4:3"` (25.4 × 19.05cm). |
| `projection` | `auto` | `"light"` or `"dark"`. `auto` takes `tone`. |
| `tone` | `"light"` | Used when `projection` is `auto`. |
| `accent` | theme default | Deck accent. Slides without `accent:` use it. |
| `label` | `none` | Top left of every slide, such as the series name. |
| `date` | `none` | Top right of every slide. Any content. |
| `presenter` | `none` | Bottom right of every slide except the title slide. |
| `logos` | `(left: none, right: none)` | Content, such as `image(...)`, that replaces `label` or `date` in the top corners. |
| `light` | `auto` | Bloom light source `(x: 0..1, y: 0..1)` for every slide. `auto` picks a fixed point per slide from its number, so builds are reproducible. |
| `bloom` | `true` | `false` removes the accent bloom. |
| `title`, `author`, `lang` | `none`, `()`, `"en"` | Metadata and language. |

Document-only arguments (`stage`, `header`, `sensitivity` and so on) MUST NOT be passed to a deck.

### Grounds

- `projection: "dark"`: content slides sit on near-black with an accent bloom; section slides sit on the accent's 600 step.
- `projection: "light"`: content slides sit on off-white with a faint bloom; section slides sit on the accent's 800 step.

### Frame

Every slide carries a hairline near the top and one near the foot.

- Above the top line: `label` (or the left logo), the current section title in the centre (omitted on section slides), and `date` (or the right logo).
- Below the foot line: the slide count as `NN / TT` on the left and `presenter` on the right.
- A `source:` line, where a slide takes one, sits at the bottom left of the content area as `Source: …`.

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

Training exercise: the task, an "Expected output" block, and the time box set large on the right. Without `accent:` it takes a second accent, ember, or teal when the deck accent is ember, so exercises stand apart from content.

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

## 8. Theme and tokens

### `theme`

`theme(accent: "indigo", document: (body: 10pt, k: 3), deck: (body: 18pt, k: 2))`

Builds a theme dictionary: palettes for every accent in light and dark, fonts, weights, type scales and radii. Any key MAY be overridden by adding a dictionary: `theme() + (radius: (s: 4pt, m: 6pt, l: 9pt, full: 999pt))`.

`label-case` sets the small labels: figure and table captions, key–value keys, table headers, attributions, KPI and signature labels, and register cards. `"upper"` (the default) sets them in tracked capitals; `"as-written"` keeps the author's case without tracking, for brands that avoid capitals: `theme() + (label-case: "as-written")`. Any other value stops the build.

### `make-kit`

`make-kit(theme)`

Builds every component from a theme and returns them as a dictionary. Use it for a custom theme:

```typ
#let (centauri, cover, claim, ..rest) = make-kit(theme(accent: "teal", document: (body: 10.5pt, k: 3)))
```

### `kit`

The dictionary `make-kit(theme())`, from which `lib.typ` exports the components.

### `scale`

`scale(body, k)`

Type scale: `size(hN) = body × φ^((6 − N) / k)`, so h6 is body size. Returns `body`, `small`, `label`, `h1` to `h6`, `display` (h1 × φ) and `kpi`.

### `phi`

The golden ratio, from `tokens.toml`.

### `accents`

Dictionary of accent names and their token values: `indigo`, `teal`, `ember`, `lime`.

### `ramp`

`ramp(hex)`

Tonal ramp from 50 (lightest) to 950 (darkest), built in OKLCH at constant hue. Keys are strings: `ramp("#5B5BD6").at("700")`.

### `ink-on`

`ink-on(ground, dark: rgb("#1B1D2E"), light: rgb("#EFF0F8"))`

Returns whichever ink has the higher contrast on `ground`.

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
#import "@preview/centauri:0.2.0": *
#show: centauri.with(kind: "brief", accent: "teal", title: "Capstone proposal",
  header: (left: [Capstone proposal], right: [AI Builder Track]), sensitivity: "Internal")

= Capstone proposal
#kv(([Team], [Three people]), ([Due], [30 September]))

== Problem
One paragraph.

== Approach
One paragraph.

#risk[The labelled data set may be too small.]
```

The brief uses compact level 1 headings and stops the build if it runs past one page.

### Report

```typ
#import "@preview/centauri:0.2.0": *
#show: centauri.with(kind: "report", title: "Quarterly review", header: (center: auto), sensitivity: "Internal")

#cover(tone: "dark", title: [Quarterly review], subtitle: [Q3 2026], meta: (([Owner], [Platform team]),))[]
#outline()

= Summary
#grid(columns: 3, column-gutter: 10pt, kpi([Tickets], [96], foot: [#delta[−20%] vs Q2]), kpi([Hours], [31]), kpi([Uptime], [99.9%]))

= Risks
#register-table("risk")

#show: annexes
= Revision history
#revision-history(([0.1], [1 Sep], [DP], [First draft]))
```

### Deck

```typ
#import "@preview/centauri:0.2.0": *
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
#exercise(title: [Route four tickets by hand], task: [Assign each ticket a queue.], minutes: 10, output: [A four-row table.])
#close(actions: ([Read the handout], [Bring one real ticket]))
```

---

## 10. Authoring checklist

An author or agent generating Centauri source SHOULD check each item before compiling.

1. The import is the only import; every component comes from it.
2. The document sets exactly one `#show: centauri.with(...)` (or `letter.with(...)`).
3. A one-page document uses `kind: "brief"`. Content is cut to fit; `max-pages` is not raised to hide an overflow.
4. No `todo` remains in a document meant for stage `final`; deliberate gaps use `tba`.
5. Slide titles are sentences in sentence case, at most two lines, with no final full stop.
6. Each slide carries one message and one exhibit; a second exhibit becomes a second slide.
7. Tables of text on slides pass `align: left`.
8. Per-slide accents are set with `accent:` on the slide, not with `use-accent`.
9. Charts and exhibits carry no title of their own; the slide title interprets them.
10. The build is compiled with `--font-path fonts` and finishes with no errors and no warnings.

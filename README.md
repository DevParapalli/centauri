# Centauri

Centauri is the print and slide half of the Proxima design system. It is light-first, builds on the tokens Proxima publishes in `tokens.toml`, and provides page furniture, covers, drafting controls and components for reports, proposals, RFP responses, handbooks, handouts, letters and slide decks.

The complete reference for every component, argument and build rule is [`docs/reference.md`](docs/reference.md). It is written to serve as reference material for people and for AI agents generating Centauri source. Deck design rationale is in [`docs/deck-board.md`](docs/deck-board.md).

## Releases

Centauri and Proxima share major and minor versions; patch versions move independently. Proxima leads each minor: Centauri `X.Y.0` is released only after Proxima `vX.Y.0`. Only a major or minor Proxima release may change a token value in `tokens.toml`; a patch may fix its comments only. A Centauri `X.Y.*` release vendors `tokens.toml` from the latest Proxima tag `vX.Y.*`. Centauri 0.3.2 carries the tokens from Proxima 0.3.0.

`src/tokens.toml` MUST NOT be edited by hand. It is written by:

```sh
uv run scripts/sync-tokens.py                         # latest Proxima vX.Y.* for typst.toml's X.Y
uv run scripts/sync-tokens.py --ref 0.3               # the same, X.Y given; must match typst.toml
uv run scripts/sync-tokens.py --from ../proxima/tokens.toml
uv run scripts/sync-tokens.py --check                 # exits 1 when the copy differs
```

`--ref` takes `X.Y` or `vX.Y` and finds the tag with `git ls-remote`, so `git` must be installed.

## Requirements

- Typst 0.15.0 or later.
- Fonts: Atkinson Hyperlegible Next and Atkinson Hyperlegible Mono (Braille Institute) for text and code, and Newsreader for quotations. All are OFL-1.1 without a Reserved Font Name and are in `fonts/` of the source repository with their licence files. Typefaces are Centauri's own; Proxima sets the same tokens in Outfit for screens. Documents MUST be compiled with these fonts available, for example `typst compile --font-path fonts document.typ`. Without them Typst falls back to other fonts and page breaks change.

## Usage

One import serves every kind of output.

```typ
#import "@preview/centauri:0.3.2": *

#show: centauri.with(kind: "report", accent: "teal", title: "Example report")

#cover(title: [Example report], meta: (([Owner], [Name]),))[]
= Scope
Body text.
```

A deck uses the same import and the same components:

```typ
#import "@preview/centauri:0.3.2": *

#show: centauri.with(kind: "deck", aspect: "16:9", accent: "ember", label: "Class 1")

#title-slide(title: [What AI actually is], subtitle: [Four eras and a first call.])
#claim(title: [One ticket can be routed four ways, each with its own cost])[
  - Rules, classical ML, deep learning, generative AI
]
```

Before the package is published, or to work against a checkout, import the entry file directly: `#import "../centauri/lib.typ": *`, compiling with `--root` set to a directory that contains both.

## Kinds

`kind` selects defaults. Any default MAY be overridden with the argument of the same name.

| Kind | Orientation | Columns | Level 1 starts a page | Level 1 style | Page limit | Sidenotes |
|---|---|---|---|---|---|---|
| `report`, `rfp`, `spec` | portrait | 1 | yes | auto | none | footnotes |
| `brief` | portrait | 1 | no | compact | 1 | footnotes |
| `handout` | portrait | 2 | no | auto | none | footnotes |
| `handbook` | portrait | 1 | yes | auto | none | outer margin |
| `wallchart` | landscape | 1 | no | auto | none | footnotes |
| `deck` | 16:9 or 4:3 | 1 | not applicable | not applicable | none | not applicable |

- `paper` is `"a4"` or `"us-letter"`. `orientation` is `"portrait"` or `"landscape"`. A4 and A3 share one ratio, so a landscape page prints on A3 by scaling.
- When `max-pages` is set, compilation stops if the document is longer.
- With `h1-style: auto`, a level 1 heading that opens a page is set as a banner: a tinted band across the full page width, the number and title centred, an accent rule beneath. A level 1 heading that falls mid-page, or any level 1 heading in a multi-column layout, sits under a rule with its number beside it.
- `h1-style: "compact"` sets a level 1 heading at the same size with its number beside it, without the band or the rule, so a page keeps its space for content. `brief` uses it by default.
- `h1-style: "banner"`, `"rule"` or `"compact"` forces one treatment on every level 1 heading.
- Levels 2 to 6 are plain headings. Their numbers are set at the heading's own size and weight in low ink. `heading-numbers: "hang"` outdents numbers into the left margin so titles align with body text; `"none"` omits them.
- `letter(sender, contact, recipient, date, subject, closing, signature, paper)` is a separate template for correspondence.

## Type

Heading sizes follow `size(hN) = body × φ^((6 − N) / k)`, so h6 is body size.

| Scale | Body | k | h1 | h2 | h3 | h4 | h5 |
|---|---|---|---|---|---|---|---|
| Documents | 10 pt | 3 | 22.30 | 19.00 | 16.18 | 13.78 | 11.74 |
| Decks | 20 pt | 2 | 66.6 | 52.4 | 41.2 | 32.4 | 25.4 |

Weight falls as size rises in both scales. Documents set h1 at 500 and h6 at 700; decks set display type at 300.

Every heading is set in Atkinson Hyperlegible Next. Newsreader is used only for quotations (`pull-quote`, `epigraph`, block `quote`) and `drop-cap`. `theme(document: (body: 11pt, k: 3))` changes a scale; for example, a handout printed at A5 SHOULD use a 13 to 14 pt body.

## Accents

Every Proxima accent (`indigo`, `teal`, `ember`, `lime`) is available in both tones. The accent MAY be set:

- for the whole document, with `centauri(accent: "teal")`;
- for one cover, slide or part, with `accent: "ember"` on that call;
- from a point onward, with `use-accent("lime")` (documents only; in a deck, set `accent:` on each slide instead);
- for one passage, with `with-accent("indigo")[...]`.

The link colour for each accent is the first of accent, accent-deep and ink that reaches 4.5:1 on both the page and the cover ground. Compilation stops if a theme override breaks that.

## Page furniture

Inner pages have left, centre and right slots above the header rule and below the footer rule. Each slot takes content, `none`, `auto`, or a function of the page tone. The header centre is empty by default; `auto` there opts in to the running head (the level 1 heading in force). `auto` in the footer centre is the page number followed by the sensitivity label. Set slots with `centauri(header: (center: [...]))`; change them from any point with `furniture(header: (center: [...]))`. Slots set on `centauri` apply from page 1, whatever the page opens with.

## Covers

`cover(tone, accent, title, subtitle, meta, heading, furniture, bloom)[body]` produces a full page and MAY appear anywhere. With `heading: true` the title becomes a numbered level 1 heading and is listed in the contents. Covers carry an accent bloom by default; `bloom: false` prints a flat ground.

## Components

Documents and decks share: `chip`, `pill`, `status`, `delta`, `callout`, `rule-note`, `card`, `kpi`, `kv`, `data-table`, `qa-table`, `compliance-matrix`, `sig-block`, `req`, `todo`, `tba`, `note`, `assumption`, `dependency`, `decision`, `risk`, `issue`, `register-table`, `annexes`, `pull-quote`, `epigraph`, `drop-cap`, `sidenote`, `glossary`, `revision-history`, `request-list`, `current-section`, `part`, `furniture`, `use-accent`, `with-accent`.

Decks follow the design board in `docs/deck-board.md` and Proxima's primitives: assertion–evidence content slides (a sentence title stating the takeaway, then one exhibit), one message per slide, a single body size, left-aligned text, and quiet chrome.

### Grounds and projection

`projection: "dark" | "light"` sets the whole deck.

- **Dark:** content slides sit on Proxima's near-black with an accent bloom; section slides sit on the accent's 600 step, so a divider never flashes white.
- **Light:** content slides are off-white with dark text and a faint accent bloom; section slides sit on the accent's 800 step.

Accent steps come from a tonal ramp (50 to 950) built in OKLCH from each accent. Text on a section ground is whichever ink reads better on it.

Each bloom sits at a light source `(x, y)`, where each value is a ratio of the page from 0 to 1 (`x: 1` is the right edge, `y: 1` the bottom). Without `light:`, each slide takes a fixed pseudo-random point from its frame number, so the deck varies but every build is identical. `light:` on the deck sets one point for all slides; on a slide, it sets that slide. `bloom: false` removes blooms.

### Chrome

- Above a hairline at the top: `label` on the left, the current section title in the centre (omitted on section slides), and `date` on the right. `logos: (left: ..., right: ...)` replaces the label or date with a logo.
- Below a hairline at the foot: the slide count (`03 / 21`) on the left and `presenter` on the right. The title slide leaves the bottom right empty.
- A `source:` line sits at the bottom left of the content area.

### Type on slides

Weight falls as size rises: display and h1 are set at 300–320, small headings at 560–650. Headlines MUST be in sentence case, MUST NOT end with a full stop (the build stops if one does), and SHOULD break where the sense breaks. Runts, widows and orphans are penalised.

### Slides

| Component | Use |
|---|---|
| `title-slide(title, subtitle, facts, number, side)` | Title set large and light; `facts` as chips; optional large numeral cropped at the bottom right; `side` runs up the left edge. |
| `outline-slide(title, current)` | Generated from the section slides: one tile per section with its slide count; `current` highlights one section. |
| `section-slide(title, subtitle, preview)` | Accent ground. `Section 2 of 4`, the title set large and light, and up to `preview` glass cards listing the slides in the section, sized to the longest title. |
| `claim(title, source)[exhibit]` | Default content slide. `slide` is an alias. |
| `exhibit(title, source)[chart]` | One chart or diagram; the title interprets, the exhibit shows data only. |
| `statement(sub)[phrase]` | One phrase at h1 size beside an emphasis line; `hl[...]` marks key words. |
| `quote-slide(attribution)[text]` | Quotation in the serif beside an emphasis line. |
| `explain(title, ..rows)` | Terms and explanations in rows divided by hairlines. Use sparingly. |
| `compare(title, left, right, pick)` | Two options on a shared baseline. |
| `table-slide(title, columns, header, align, source)[..cells]` | Numbers right-aligned after the first column by default; `align: left` for tables of text, or any `table` alignment. |
| `bars-chart(..bars)` | Horizontal bars as `(label, value, pill)`. A bar is never narrower than 2.4cm, so its value pill fits; a very small value reads slightly longer than its true length, and the pill carries the exact figure. |
| `split(title, sub, ..items)` | Accent panel with the title on the left, numbered tiles on the right. |
| `display-slide(title, sub)[word]` | One word or phrase scaled to fill the column. |
| `code-slide`, `steps-slide`, `exercise`, `appendix`, `close` | As named; `exercise` takes a second accent. |
| `columns-chart(height, ..items)` | Rising columns with the value inside and the label in a pill. |
| `tile[body]` | Plain tonal card for use inside a slide body. |
| `stats`, `metric`, `cols`, `hl`, `notes` | Helpers. |

Two line types have distinct jobs: the emphasis line (thick, round-ended, accent, from the first line's cap height to the last line's baseline) marks a statement or quotation; the hairline divides rows and items. Every slide accepts `projection` and `accent` overrides; title, section, statement, quote, explain, split and display slides also accept `light`. A slide without `accent:` uses the deck's accent, so a per-slide override never carries to the next slide.

### Output modes

Output modes are selected with `--input mode=`:

- `slides` (default): one slide per page. A slide that runs onto a second page stops the build; the text is changed to fit, never the size.
- `handout`: A4 pages; each slide is scaled to the text width with its speaker notes beneath.
- `titles`: an A4 list of slide titles in order, grouped by section, for reviewing the argument before content is written.

`notes[...]` carries the speaker script. It appears in handouts, and on the slides only with `--input notes=true`.

Code blocks are highlighted with a theme generated from the palette in force, so highlighting follows the accent and the tone.

## Changes in 0.3.2

- `auto` in the footer's left or right slot prints the folio, as it does in the centre, so a design can move the page label to a corner. Defaults are unchanged.

## Changes in 0.3.1

- `folio` on `centauri` and `furniture` replaces the footer-centre page label with a function of the page, the total and the sensitivity in force; `auto` keeps `n/N | sensitivity`.
- `annexes` takes `title`, `subtitle`, `word` and `numbering`. A title draws a divider page first; `word` is what a cross-reference prints ("Annex A", "Appendix I"); `numbering` sets the level 1 and lower patterns. Numbering still restarts, and no divider is drawn by default.
- `fit-logo` scales a logo down to a height and width; `logo-line` does the same to every image and box in a line of text and centres them on its capitals.
- The caption tests pass with pdftotext versions that split letter-spaced labels.

## Changes in 0.3.0

- Carries the tokens from Proxima 0.3.0; the values are unchanged from 0.2.0.
- `theme() + (label-case: "as-written")` sets small labels in the author's case, without tracking, for brands that avoid capitals.
- `header-rule` and `footer-rule` on `centauri` and `furniture` take a stroke, `none` or `auto`; a rule left out of `furniture` is kept.

## Changes in 0.2.0

- Tokens are read from the vendored `tokens.toml`.
- Golden-ratio type scale, all six heading levels styled.
- `serif-em` is removed.
- Deck support merged into the same entry point.
- Accents MAY change per document, cover, slide, part or passage.
- The header centre MAY carry the running head with `auto`; it is empty by default.
- Eyebrows are removed everywhere. Level 1 headings open pages as banners; heading numbers match their heading's size.
- New kinds, new components and `letter`.
- `h1-style: "compact"`, the default for `brief`.
- Slides export `tile`; `table-slide` takes `align:`; `bars-chart` bars have a 2.4cm minimum width.
- Section-slide preview cards share the height of the tallest title, so long titles are not cut off.
- A deck whose accent is not the theme default converges at any length. `use-accent` no longer carries across slides.
- On 4:3 slides, titles and statements fit the 21.6cm between the margins; 16:9 keeps the 24cm measure.
- `docs/reference.md`: complete reference for every export, checked by the tests.
- Header, footer and sensitivity set on `centauri` apply on page 1 when the page opens with something other than a heading.

## Tests

`tests/run.sh`, run from the repository root, MUST pass before a release. It requires `typst`, poppler (`pdftotext`, `pdftocairo`, `pdftoppm`, `pdfinfo`) and `uv`, and checks that:

- the examples and test documents build with no errors and no warnings, decks in every output mode and both projections;
- each build rule stops the build with its own error: page limit, unresolved `todo`, lint match, low link contrast, slide overflow, a title ending in a full stop, and an unknown `h1-style`;
- page furniture, including on page 1, its rules and the folio, and figure captions print the expected text;
- `annexes` restarts numbering in its patterns, prints its reference word and draws a divider only when titled;
- `fit-logo` and `logo-line` cap logos, and `logo-line` centres an image and a text box on the line's capitals within a pixel;
- every complete example in `README.md` and `docs/reference.md` builds;
- `docs/reference.md` documents every name `lib.typ` exports, and no other.

## Licence

Code is MIT. Fonts in `fonts/` are OFL-1.1 under their own licence files.

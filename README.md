# Centauri

Centauri is the print and slide half of the Proxima design system. It supplies the rules (stages, drafting gates, numbering, page furniture, covers and components for documents and slide decks) and its own light-first theme built on the tokens Proxima publishes in `tokens.toml`. A brand package overrides that theme for its own identity and presents the same components in it.

The complete reference for every component, argument and build rule is [`docs/reference.md`](docs/reference.md). It is written to serve as reference material for people and for AI agents generating Centauri source. Deck design rationale is in [`docs/deck-board.md`](docs/deck-board.md).

## Releases

Centauri and Proxima release separately. Centauri vendors `tokens.toml` from Proxima's latest release tag, and a Centauri release whose vendored tokens change is a minor release at least. Centauri 0.4.0 carries the tokens from Proxima 0.3.0.

`src/tokens.toml` MUST NOT be edited by hand. It is written by:

```sh
uv run scripts/sync-tokens.py                         # latest Proxima release tag
uv run scripts/sync-tokens.py --ref v0.3.0            # one tag
uv run scripts/sync-tokens.py --from ../proxima/tokens.toml
uv run scripts/sync-tokens.py --check                 # exits 1 when the copy differs from the latest tag
```

The script finds tags with `git ls-remote`, so `git` must be installed. `--check` failing after a new Proxima release is the signal to sync and bump the minor.

## Requirements

- Typst 0.15.0 or later.
- Fonts: Centauri's theme sets Atkinson Hyperlegible Next and Atkinson Hyperlegible Mono (Braille Institute) for text, labels and code, and Newsreader for quotations. All are OFL-1.1 without a Reserved Font Name and are in `fonts/` of the source repository with their licence files. Typefaces are Centauri's own; Proxima sets the same tokens in Outfit for screens. Documents MUST be compiled with the theme's fonts available, for example `typst compile --font-path fonts document.typ`. Without them Typst falls back to other fonts and page breaks change.

## Usage

One import serves every kind of output.

```typ
#import "@preview/centauri:0.4.0": *

#show: centauri.with(accent: "teal", title: "Example report")

#cover(title: [Example report], meta: (([Owner], [Name]),))[]
= Scope
Body text.
```

A deck uses the same import and the same components:

```typ
#import "@preview/centauri:0.4.0": *

#show: centauri.with(kind: "deck", aspect: "16:9", accent: "ember", label: "Class 1")

#title-slide(title: [What AI actually is], subtitle: [Four eras and a first call.])
#claim(title: [One ticket can be routed four ways, each with its own cost])[
  - Rules, classical ML, deep learning, generative AI
]
```

Before the package is published, or to work against a checkout, import the entry file directly: `#import "../centauri/lib.typ": *`, compiling with `--root` set to a directory that contains both.

## Kinds

`kind` is `"document"` (the default) or `"deck"`. It picks the engine and the page sizes: a document is A4 or US Letter, portrait or landscape (`paper`, `orientation`), in any number of `columns`; a deck is 16:9 or 4:3 (`aspect`). Everything else is the document's own: a level 1 heading does not start a page, so put `#pagebreak()` where one should; nothing counts pages; notes go at the foot of their page with `footnote`; a letter is a document whose theme furniture carries the letterhead.

- A level 1 heading that opens a page is set as a banner: a tinted band across the full page width, the number and title centred, an accent rule beneath. A level 1 heading that falls mid-page, or any level 1 heading in a multi-column layout, sits under a rule with its number beside it.
- Levels 2 to 6 are plain headings. Their numbers are set at the heading's own size and weight in low ink. `heading-numbers: "hang"` outdents numbers into the left margin so titles align with body text; `"none"` omits them.

## Themes

A theme is one dictionary: colours (light and dark), faces, type scale, strokes, page geometry, a function for each heading level, functions for quotations, code, captions, footnotes and cover backdrops, the starting page furniture, the sensitivity levels, and every fixed word. `centauri-theme` is Centauri's own. A brand overrides it with `extend` and passes the result:

```typ
#import "@preview/centauri:0.4.0": *

#let brand = extend(centauri-theme, (
  fonts: (heading: ("Newsreader 16pt",)),
  furniture: (header: (left: [Brand], center: current-section)),
  sensitivity: (default: "Internal", levels: ("Public", "Internal", "Confidential")),
))
#show: centauri.with(theme: brand)
= Scope
Body text.
```

A misspelled key stops the build and names it. Theme functions and brand code read the theme in force with `theme-now()` inside `context`; `colors` there is already resolved for the page's tone and accent. `examples/lol/` is a complete brand package; [`docs/reference.md`](docs/reference.md#8-themes) lists every key.

## Type

Heading sizes follow `size(hN) = body × φ^((6 − N) / k)`, so h6 is body size.

| Scale | Body | k | h1 | h2 | h3 | h4 | h5 |
|---|---|---|---|---|---|---|---|
| Documents | 10 pt | 3 | 22.30 | 19.00 | 16.18 | 13.78 | 11.74 |
| Decks | 20 pt | 2 | 66.6 | 52.4 | 41.2 | 32.4 | 25.4 |

Weight falls as size rises in both scales. Documents set h1 at 500 and h6 at 700; decks set display type at 300.

Every heading is set in Atkinson Hyperlegible Next. Newsreader is used only for quotations (`pull-quote`, `epigraph`, block `quote`) and `drop-cap`. `extend(centauri-theme, (type: (document: (body: 11pt))))` changes a scale; for example, a handout printed at A5 SHOULD use a 13 to 14 pt body.

## Accents

Centauri's theme carries every Proxima accent (`indigo`, `teal`, `ember`, `lime`) in both tones. The accent MAY be set:

- for the whole document, with `centauri(accent: "teal")`;
- for one cover or slide, with `accent: "ember"` on that call;
- from a point onward, with `use-accent("lime")` (documents only; in a deck, set `accent:` on each slide instead);
- for one passage, with `with-accent("indigo")[...]`.

The link colour for each accent is the first of accent, accent-deep and ink that reaches 4.5:1 on both the page and the cover ground. Compilation stops if a theme breaks that. A brand theme MAY set `accents: none`; asking it for an accent then stops the build.

## Page furniture

Inner pages have left, centre and right slots above the header rule and below the footer rule. Each slot takes content, `none`, or a function of no arguments called in context. The theme's `furniture` sets them from page 1; Centauri's puts `folio` (the page as `n/N`, then the sensitivity) in the footer centre and leaves the rest empty, and `current-section` is the running head for any slot. `furniture(header: (center: [...]), sensitivity: "Confidential")` changes slots, rules and the sensitivity from the next page on. The theme's `page` places the rules by their distance from the paper's edges.

## Covers

`cover(tone, accent, title, subtitle, meta, heading, furniture, backdrop)[body]` produces a full page; where it is placed makes it a front cover, a divider or a back cover. With `heading: true` the title becomes a numbered level 1 heading and is listed in the contents. `backdrop` is drawn behind the page: `auto` for the theme's (Centauri's is an accent bloom), `none` for a flat ground, an image or any content, or a function called with the cover's tone in force.

## Components

Documents and decks share: `chip`, `pill`, `status`, `delta`, `callout`, `rule-note`, `card`, `kpi`, `kv`, `data-table`, `qa-table`, `compliance-matrix`, `sig-block`, `req`, `todo`, `tba`, `note`, `warn`, `assumption`, `dependency`, `decision`, `risk`, `issue`, `register-table`, `annexes`, `pull-quote`, `epigraph`, `drop-cap`, `glossary`, `revision-history`, `request-list`, `furniture`, `use-accent`, `with-accent`. Tones are `success`, `caution`, `danger` and `info`, with `mute` and `accent`.

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
| `code-slide`, `steps-slide`, `exercise`, `appendix`, `close` | As named; pass `accent:` to set an `exercise` apart. |
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

## Brand packages

A brand package is a Typst package that imports Centauri, overrides its theme and exports the result. [`examples/lol/`](examples/lol/) is a complete one for Lafayette O'Reilly Logistics, an invented company:

- `lib.typ` builds `lol-theme` with `extend(centauri-theme, (...))`: LOL's colours, faces, heading functions, quotation style, cover backdrop, two furniture arrangements, its five data classes as sensitivity levels, and its words. It exports the theme, `lol = centauri.with(theme: lol-theme)`, the drawn logo and the furniture `presets`, alongside every Centauri name.
- `report.typ` is a document written with it.
- `run.py` is the brand's test runner: it runs Centauri's suite, then the brand's own checks with `tests/checks.py`.

A brand repository vendors Centauri as a git submodule (`vendor/centauri`) for its tests, copies `run.py`, and points `CENTAURI`, `ROOT` and `FONTS` at the submodule, the repository and its fonts. Documents written with the brand need no tests of their own.

## Changes in 0.4.0

Centauri becomes an engine with its own theme, so brand packages can restyle it without wrapping it. Documents written for 0.3 need the changes below.

- `theme:` on `centauri` takes a theme dictionary; `centauri-theme` is Centauri's own, and `extend` overrides parts of it. Unknown keys stop the build. `theme()`, `make-kit`, `kit`, `scale`, `phi` and `accents` are removed.
- Headings are drawn by the theme's `h1` to `h6` functions, and quotations, code blocks, captions, footnotes and cover backdrops by its `elements`. `heading-number`, `at-page-top`, `label-text` and `palette` help write them.
- `theme-now()` and `themed()` give the theme in force, with colours resolved for the page's tone and accent, to theme functions and brand code.
- Colours are named in the theme as `success`, `caution`, `danger` and `info` (were `mint`, `amber`, `rose`, `sky`); `pill`, `callout` and `tone` arguments take the new names.
- `kind` is `"document"` or `"deck"`. The other kinds, `h1-pagebreak`, `h1-style`, `max-pages` and `sidenotes` are removed: put `#pagebreak()` before a heading that should open a page, and use `footnote`.
- Furniture, sensitivity and page geometry come from the theme. `header`, `footer`, `sensitivity`, `header-rule`, `footer-rule`, `folio` and `req-label` are removed from `centauri`. Slots take content, `none` or a function of no arguments; `auto` in a slot is removed, and `folio` and `current-section` are slot functions. A `furniture` change takes effect on the next page for everything, `theme-now` included. A theme MAY list sensitivity `levels`; any other value stops the build.
- `cover(backdrop:)` replaces `bloom:` and takes an image or any content as well. `part`, `letter` and the `annexes` divider are removed: place a `cover`. `annexes` sets numbering and the reference word only.
- `warn[...]` prints a draft-only remark that takes no space.
- Every fixed word (contents title, watermark, annex word, drafting-note lead, table headers, register words and prefixes, status words, signature lines, deck words) comes from the theme's `words`.
- `exercise` keeps the deck accent unless given `accent:`.
- The tests run with `uv run tests/run.py` and need only `typst` and `uv`.

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

`uv run tests/run.py` MUST pass before a release. It needs `typst` and `uv`; `uv` installs pypdf and Pillow for the run. It checks that:

- the examples and test documents build with no errors and no warnings, decks in every output mode and both projections;
- each build rule stops the build with its own error: unresolved `todo`, lint match, low link contrast, slide overflow, a title ending in a full stop, an unknown or missing theme key, a sensitivity outside the theme's levels, an accent the theme lacks, and an unknown `kind`;
- page furniture, including on page 1, its rules, the folio and the sensitivity in the header, and figure captions print the expected text, a `furniture` change reaches the next page, and the rules sit at the theme's `header-line` and `footer-line`;
- theme heading functions draw the headings, with their numbers;
- `annexes` restarts numbering in its patterns and prints its reference word, the caller's or the theme's;
- a cover draws no backdrop, content, or a function that sees the cover's tone;
- `warn` prints in draft only and moves nothing;
- `fit-logo` and `logo-line` cap logos, and `logo-line` centres an image and a text box on the line's capitals within a pixel;
- every complete example in `README.md` and `docs/reference.md` builds;
- `docs/reference.md` documents every name `lib.typ` exports, and no other.

`tests/checks.py` holds the build and PDF checks the suite uses. The repository is open: a brand package that wants the same checks downloads `tests/` from it, or vendors Centauri as a git submodule, and imports `checks.py` from its own runner.

## Licence

Code is MIT. Fonts in `fonts/` are OFL-1.1 under their own licence files.

# Centauri

Centauri is the print half of the Proxima design system. It is light-first, uses the Proxima token set flattened for opaque print output, and provides page furniture, covers, drafting controls and document components for reports, proposals and RFP responses.

## Requirements

- Typst 0.15.0 or later.
- Fonts: Outfit (variable), Instrument Serif and IBM Plex Mono. All three are OFL-1.1 and are included in `fonts/` of the source repository. Documents MUST be compiled with these fonts available, for example `typst compile --font-path fonts document.typ`. Without them Typst falls back to other fonts and page breaks change.

## Usage

```typ
#import "@preview/centauri:0.1.0": *

#show: centauri.with(
  title: "Example report",
  stage: "draft",
  lint: ("\u{2014}",),
  header: (left: image("our-logo.svg", height: 14pt), right: image("partner.svg", height: 18pt)),
  sensitivity: "Internal",
)

#cover(eyebrow: ("Report", "v0.1"), title: [Example report], meta: (([Owner], [Name]),))[]
#outline()

= First section
```

`examples/showcase.typ` renders every component.

## Page furniture

Each inner page has three slots above the header rule and three below the footer rule, addressed as `left`, `center` and `right`.

- A slot value MUST be content, `none`, `auto`, or a function that takes the page tone (`"light"` or `"dark"`) and returns content.
- `auto` in the footer center renders the page as `1/N`, followed by ` | ` and the sensitivity label when one is set. `auto` in any other slot renders nothing.
- `furniture(header: (..), footer: (..), sensitivity: ..)` updates the furniture. Keys that are not passed keep their value. Header and footer both read the furniture as it stood at the top of the page, so an update takes effect from the following page.

## Covers

`cover(tone: "light" | "dark", eyebrow, title, subtitle, meta, heading, furniture, bloom)[body]` produces a full page and MAY appear anywhere in a document. With `heading: true` the title becomes a numbered level 1 heading and is listed in the contents. Dark covers use an accent bloom by default; `bloom: false` disables it.

`tone` is a document state holding the active page tone, `"light"` or `"dark"`. A dark cover sets it to `"dark"` for its own page and restores `"light"` after it, and every component reads it, so the same `kpi` or `pill` carries the dark palette inside a dark cover without taking an argument. Custom cover content MAY read it with `context tone.get()`.

Two things do not follow the tone, because Typst set rules cannot be contextual: a bare `#table` keeps the light hairline, and list markers keep the light low-ink colour. Use `data-table` for tables on a dark cover.

## Figures and tables

A `figure` caption sets the supplement and number in mono, then the caption text, left aligned, below the content for both figures and tables. Numbering is per document.

`data-table` resolves its palette inside a context block, so Typst cannot see the table element inside it and counts such a figure as a figure. Pass `kind: table, supplement: [Table]` to have it counted and labelled as a table.

## Stages

The stage is read from `--input stage=...` and otherwise from the `stage` parameter.

| Behaviour | draft | review | final |
| --- | --- | --- | --- |
| Watermark | shown | hidden | hidden |
| `note` | shown | hidden | hidden |
| Open `todo` | highlighted | highlighted | compilation fails |
| `lint` match | highlighted | highlighted | compilation fails |
| `tba` | marked | marked | marked |

`tba` marks a deliberate gap. It renders a neutral marker at every stage, including final, and is not counted.

## Contrast

Link colour is the first of accent, accent-deep and ink that reaches a WCAG contrast ratio of 4.5:1 on both the page and the cover ground. State text is darkened toward ink until it reaches 4.5:1 on its fill. Compilation fails if a theme override sets a link colour below 4.5:1.

## Themes

`theme(accent: "indigo" | "teal" | "ember" | "lime")` returns the Proxima light and dark palettes, fonts, sizes, weights and radii. `make(theme)` returns every component bound to that theme. The default exports use the indigo accent.

```typ
#import "@preview/centauri:0.1.0": make, theme
#let (centauri, cover, pill, ..rest) = make(theme(accent: "teal"))
```

A theme MAY be extended by dictionary addition, for example `theme() + (radius: (s: 4pt, m: 6pt, l: 9pt, full: 999pt))`.

## Components

`serif-em`, `eyebrow`, `chip`, `pill`, `status`, `delta`, `callout`, `rule-note`, `card`, `kpi`, `kv`, `data-table`, `qa-table`, `compliance-matrix`, `sig-block`, `req`, `todo`, `tba`, `note`, `assumption`, `dependency`, `decision`, `risk`, `issue`, `register-table`, `annexes`, `furniture`, `contrast`, `tone`.

## Tests

`tests/run.sh` compiles the showcase and test documents from the repository root. It requires `typst` and `pdftotext`.

## Licence

Code is MIT. Fonts in `fonts/` are OFL-1.1 under their own licence files.

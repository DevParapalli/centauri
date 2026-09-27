// Centauri: print and slide design system on Proxima's shared tokens.
// One entry point: `#show: centauri.with(kind: ...)`. Kinds: report, rfp, spec,
// brief, handout, handbook, wallchart, deck. `letter` is its own template.

#import "src/tokens.typ": theme, scale, contrast, luminance, accents, phi, ramp, ink-on
#import "src/make.typ": furniture, tone, kinds
#import "src/slides.typ": make-kit, aspects

/// Build a kit from a custom theme: `#let kit = make-kit(theme(accent: "teal"))`.
#let kit = make-kit(theme())

#let (
  centauri, cover, annexes, letter, part,
  use-accent, with-accent,
  todo, tba, note, req,
  chip, pill, status, delta, callout, rule-note, card, kpi,
  kv, data-table, qa-table, compliance-matrix, sig-block,
  assumption, dependency, decision, risk, issue, register-table,
  pull-quote, epigraph, drop-cap, sidenote, glossary,
  revision-history, request-list, current-section,
  slide, claim, exhibit, title-slide, section-slide, outline-slide, statement, quote-slide,
  compare, explain, table-slide, code-slide, steps-slide, exercise, appendix, close,
  metric, stats, columns-chart, bars-chart, split, display-slide, cols, hl, notes,
  ..rest,
) = kit

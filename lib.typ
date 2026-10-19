// Centauri: a print and slide engine with its own theme, on Proxima's shared tokens.
// One entry point: `#show: centauri.with(kind: "document")` or `kind: "deck"`. A brand passes
// `theme: extend(centauri-theme, (...))`.

#import "src/tokens.typ": contrast, luminance, over, ramp, ink-on
#import "src/theme.typ": centauri-theme
#import "src/schema.typ": extend
#import "src/runtime.typ": tone, theme-now, themed, palette, heading-number, at-page-top, label-text, folio, current-section
#import "src/make.typ": (
  furniture, cover, annexes, use-accent, with-accent,
  todo, tba, note, warn, req,
  chip, pill, status, delta, callout, rule-note, card, kpi,
  kv, data-table, qa-table, compliance-matrix, sig-block,
  assumption, dependency, decision, risk, issue, register-table,
  pull-quote, epigraph, drop-cap, glossary, revision-history, request-list,
)
#import "src/slides.typ": (
  centauri, aspects,
  slide, claim, exhibit, title-slide, section-slide, outline-slide, statement, quote-slide,
  compare, explain, table-slide, code-slide, steps-slide, exercise, appendix, close,
  metric, stats, tile, columns-chart, bars-chart, split, display-slide, cols, hl, notes,
)
#import "src/logos.typ": fit-logo, logo-line

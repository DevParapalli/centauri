#import "/lib.typ": *
// A custom folio on page 1; page 2 changes the sensitivity, page 3 restores Centauri's folio.
#show: centauri.with(stage: "review", theme: extend(centauri-theme, (
  furniture: (footer: (center: () => [#theme-now().sensitivity -- page #counter(page).get().first() of #counter(page).final().first()])),
  sensitivity: (default: "Internal"),
)))
Page one.
#furniture(sensitivity: "Public")
#pagebreak()
Page two.
#furniture(footer: (center: folio))
#pagebreak()
Page three.

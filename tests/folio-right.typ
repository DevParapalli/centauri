#import "/lib.typ": *
// A folio function in the footer's right slot prints there, and the centre stays empty.
#show: centauri.with(stage: "review", theme: extend(centauri-theme, (
  furniture: (footer: (center: none, right: () => [#theme-now().sensitivity | #counter(page).get().first()])),
  sensitivity: (default: "Internal"),
)))
Body.

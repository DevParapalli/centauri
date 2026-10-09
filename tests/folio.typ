#import "/lib.typ": *
// A custom folio on page 1; page 2 changes the sensitivity, page 3 restores the default folio.
#show: centauri.with(stage: "review", h1-pagebreak: false, sensitivity: "Internal",
  folio: (n, total, s) => [#s -- page #n of #total])
Page one.
#furniture(sensitivity: "Public")
#pagebreak()
Page two.
#furniture(folio: auto)
#pagebreak()
Page three.

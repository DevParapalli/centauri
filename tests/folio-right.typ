#import "/lib.typ": *
// auto in the footer's right slot prints the folio there, and the centre stays empty.
#show: centauri.with(stage: "review", h1-pagebreak: false, sensitivity: "Internal",
  footer: (center: none, right: auto), folio: (n, total, s) => [#s | #n])
Body.

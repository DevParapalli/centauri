// A theme written out by hand that leaves a key out stops the build and names it.
#import "/lib.typ": *
#let t = centauri-theme
#let _ = t.remove("words")
#show: centauri.with(theme: t)
Body.

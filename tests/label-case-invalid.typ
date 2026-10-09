#import "/lib.typ": make-kit, theme
#let (centauri, ..) = make-kit(theme() + (label-case: "title"))
#show: centauri.with(stage: "review")
Body.

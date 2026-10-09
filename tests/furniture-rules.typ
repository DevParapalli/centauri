#import "/lib.typ": *
#show: centauri.with(stage: "review", h1-pagebreak: false)
Page one keeps the default hairlines.
#furniture(header-rule: none, footer-rule: 2pt + rgb("#ff0000"))
#pagebreak()
Page two has no header rule and a thick red footer rule.
#pagebreak()
Page three keeps the change: rules left out of `furniture` are kept.

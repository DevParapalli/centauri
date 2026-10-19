#import "/lib.typ": *
#show: centauri.with(stage: "review", theme: extend(centauri-theme, (
  furniture: (header: (left: [L], right: [R])),
  sensitivity: (default: "Internal"),
)))
= One
#furniture(footer: (left: [CLIENT], right: [NOTE]), sensitivity: "Confidential")
#pagebreak()
Two
#furniture(footer: (left: none, right: none), sensitivity: "Public")
#pagebreak()
Three

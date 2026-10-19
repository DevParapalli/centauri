// A sensitivity outside the theme's levels stops the build.
#import "/lib.typ": *
#show: centauri.with(stage: "review", theme: extend(centauri-theme, (
  sensitivity: (default: "Internal", levels: ("Public", "Internal", "Confidential")),
)))
Body.
#furniture(sensitivity: "Confidental")

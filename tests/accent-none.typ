// A theme without accents stops the build on use-accent.
#import "/lib.typ": *
#show: centauri.with(stage: "review", theme: extend(centauri-theme, (accents: none)))
Body.
#use-accent("teal")

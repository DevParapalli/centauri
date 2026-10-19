// A one-page document that opens with a grid, not a heading, shows the theme's furniture on page 1.
#import "/lib.typ": *
#show: centauri.with(stage: "review", theme: extend(centauri-theme, (
  furniture: (header: (left: [BRIEFHEAD]), footer: (left: [BRIEFFOOT])),
  sensitivity: (default: "Internal"),
)))
#grid(columns: 2)[Brief][One page.]

// A one-page document that opens with a grid, not a heading, still shows its own
// header and footer settings on page 1.
#import "/lib.typ": *
#show: centauri.with(stage: "review", header: (left: [BRIEFHEAD]), footer: (left: [BRIEFFOOT]), sensitivity: "Internal")
#grid(columns: 2)[Brief][One page.]

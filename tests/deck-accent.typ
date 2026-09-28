// A deck accent other than the theme default must converge in a deck of any length.
// Also exercises tile, table-slide align and the bars-chart minimum width.
#import "/lib.typ": *
#show: centauri.with(kind: "deck", accent: "ember", title: "Accent convergence")

#for i in range(6) {
  claim(title: [Slide #(i + 1) keeps the deck accent])[#tile[*Run #(i + 1)* \ Plain tonal card.]]
}
#table-slide(title: [Text tables align left when asked], columns: 2, header: ([Ticket], [Summary]), align: left,
  [T-1], [Disk full on build agent], [T-2], [Login loop after reset])
#exhibit(title: [Short bars keep their value pill inside])[#bars-chart(([the], 0.4, [0.4]), ([ticket], 12, [12]), ([disk], 30, [30]))]
#exercise(title: [Exercises take the second accent], task: [Route four tickets.], minutes: 10, output: [A table.])

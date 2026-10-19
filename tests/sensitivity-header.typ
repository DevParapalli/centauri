// The sensitivity prints from a header slot and changes with `furniture` from the next page.
#import "/lib.typ": *
#show: centauri.with(stage: "review", theme: extend(centauri-theme, (
  furniture: (header: (right: () => theme-now().sensitivity)),
  sensitivity: (default: "MARK-INTERNAL", levels: ("MARK-PUBLIC", "MARK-INTERNAL")),
)))
Page one.
#furniture(sensitivity: "MARK-PUBLIC")
#context assert.eq(theme-now().sensitivity, "MARK-INTERNAL", message: "a change waits for the next page")
#pagebreak()
Page two.
#context assert.eq(theme-now().sensitivity, "MARK-PUBLIC")

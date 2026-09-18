#import "/lib.typ": *
#show: centauri.with(stage: "review")

#let ground-is-legible() = context {
  let q = if tone.get() == "dark" { theme().dark } else { theme().light }
  assert(contrast(q.ink-hi, q.paper) >= 4.5, message: "ink-hi on the active ground")
  assert(contrast(q.ink-mid, q.paper) >= 4.5, message: "ink-mid on the active ground")
}

#context assert.eq(tone.get(), "light", message: "body tone")
#ground-is-legible()

#cover(tone: "dark", title: [Dark])[
  #context assert.eq(tone.get(), "dark", message: "tone inside a dark cover")
  #ground-is-legible()
  #kpi([Label], [12 / 33], foot: [detail])
  #card[Card text.]
  #pill(tone: "mint")[Healthy] #status("partial") #chip[CHIP] #tba[gap]
  #callout(tone: "amber", title: [Heads up.])[Text.]
  #data-table(columns: 2, header: ([A], [B]), [a], [b])
]

#context assert.eq(tone.get(), "light", message: "tone restored after a dark cover")
#ground-is-legible()

#cover(tone: "light", title: [Light])[
  #context assert.eq(tone.get(), "light", message: "tone inside a light cover")
  #ground-is-legible()
]

= Body
#context assert.eq(tone.get(), "light", message: "tone after a light cover")
#ground-is-legible()

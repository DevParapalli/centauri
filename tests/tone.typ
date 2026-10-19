#import "/lib.typ": *
#show: centauri.with(stage: "review")

#let ground-is-legible() = context {
  let q = theme-now().colors
  assert(contrast(q.ink-hi, q.paper) >= 4.5, message: "ink-hi on the active ground")
  assert(contrast(q.ink-mid, q.paper) >= 4.5, message: "ink-mid on the active ground")
}

#context assert.eq(tone.get(), "light", message: "body tone")
#ground-is-legible()

#cover(tone: "dark", title: [Dark])[
  #context assert.eq(tone.get(), "dark", message: "tone inside a dark cover")
  #context assert.eq(theme-now().colors.paper, centauri-theme.colors.dark.paper, message: "dark palette inside a dark cover")
  #ground-is-legible()
  #kpi([Label], [12 / 33], foot: [detail])
  #card[Card text.]
  #pill(tone: "success")[Healthy] #status("partial") #chip[CHIP] #tba[gap]
  #callout(tone: "caution", title: [Heads up.])[Text.]
  #data-table(columns: 2, header: ([A], [B]), [a], [b])
  #themed(t => rect(width: 1cm, height: 0.5cm, fill: t.colors.panel))
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

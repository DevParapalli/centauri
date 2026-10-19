// A bare cover sets its body from the top of its own margins, with no title layout.
#import "/lib.typ": *
#show: centauri.with(stage: "review")
#cover(tone: "dark", layout: "bare", margin: (x: 1cm, top: 1cm, bottom: 1cm), furniture: false, backdrop: none)[
  BARE-TOP
  #context assert.eq(theme-now().tone, "dark", message: "a bare cover keeps its tone")
]
= After
#context assert.eq(theme-now().tone, "light", message: "tone restored after a bare cover")

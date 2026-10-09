#import "/lib.typ": make-kit, theme
#let (centauri, kv, risk, ..) = make-kit(theme() + (label-case: "as-written"))
#show: centauri.with(stage: "review")
= Label case
#figure(rect(width: 4cm, height: 1.5cm), caption: [An ordinary figure.])
#kv(([Owner key], [Value]))
#risk[A risk card.]

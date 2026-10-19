// Page 1: no backdrop; page 2: content (a red block); page 3: a function that reads the tone.
#import "/lib.typ": *
#show: centauri.with(stage: "review")
#cover(tone: "light", title: [None], backdrop: none)
#cover(tone: "light", title: [Content], backdrop: place(top + left, rect(width: 3cm, height: 3cm, fill: rgb("#ff0000"))))
#cover(tone: "dark", title: [Function], backdrop: () => place(bottom + left, dx: 1cm, dy: -1cm,
  text(fill: theme-now().colors.ink-hi)[BACKDROP-TONE-#theme-now().tone]))

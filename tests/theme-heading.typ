// Heading functions come from the theme; heading-number gives the formatted number.
#import "/lib.typ": *
#show: centauri.with(stage: "review", theme: extend(centauri-theme, (
  h1: it => block[CUSTOM-H1 #heading-number(it) #it.body],
  h2: it => block[CUSTOM-H2 #heading-number(it) #it.body #if at-page-top() [TOP] else [MID]],
)))
#context assert.eq(theme-now().heading-numbers, "inline")
= First
Text.
== Second

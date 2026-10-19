// An accent set with use-accent holds across page breaks and with-accent restores the one before.
#import "/lib.typ": *
#show: centauri.with(stage: "review")
#context assert.eq(theme-now().accent, none)
#use-accent("teal")
#pagebreak()
#context assert.eq(theme-now().accent, "teal", message: "accent after a page break")
#with-accent("ember")[#context assert.eq(theme-now().accent, "ember")]
#context assert.eq(theme-now().accent, "teal", message: "accent after with-accent")
#context assert.eq(theme-now().colors.accent, centauri-theme.accents.teal.light.accent)

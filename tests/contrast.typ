// A theme override whose link colour falls below 4.5:1 on the page stops the build.
#import "/lib.typ": *
#for a in accents.keys() {
  let th = theme(accent: a)
  for q in (th.light, th.dark) {
    assert(contrast(q.link, q.paper) >= 4.5, message: a + " link on paper")
    assert(contrast(q.link, q.cover) >= 4.5, message: a + " link on cover")
    for s in ("mint", "amber", "rose", "sky") {
      assert(contrast(q.at(s).text, q.at(s).fill) >= 4.5, message: a + " " + s + " text on fill")
    }
  }
}
#let t = theme()
#let bad = t + (palettes: t.palettes + (indigo: t.palettes.indigo + (light: t.palettes.indigo.light + (link: rgb("#9094B0")))))
#let (centauri, ..rest) = make-kit(bad)
#show: centauri.with()
Should not compile.

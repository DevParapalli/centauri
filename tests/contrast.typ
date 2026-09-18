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
#let bad = theme() + (light: theme().light + (link: rgb("#9094B0")))
#let (centauri, ..rest) = make(bad)
#show: centauri.with()
Should not compile.

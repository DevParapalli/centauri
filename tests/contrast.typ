// Every palette Centauri's theme produces is legible; a theme whose link colour falls below
// 4.5:1 on the page stops the build.
#import "/lib.typ": *
#let t = centauri-theme
#for a in (none,) + t.accents.keys() {
  for tn in ("light", "dark") {
    let q = t.colors.at(tn) + if a == none { (:) } else { t.accents.at(a).at(tn) }
    assert(contrast(q.link, q.paper) >= 4.5, message: repr(a) + " link on paper")
    assert(contrast(q.link, q.cover) >= 4.5, message: repr(a) + " link on cover")
    for s in ("success", "caution", "danger", "info") {
      assert(contrast(q.at(s).text, q.at(s).fill) >= 4.5, message: repr(a) + " " + s + " text on fill")
    }
  }
}
#show: centauri.with(theme: extend(t, (accents: (indigo: (light: (link: rgb("#9094B0")), dark: (:))))))
Should not compile.

#import "/lib.typ": *
// fit-logo shrinks to the tighter of height and max-width, keeps the aspect ratio, never enlarges.
#let logo = rect(width: 4cm, height: 2cm)
#let near(a, b) = calc.abs((a - b).to-absolute() / 1pt) < 0.01
#context {
  let check(fitted, w, h, what) = {
    let s = measure(fitted)
    assert(near(s.width, w) and near(s.height, h), message: what + ": got " + repr(s.width) + " x " + repr(s.height))
  }
  check(fit-logo(logo, height: 1cm), 2cm, 1cm, "height cap")
  check(fit-logo(logo, max-width: 1cm), 1cm, 0.5cm, "width cap")
  check(fit-logo(logo, height: 1cm, max-width: 1cm), 1cm, 0.5cm, "tighter cap wins")
  check(fit-logo(logo, height: 5cm, max-width: 10cm), 4cm, 2cm, "never enlarged")
}

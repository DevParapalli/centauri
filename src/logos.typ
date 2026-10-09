// Logo sizing and inline placement. Theme-free: these take lengths, not tokens.

// Scale factor that fits size `s` within `height` and `max-width`, capped at 100%.
#let _shrink(s, height, max-width) = calc.min(
  100%,
  if height == auto { 100% } else { height / s.height * 100% },
  if max-width == auto { 100% } else { max-width / s.width * 100% },
)

/// Scale a logo (an image, a box or any content) down to fit `height` and `max-width`; never up.
#let fit-logo(logo, height: auto, max-width: auto) = context {
  let s = measure(logo)
  let k = _shrink(s, height, max-width)
  box(width: s.width * k, height: s.height * k, place(top + left, scale(k, reflow: true, logo)))
}

// Fit, then centre on the line's cap-height midline. A box holding text would otherwise align
// its own text baseline with the line, so the logo is placed inside a fixed-size box that hides
// it. The label stops the `box` rule in `logo-line` from wrapping its own output again.
#let _line-logo(logo, height, max-width) = context {
  let s = measure(logo)
  let k = _shrink(s, height, max-width)
  let (w, h) = (s.width * k, s.height * k)
  let cap = measure(text("H")).height
  [#box(width: w, height: h, baseline: (h - cap) / 2, place(top + left, scale(k, reflow: true, logo)))<centauri-line-logo>]
}

/// Every image and box in `body` is scaled down to `height` and `max-width`, then centred halfway
/// up the capitals of the surrounding text, so a logo reads level with the words beside it.
#let logo-line(body, height: auto, max-width: auto) = {
  show image: it => _line-logo(it, height, max-width)
  show box: it => if it.at("label", default: none) == <centauri-line-logo> { it } else { _line-logo(it, height, max-width) }
  body
}

// Theme overrides and the checks every theme passes before a document uses it.

#import "theme.typ": centauri-theme

// Replaced whole by an override, never merged: a brand's accents are its own set, not
// Centauri's plus its own.
#let _replace = ("accents",)
// Keys whose names a theme chooses.
#let _open = ("accents", "colors.light.ramp", "colors.dark.ramp")

#let _merge(base, over, path) = {
  let out = base
  for (k, v) in over {
    let p = if path == "" { k } else { path + "." + k }
    assert(k in base, message: "centauri: unknown theme key " + p)
    out.insert(k, if type(base.at(k)) == dictionary and type(v) == dictionary and p not in _replace {
      _merge(base.at(k), v, p)
    } else { v })
  }
  out
}

/// `base` with `overrides` merged in, dictionary by dictionary. Any key `base` does not have
/// stops the build. `accents` is replaced whole.
#let extend(base, overrides) = {
  assert(type(overrides) == dictionary, message: "centauri: extend takes a dictionary of overrides")
  _merge(base, overrides, "")
}

#let _shape(t, ref, path) = {
  if path in _open { return }
  for k in ref.keys() {
    assert(k in t, message: "centauri: theme is missing " + (if path == "" { k } else { path + "." + k }))
  }
  for (k, v) in t {
    let p = if path == "" { k } else { path + "." + k }
    assert(k in ref, message: "centauri: unknown theme key " + p)
    if type(ref.at(k)) == dictionary and type(v) == dictionary { _shape(v, ref.at(k), p) }
  }
}

#let _slot-ok(v) = v == none or type(v) in (content, str, function)

/// Stops the build, naming the key, when `t` is not a complete theme.
#let validate(t) = {
  assert(type(t) == dictionary, message: "centauri: a theme is a dictionary")
  _shape(t, centauri-theme, "")
  for tone in ("light", "dark") {
    for (name, a) in if t.accents == none { (:) } else { t.accents } {
      for k in a.at(tone).keys() {
        assert(k in t.colors.at(tone), message: "centauri: accent " + name + " sets unknown colour " + k)
      }
    }
  }
  for n in range(1, 7) {
    assert(type(t.at("h" + str(n))) == function, message: "centauri: theme h" + str(n) + " must be a function of the heading")
  }
  for (k, v) in t.elements {
    assert(type(v) == function, message: "centauri: theme elements." + k + " must be a function")
  }
  for row in ("header", "footer") {
    for (k, v) in t.furniture.at(row) {
      assert(_slot-ok(v), message: "centauri: furniture " + row + "." + k + " must be content, none or a function")
    }
  }
  assert(t.label-case in ("upper", "as-written"), message: "centauri: label-case must be upper or as-written")
  let s = t.sensitivity
  assert(s.levels == none or type(s.levels) == array, message: "centauri: sensitivity levels must be an array or none")
  assert(s.levels == none or s.default == none or s.default in s.levels,
    message: "centauri: default sensitivity is not one of the theme's levels")
}

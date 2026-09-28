#!/bin/sh
# Compile checks for Centauri. Run from the repository root.
set -u
out=$(mktemp -d)
fail=0
compile() { typst compile --root . --font-path fonts --ignore-system-fonts "$@"; }

# pass FILE [TYPST OPTIONS...]: must compile with no errors and no warnings.
pass() { if compile "$@" "$out/x.pdf" 2>"$out/err" && [ ! -s "$out/err" ]; then echo "ok    $*"; else echo "FAIL  $* (expected a clean build)"; cat "$out/err"; fail=1; fi; }
reject() { if compile "$1" "$out/x.pdf" 2>"$out/err"; then echo "FAIL  $1 (expected failure: $2)"; fail=1;
  elif grep -q "$2" "$out/err"; then echo "ok    $1"; else echo "FAIL  $1 (wrong error)"; cat "$out/err"; fail=1; fi; }

# Documents
pass examples/showcase.typ
pass tests/final-clean.typ
pass tests/tone.typ
pass tests/handbook.typ
pass tests/letter.typ
pass tests/h1-compact.typ
reject tests/final-todo.typ "unresolved todo"
reject tests/final-lint.typ "lint match"
reject tests/contrast.typ "below 4.5:1"
reject tests/h1-banner.typ "kind brief allows 1"
reject tests/h1-style-invalid.typ "h1-style must be"

# Decks: every mode and both projections
pass examples/deck.typ
pass examples/deck-accents.typ --input projection=light
pass examples/deck-accents.typ --input projection=dark
pass tests/deck-accent.typ
for args in "" "--input projection=dark" "--input mode=handout" "--input mode=titles" "--input notes=true"; do
  # shellcheck disable=SC2086
  pass tests/slides.typ $args
done
reject tests/slide-overflow.typ "overflows its page"
reject tests/slide-title-stop.typ "ends with a full stop"

compile tests/captions.typ "$out/c.pdf" 2>/dev/null
for want in "FIGURE 1" "TABLE 1"; do
  if pdftotext -layout "$out/c.pdf" - | grep -qF "$want"; then echo "ok    caption label $want"; else echo "FAIL  caption label $want"; fail=1; fi
done

compile tests/furniture.typ "$out/f.pdf" 2>/dev/null
for spec in "1:1/3 | Internal" "2:CLIENT" "2:2/3 | Confidential" "3:3/3 | Public"; do
  page=${spec%%:*}; want=${spec#*:}
  if pdftotext -f "$page" -l "$page" -layout "$out/f.pdf" - | grep -qF "$want"; then echo "ok    furniture page $page: $want"; else echo "FAIL  furniture page $page: $want"; fail=1; fi
done
if pdftotext -f 3 -l 3 -layout "$out/f.pdf" - | grep -qF "CLIENT"; then echo "FAIL  furniture page 3 still shows client slot"; fail=1; else echo "ok    furniture page 3 cleared"; fi

compile tests/first-page.typ "$out/p.pdf" 2>/dev/null
for want in "BRIEFHEAD" "BRIEFFOOT"; do
  if pdftotext -f 1 -l 1 -layout "$out/p.pdf" - | grep -qF "$want"; then echo "ok    first page furniture $want"; else echo "FAIL  first page furniture $want"; fail=1; fi
done

# Every complete example in the docs (a typ block that opens with the package import) compiles cleanly.
for doc in README.md docs/reference.md; do
  awk -v dir="$out" -v tag="$(basename "$doc" .md)" '
    /^```typ$/ { n++; f = dir "/" tag "-" n ".typ"; inblock = 1; first = 1; next }
    /^```$/ && inblock { inblock = 0; next }
    inblock { if (first && $0 !~ /^#import "@preview\/centauri/) { inblock = 0; next }
              first = 0; sub(/"@preview\/centauri:[0-9.]*"/, "\"/lib.typ\""); print > f }
  ' "$doc"
done
for f in "$out"/README-*.typ "$out"/reference-*.typ; do
  [ -e "$f" ] || continue
  cp "$f" "./.doc-example.typ"
  if compile .doc-example.typ "$out/x.pdf" 2>"$out/err" && [ ! -s "$out/err" ]; then echo "ok    example $(basename "$f")"; else echo "FAIL  example $(basename "$f")"; cat "$out/err"; fail=1; fi
done
rm -f .doc-example.typ

# docs/reference.md documents every name lib.typ exports, and nothing else.
exported=$(sed -n '/^#import "src/s/.*: //p; /^#let [a-z]/{ s/^#let \([a-z-]*\).*/\1/p; }; /^#let (/,/) = kit/{ s/^#let (//; s/) = kit//; s/\.\.rest//; p; }' lib.typ | tr ',' '\n' | tr -d ' ' | grep -v '^$' | sort -u)
documented=$(sed -n 's/^### `\([a-z0-9-]*\)`.*/\1/p' docs/reference.md | sort -u)
missing=$(printf '%s\n' "$exported" | grep -vxF "$documented")
extra=$(printf '%s\n' "$documented" | grep -vxF "$exported")
if [ -z "$missing" ] && [ -z "$extra" ]; then echo "ok    docs/reference.md covers every export"; else
  [ -n "$missing" ] && echo "FAIL  undocumented exports: $(echo $missing)"
  [ -n "$extra" ] && echo "FAIL  documented but not exported: $(echo $extra)"
  fail=1
fi

# Components must read the tone-resolved palette, never the light one captured by make().
if awk '/^    theme: t,/{f=1} f && /\<p\./{print "      " FILENAME ":" NR; c++} END{exit !c}' src/make.typ; then
  echo "FAIL  components reference the light palette directly"; fail=1
else
  echo "ok    components use the tone-resolved palette"
fi

rm -rf "$out"
exit $fail

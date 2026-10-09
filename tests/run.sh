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
reject tests/label-case-invalid.typ "label-case must be"
reject tests/furniture-rule-invalid.typ "header-rule must be a stroke, none or auto"
reject tests/folio-invalid.typ "folio must be a function"
reject tests/annexes-invalid.typ "annexes numbering takes two patterns"
pass tests/fit-logo.typ

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
# Labels are letter-spaced capitals; some pdftotext versions split them into "F I G U R E",
# so the match allows a space between letters.
for want in "FIGURE 1" "TABLE 1"; do
  pattern=$(printf '%s' "$want" | sed 's/./& ?/g')
  if pdftotext -layout "$out/c.pdf" - | grep -qE "$pattern"; then echo "ok    caption label $want"; else echo "FAIL  caption label $want"; fail=1; fi
done

compile tests/label-case.typ "$out/l.pdf" 2>/dev/null
for want in "Figure 1" "Owner key" "Risk R1"; do
  if pdftotext -layout "$out/l.pdf" - | grep -qF "$want"; then echo "ok    label-case as-written: $want"; else echo "FAIL  label-case as-written: $want"; fail=1; fi
done
if pdftotext -layout "$out/l.pdf" - | grep -qE "FIGURE|OWNER KEY|RISK"; then echo "FAIL  label-case as-written still prints capitals"; fail=1; else echo "ok    label-case as-written prints no capitals"; fi

# Rules: page 1 keeps both hairlines; `furniture` then drops the header rule and sets a red
# footer rule, which page 2 shows and page 3 keeps.
compile tests/furniture-rules.typ "$out/r.pdf" 2>/dev/null
for spec in "1:2:0" "2:0:1" "3:0:1"; do
  page=${spec%%:*}; rest=${spec#*:}; want_hair=${rest%%:*}; want_red=${rest#*:}
  pdftocairo -svg -f "$page" -l "$page" "$out/r.pdf" "$out/r.svg"
  hair=$(grep -c 'stroke-width="0.5"' "$out/r.svg"); red=$(grep -c 'stroke="rgb(100%, 0%, 0%)"' "$out/r.svg")
  if [ "$hair" = "$want_hair" ] && [ "$red" = "$want_red" ]; then echo "ok    furniture rules page $page"; else echo "FAIL  furniture rules page $page: $hair hairlines, $red red (want $want_hair, $want_red)"; fail=1; fi
done

# Folio: a custom function on page 1, a new sensitivity on page 2, the default restored on page 3.
compile tests/folio.typ "$out/fo.pdf" 2>/dev/null
for spec in "1:Internal – page 1 of 3" "2:Public – page 2 of 3" "3:3/3 | Public"; do
  page=${spec%%:*}; want=${spec#*:}
  if pdftotext -f "$page" -l "$page" "$out/fo.pdf" - | grep -qF "$want"; then echo "ok    folio page $page: $want"; else echo "FAIL  folio page $page: $want"; fail=1; fi
done

# auto in the footer's right slot prints the folio there: "Internal" sits in the right third.
compile tests/folio-right.typ "$out/fr.pdf" 2>/dev/null
mid=$(pdftotext -bbox "$out/fr.pdf" - | awk -F'"' '/<page/ {w=$2} />Internal</ {printf "%d", ($2+$6)/2*100/w}')
if [ -n "$mid" ] && [ "$mid" -gt 67 ]; then echo "ok    folio in the right footer slot ($mid%)"; else echo "FAIL  folio not in the right footer slot (${mid:-missing}%)"; fail=1; fi

# Annexes: numbering restarts at A with no divider by default; a title adds a divider page, and
# word and numbering set the reference word and patterns.
compile tests/annexes.typ "$out/an.pdf" 2>/dev/null
for want in "2 Body two" "See Annex A." "A Key personnel" "A.1 Delivery lead" "B Glossary"; do
  if pdftotext "$out/an.pdf" - | grep -qxF "$want"; then echo "ok    annexes: $want"; else echo "FAIL  annexes: $want"; fail=1; fi
done
[ "$(pdfinfo "$out/an.pdf" | awk '/^Pages:/ {print $2}')" = 1 ] && echo "ok    annexes: no divider by default" || { echo "FAIL  annexes: unexpected divider"; fail=1; }
compile tests/annexes-custom.typ "$out/ac.pdf" 2>/dev/null
for spec in "1:See Appendix I." "2:Appendices" "2:Supporting material" "3:I Key personnel" "3:I.a Delivery lead" "3:II Glossary"; do
  page=${spec%%:*}; want=${spec#*:}
  if pdftotext -f "$page" -l "$page" "$out/ac.pdf" - | grep -qxF "$want"; then echo "ok    annexes custom page $page: $want"; else echo "FAIL  annexes custom page $page: $want"; fail=1; fi
done

# logo-line: an image (page 1) and a box with text (page 2), both 1.2cm, are capped at 0.8cm
# (94px at 300 ppi) and centred on the cap-height midline within a pixel.
compile tests/logo-line.typ "$out/ll.pdf" 2>/dev/null
for page in 1 2; do
  pdftoppm -f "$page" -l "$page" -r 300 -singlefile "$out/ll.pdf" "$out/ll"
  set -- $(uv run --quiet tests/centre.py "$out/ll.ppm")
  if [ "$1" -le 95 ] && [ "$2" -le 2 ]; then echo "ok    logo-line page $page: ${1}px, offset $2"; else echo "FAIL  logo-line page $page: ${1}px tall, offset $2 half-pixels"; fail=1; fi
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

uv run --quiet tests/sync-tokens.py || fail=1

rm -rf "$out"
exit $fail

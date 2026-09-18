#!/bin/sh
# Compile checks for Centauri. Run from the repository root.
set -u
out=$(mktemp -d)
fail=0
compile() { typst compile --root . --font-path fonts --ignore-system-fonts "$@"; }

pass() { if compile "$1" "$out/x.pdf" 2>"$out/err"; then echo "ok    $1"; else echo "FAIL  $1 (expected success)"; cat "$out/err"; fail=1; fi; }
reject() { if compile "$1" "$out/x.pdf" 2>"$out/err"; then echo "FAIL  $1 (expected failure: $2)"; fail=1;
  elif grep -q "$2" "$out/err"; then echo "ok    $1"; else echo "FAIL  $1 (wrong error)"; cat "$out/err"; fail=1; fi; }

pass examples/showcase.typ
pass tests/final-clean.typ
pass tests/tone.typ
reject tests/final-todo.typ "unresolved todo"
reject tests/final-lint.typ "lint match"
reject tests/contrast.typ "below 4.5:1"

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

# Components must read the tone-resolved palette, never the light one captured by make().
if awk '/^    theme: t,/{f=1} f && /\<p\./{print "      " FILENAME ":" NR; c++} END{exit !c}' src/make.typ; then
  echo "FAIL  components reference the light palette directly"; fail=1
else
  echo "ok    components use the tone-resolved palette"
fi

rm -rf "$out"
exit $fail

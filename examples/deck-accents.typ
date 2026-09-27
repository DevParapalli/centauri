// All four accents in one projection. Build twice:
//   typst compile --input projection=dark  examples/deck-accents.typ deck-accents-dark.pdf
//   typst compile --input projection=light examples/deck-accents.typ deck-accents-light.pdf
#import "/lib.typ": *

#let projection = sys.inputs.at("projection", default: "dark")
#show: centauri.with(kind: "deck", aspect: "16:9", projection: projection, label: "Centauri accents", date: projection + " projection", presenter: "Centauri 0.2.0", title: "Centauri accents, " + projection)

#for (i, a) in ("indigo", "teal", "ember", "lime").enumerate() {
  let name = upper(a.first()) + a.slice(1)
  title-slide(accent: a, number: [#(i + 1)], side: [Internal], title: [#name, #projection projection], subtitle: [Title, section, content, statement, comparison and code slides in one accent.], facts: ([#name], [#projection], [16:9]))
  exhibit(accent: a, title: [Accuracy rises with each method], source: [Synthetic])[#columns-chart(height: 6.5cm, ([Rules], 61, [61%]), ([TF-IDF], 84, [84%]), ([Embeddings], 89, [89%]), ([LLM], 91, [91%]))]
  section-slide(accent: a, number: str(i + 1), title: [Start from the problem], subtitle: [Section divider on the accent ground.])
  claim(accent: a, title: [Most failed AI projects chose the tool before they understood the problem], source: [Illustrative])[
    #cols(widths: (1.2fr, 1fr),
      [The same ticket, #hl[“no space left on device”], can be routed four ways. Each costs a different amount to build and run, and each fails in its own way. See the #link("https://proxima.parapalli.dev")[design system].],
      [
        - Rules: a person writes every decision
        - Classical ML: learns from labelled history
        - Deep learning: learns its own features
        - Generative AI: follows a described task
      ],
    )
  ]
  statement(accent: a, sub: [Emphasis is carried by weight and ink; the accent draws only the line.])[The #hl[cheapest option] that meets the error budget wins.]
  compare(accent: a, title: [Write a rule when the rule is known; train a model when it lives in people’s heads], pick: "right",
    left: ([Rule], [
      - Known, stable logic
      - Every decision must be explainable
    ]),
    right: ([Model], [
      - Logic nobody has written down
      - Labelled history exists
    ]))
  code-slide(accent: a, title: [The rule version is six lines and never surprises anyone], file: "route_rules.py", highlight: (3, 4))[
    ```python
    import re

    def route(ticket: str) -> str:
        if re.search(r"no space|disk full", ticket, re.I):
            return "storage"
        return "triage"
    ```
  ]
}

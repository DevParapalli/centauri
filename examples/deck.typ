#import "/lib.typ": *

#let projection = sys.inputs.at("projection", default: "dark")
#show: centauri.with(kind: "deck", aspect: "16:9", projection: projection, accent: "indigo",
  label: "Series label", date: "Session · Year", presenter: "Presenter", title: "Deck title")

#title-slide(number: [0], side: [Audience or classification], title: [Deck title in five words or fewer], subtitle: [One sentence stating what the audience can do after this session.], facts: ([Duration], [Format], [Part n of m]))

#outline-slide(current: 1)

#section-slide(number: [1], title: [Section title], subtitle: [Who this section is for.])

#display-slide(title: [Display slide], sub: [One term or number, shown large])[Keyword]

#claim(title: [Claim slide: the title states the conclusion as a full sentence])[
  #cols(widths: (1.2fr, 1fr),
    [Left column carries the argument in two or three sentences. Use #hl[highlight] for the single phrase the audience must remember.],
    [
      - Supporting point one
      - Supporting point two
      - Supporting point three
      - Supporting point four
    ],
  )
  #notes[Speaker notes: what to say, what to ask the room, when to advance.]
]

#split(title: [Split slide: three parallel options], sub: [Same shape per panel, one line of contrast each.],
  ([Option A], [What it is. Its main strength, its main weakness.]),
  ([Option B], [What it is. Its main strength, its main weakness.]),
  ([Option C], [What it is. Its main strength, its main weakness.]),
)

#statement(sub: [Optional one-line context under the statement.])[One sentence with a #hl[highlighted phrase] that the deck returns to.]

#explain(title: [Explain slide: four terms, one definition each],
  ([Term one], [Definition in one sentence.]),
  ([Term two], [Definition in one sentence.]),
  ([Term three], [Definition in one sentence, with a second clause if needed.]),
  ([Term four], [Definition in one sentence.]),
)

#claim(title: [Claim with stats: the title states what the numbers prove], source: [Source line])[
  #cols(widths: (1fr, 1.1fr),
    [Before-and-after framing in two sentences. The numbers on the right carry the evidence.],
    stats(([000], [first metric]), ([00], [second metric]), ([0 s], [third metric])),
  )
]

#exhibit(title: [Column chart: the title states the trend, not the axes], source: [Source line])[
  #columns-chart(height: 7.5cm, ([Series A], 60, [60%]), ([Series B], 75, [75%]), ([Series C], 85, [85%]), ([Series D], 90, [90%]))
]

#exhibit(title: [Bar chart: sorted descending, labels carry units], source: [Source line])[
  #bars-chart(([Category A], 65, [65]), ([Category B], 42, [42]), ([Category C], 18, [18]), ([Category D], 12, [12]))
]

#compare(title: [Compare slide: the title states when each side applies], pick: "right",
  left: ([Left option], [
    - Condition one
    - Condition two
    - Condition three
  ]),
  right: ([Right option], [
    - Condition one
    - Condition two
    - Condition three
  ]),
)

#steps-slide(title: [Steps slide: a fixed sequence, current step marked], current: 3,
  [Step one], [Step two], [Step three], [Step four], [Step five])

#exercise(title: [Exercise slide: imperative title], minutes: 10,
  task: [What participants do, in whatever grouping, with what materials.],
  output: [What they produce by the end, stated concretely.])

#section-slide(number: [2], title: [Second section], subtitle: [Who this section is for.], accent: "teal")

#code-slide(title: [Code slide: the title states what the code demonstrates], file: "code/example.py", highlight: (3, 4), accent: "teal")[
  ```python
  import re

  def classify(text: str) -> str:
      if re.search(r"pattern", text, re.I):
          return "match"
      return "default"
  ```
]

#quote-slide(attribution: [Attribution])[A single sentence worth repeating, one or two lines long.]

#close(actions: ([First action for the audience.], [Second action for the audience.], [Third action for the audience.]), contact: [Contact line.])

// Every slide component on one 4:3 deck. Built in slides, handout and titles modes,
// light and dark (`--input projection=dark`), with no warnings.
#import "/lib.typ": *
#let projection = sys.inputs.at("projection", default: "light")
#show: centauri.with(kind: "deck", aspect: "4:3", projection: projection, accent: "teal", label: "Slides test", date: "Test", presenter: "Centauri", title: "Slides test")

#title-slide(number: [1], side: [Internal], title: [Every slide component in one deck], subtitle: [A build check.], facts: ([4:3], [Teal]))
#outline-slide()
#section-slide(title: [Evidence], subtitle: [Charts and tables.])
#claim(title: [A claim slide carries one exhibit], source: [Test])[#tile[*Run 1* \ A tonal tile inside a slide body.]]
#exhibit(title: [Short bars keep their value inside the bar])[#bars-chart(([the], 0.4, [0.4]), ([ticket], 12, [12]), ([disk], 30, [30]))]
#exhibit(title: [Columns rise with the value])[#columns-chart(height: 5cm, ([A], 10), ([B], 20), ([C], 30))]
#table-slide(title: [Numbers align right by default], columns: 3, header: ([Item], [2025], [2026]), [Tickets], [120], [96], [Hours], [40], [31])
#table-slide(title: [Text tables align left when asked], columns: 2, header: ([Ticket], [Summary]), align: left, [T-1], [Disk full on the build agent], [T-2], [Login loop after a reset])
#section-slide(title: [Explanation], subtitle: [Section preview cards grow to fit long titles.])
#claim(title: [This slide title is long enough to wrap over more than one line inside a preview card])[#stats(([61%], [Rules]), ([91%], [Model]))]
#statement(sub: [A pacing slide.])[The #hl[cheapest option] that meets the error budget wins]
#quote-slide(attribution: [Someone])[A quotation in the serif.]
#explain(title: [Two terms, defined], ([Rule], [Written by a person.]), ([Model], [Learned from history.]))
#compare(title: [Write a rule when the rule is known], pick: "left", left: ([Rule], [Known logic.]), right: ([Model], [Unwritten logic.]))
#split(title: [Split slide], sub: [Panel and tiles.], ([One], [First.]), ([Two], [Second.]))
#display-slide(title: [Display])[Tokens]
#code-slide(title: [A listing with one highlighted line], file: "x.py", highlight: (2,))[```python
def f(x):
    return x + 1
```]
#steps-slide(title: [Three steps in order], current: 2, [Collect], [Label], [Train])
#exercise(title: [Route four tickets], task: [Route each ticket.], minutes: 10, output: [A table.])
#appendix(title: [Appendix evidence])[#cols([#metric([12], [Tickets])], [Dense text.])]
#close(actions: ([Read the notes], [Try the exercise]), contact: [team\@example.com])
#notes[Speaker notes for the last slide.]

// Handbook parts, sidenotes, annexes and the running head in the header centre.
#import "/lib.typ": *
#show: centauri.with(kind: "handbook", stage: "review", header: (center: current-section))
#part([Foundations], subtitle: [Why the handbook exists.])
= Scope
Text with a sidenote.#sidenote[In the outer margin.]
#part([Practice])
= Method
Text.
#show: annexes
= Glossary
#glossary(("Rule", [Written by a person.]), ("Model", [Learned from history.]))

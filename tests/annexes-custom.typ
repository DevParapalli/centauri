#import "/lib.typ": *
// A divider is an ordinary cover; annexes sets the word Appendix and Roman numbering.
#show: centauri.with(stage: "review")
= Body
See @key.
#cover(title: [Appendices], subtitle: [Supporting material], backdrop: none, furniture: false)
#show: annexes.with(word: "Appendix", numbering: ("I", "I.a"))
= Key personnel <key>
== Delivery lead
= Glossary

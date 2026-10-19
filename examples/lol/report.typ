// A LOL document: the brand's template, its covers and both furniture arrangements.
#import "lib.typ": *

#show: lol.with(title: "Service desk review", author: "LOL Service Desk", stage: "final")

#cover(tone: "dark", title: [Service desk review], subtitle: [Tickets, tools and what to automate first],
  meta: (([Owner], [Service desk]), ([Period], [Q3 2026]), ([Class], [LOL Internal])))[
  #logo(height: 0.8cm)
]

#outline(depth: 1)

#pagebreak()
= Where the tickets come from

Every department raises tickets: operations, warehouse, finance, sales, customer service, HR and legal. Most arrive through the ServiceDesk AI form; the rest by phone.#footnote[Phone tickets are typed in by the agent who takes the call.]

#data-table(columns: (1fr, auto, auto), align: (left, right, right), header: ([Queue], [Tickets], [Share]),
  [Tracklane bookings], [412], [31%],
  [Ledgerline period close], [268], [20%],
  [Harbor MDM enrolment], [190], [14%],
  [Everything else], [457], [35%],
)

== Contractor laptops

Contractors' laptops come from their agency and go through Harbor MDM, so they are not self-serve.

#quote(block: true)[If a tool is in the directory, use it up to its limit.]

#risk[Enrolment backlog grows while the agency re-images laptops by hand.]

#furniture(sensitivity: "LOL Confidential")
#pagebreak()
= What to automate first

The InvoiceHub batch status check is one call and one rule:

```python
def batch_late(status, now):
    return status.state != "done" and now > status.due
```

#decision[Automate the InvoiceHub status check before anything that needs a model.]

#furniture(..presets.ledger)
#cover(tone: "light", title: [Schedules], backdrop: none, furniture: false)
#show: annexes
= Registers
#register-table("risk")
#register-table("decision")

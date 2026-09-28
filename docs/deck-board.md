# Centauri deck design board (consolidated)

Status: design rationale for the deck support shipped in Centauri 0.2.0. This board explains why decks look and behave as they do. The API (functions, arguments, build rules) is in [`reference.md`](reference.md); where the two differ, `reference.md` is authoritative. Sections below that record what was built are marked **As built**.

Scope: slide support in Centauri — 4:3 and 16:9, light-first, four Proxima accents. Typefaces are Centauri's own: Atkinson Hyperlegible Next for text, Atkinson Hyperlegible Mono for code and labels, Newsreader for quotations (the board was drafted against Source Sans 3 / Source Serif 4 / Source Code Pro; the rules carry over unchanged). Existing Centauri decisions are fixed: one heading font, serif reserved for quotations and drop cap, no eyebrow labels, nothing in the header centre of documents unless the author opts in.

This merges two source sets of very different rigor. Where they conflict, that's called out rather than smoothed over.

- **Board (primary, evidence-based):** draws on sources that each summarize large samples — Tufte's pamphlet (10 case studies, 2,000 PowerPoint slides, 32 non-PowerPoint controls), Alley's controlled assertion-evidence studies, Mayer's multimedia-learning meta-analyses, Figma's 100+ funded-deck collection, bestpitchdeck's archive, plus canonical themes (Metropolis, Touying). Not a first-hand review of hundreds of individual decks.
- **Pattern list (secondary, unverified):** a set of 10 patterns from an unattributed analysis of 15 "top-tier" systems (Stripe, Vercel, Linear, HashiCorp, GitHub, IBM Design). No visible methodology or sourcing — treat as SEO/vendor-style inspiration, same tier as the McKinsey-style guides already flagged below, not as evidence.

---

## Top three to adopt (from the board)

1. **Assertion–evidence as the default content slide.** A sentence headline of at most two lines stating the takeaway, supported by one visual exhibit instead of bullets. Strongest evidence on the board: Alley's study found audiences seeing sentence-headline-plus-evidence slides understood and remembered content better than topic-plus-bullets slides, significant at p < .01. Tradeoff: sentence titles run long, so slide-title size drops to roughly h3/h4 on the golden-ratio scale rather than sitting at label-title size. [Penn State](https://writing.engr.psu.edu/research.html) · [ResearchGate](https://www.researchgate.net/publication/286042632_How_the_Design_of_Presentation_Slides_Affects_Audience_Comprehension_A_Case_for_the_Assertion-Evidence_Approach)
2. **Title-only outline export.** The consulting "horizontal logic" check: read in sequence, slide titles should form the deck's complete argument. Cheap in Typst — a query over the heading tree — and doubles as the agenda slide. [Slide Science](https://slidescience.co/action-titles/) *(McKinsey-style pattern site — vendor SEO content, unverified; used only for this widely repeated pattern)*
3. **Dark projection switch.** Butterick: in dimmed rooms, white slides projected at scale become giant white rectangles that cost reader attention; he recommends dark background / pale grey text there, off-white / dark grey in lit rooms. Proxima is already dark-first, so `projection: "dark"` reuses its tokens without abandoning Centauri's light-first default. [Butterick's Practical Typography](https://practicaltypography.com/presentations.html)

Also adopted from Butterick: pick a base size that fits 12–15 lines and hold it constant across slides — no auto-fit; no centred text; a measure narrower than full 16:9 width, so 4:3 and 16:9 can share one text column with different outer margins.

---

## Principles

- **One message per slide, readable in ~3 seconds.** Duarte's Glance Test. A message title instead of a label title is the fastest fix.
- **Remove what doesn't prove the point.** Mayer's coherence principle held across 23 experiments. Basis for: no decorative icons, no stock imagery, no background textures.
- **Don't put narration on screen.** Mayer's redundancy principle — graphics + narration beats graphics + narration + the same words as text. Speaker notes carry the script; slides carry exhibits.
- **Put labels next to what they label.** Spatial contiguity outperforms separate legends. Direct-label charts.
- **Signal structure, don't decorate it.** Section dividers and the outline slide are the signalling layer — keep them functional, not ornamental.
- **Sentences over fragments where reasoning matters.** Tufte's critique: bullet hierarchies hide causal relationships. Where a slide explains a mechanism, prefer one or two full sentences over three bullets.
- **Minimal chrome.** Metropolis's stated aim — minimum noise, maximum content area. Strip navigation bars and heavy block elements; keep only frame title, frame number, content.

---

## Slide archetypes for Centauri

**As built.** Each archetype maps to one function; see `reference.md` for arguments.

| Archetype | Function | Content | Notes |
|---|---|---|---|
| `cover` | `title-slide` | Title, subtitle, fact chips, optional large numeral | Per-slide accent override. No logo wall; logos, when given, sit in the frame corners. |
| `section` | `section-slide` | Section title and subtitle | Accent ground. `Section n of m` and up to four preview cards listing the section's slides stand in for a progress bar. |
| `outline` | `outline-slide` | One tile per section with its slide count | Same source as the title-only export. |
| `claim` (default) | `claim`, alias `slide` | Sentence title plus one exhibit | Assertion–evidence. Source line at the bottom left. |
| `statement` | `statement` | One short phrase at h1 size | Takahashi method — large text, few words, many slides. Pacing tool, not evidence. |
| `quote` | `quote-slide` | Quotation plus attribution | Newsreader — the one sanctioned serif use on slides. |
| `compare` | `compare` | Two columns, before/after or A/B | Shared baseline for both columns; `pick` marks the favoured option. |
| `exhibit` | `exhibit` | Chart or diagram, no chart title | Slide title carries the interpretation; the chart shows only data. |
| `table` | `table-slide` | Grid of numbers or text | Tabular lining figures, right-aligned numerals by default, `align: left` for text, no vertical rules. |
| `code` | `code-slide` | Listing, ≤15 lines | Mono face, highlighted lines on a band, no line numbers. |
| `steps` | `steps-slide` | Numbered sequence | One step may be emphasised with `current`. |
| `exercise` | `exercise` | Task, time box, expected output | Training-specific; takes a second accent automatically. |
| `appendix` | `appendix` | Dense evidence | Smaller body size permitted — main deck is the argument, appendix is the evidence library. |
| `close` | `close` | Next actions, contact | Not "Questions?" or "Thank you." |

Added during the build, outside the original board: `explain` (terms defined in rows), `split` (accent panel plus tiles), `display-slide` (one word at column width), and the helpers `stats`, `metric`, `tile`, `columns-chart`, `bars-chart`, `cols`, `hl`, `notes`.

---

## Typography

- One body size across all slides (Butterick) — fit 12–15 lines, hold it constant.
- No auto-shrink: change the text to fit the size, not the size to fit the text. Overflow should produce a visible warning or failed build.
- Left-aligned, ragged right — no centred paragraphs or headlines (Swiss grid tradition).
- Sentence case for titles.
- Measure narrower than full 16:9 width, consistent across aspect ratios.
- Light body weight acceptable on dark projection; regular on light — thin type needs more luminance on dark backgrounds.

## Colour

- Off-white background, dark grey text — not pure white/black (Butterick; Metropolis also tones background down for eye strain).
- One accent per deck from the four Proxima accents, used for highlights only, the way Metropolis uses its alert colour. Neutrals carry structure.
- Charts: greys for context series, accent for the series the title talks about.

## Chrome

As proposed:

- Frame number bottom-right. Source line bottom-left, small, on every data slide.
- Nothing in the header centre (existing rule). No logo on every slide.
- Optional progress indicator, section slides only.

**As built.** An editorial frame of two hairlines. Above the top line: series label, current section title (centre), date. Below the foot line: slide count (`03 / 21`) on the left, presenter on the right. The section title in the top centre departs from the "nothing in the header centre" rule, which is kept for documents; on slides it replaces the progress indicator. Logos are optional and take the top corners. The source line sits at the bottom left of the content area.

## Data

- Maximize data-ink (Tufte, via Metropolis's chart styles): no boxes, no gridline clutter, no 3D.
- Direct labels on lines and bars.
- One exhibit per slide — a second exhibit means a second slide.

## Output modes

**As built.**

- `aspect: "16:9" | "4:3"` — text column of 24cm on 16:9, the full 21.6cm between margins on 4:3.
- `projection: "light" | "dark"` — dark pulls Proxima tokens.
- `--input mode=handout` — A4 pages with each slide and its speaker notes, in the spirit of Duarte's slidedocs.
- `--input mode=titles` — the title-only export, for the ghost-deck review.
- `--input notes=true` — speaker notes printed on the slides.
- Speaker notes in pdfpc-compatible form — not built. Touying exports these and remains the reference if it is taken up.

## Build process worth encoding

- **Ghost deck first.** Every slide title before any content; review the title sequence; then fill exhibits. The title-only export supports this directly.
- **One minute per slide** — commonly cited consulting pacing, unverified, but a usable check for training decks.

## Anti-patterns to exclude

Topic-label titles ("Market overview"); bullets as the default body; auto-fit text; centred paragraphs; navigation bars and dot trails (stock Beamer chrome); gradients and textured backgrounds; decorative icons; logo walls; eyebrow labels; a closing "Questions?" slide; a chart with its own title restating the slide title.

---

## Secondary patterns (unverified — reconcile before adopting)

From the 15-system pattern analysis. Several sit in tension with fixed Centauri decisions or the board's anti-patterns above; flagged inline.

| Pattern | Idea | Tension with the board |
|---|---|---|
| Context-dimmed code blocks | Monospace code in neutral greys, accent highlights only the line being discussed | Compatible — matches `code` archetype's line-highlight rule. |
| Persistent monolithic breadcrumbs | Small monospace trail (`03 / Authentication / OAuth`) top-left, updates per slide | Sits in the top-left margin, not header centre, so it doesn't violate the "nothing in header centre" rule — but it's a form of running head / structural label the board doesn't otherwise use. Overlaps with `outline`/progress-indicator intent; likely redundant with it. |
| Inverted section dividers | Section slides flip to a stark inverted canvas, accent as the primary text colour, large centered title | Conflicts with "no centred text" and with light-first-by-default; closer in spirit to the dark projection variant than to a standalone pattern. |
| Asymmetric two-column grids | 1:3 ratio, static title column + active content column | Conflicts with assertion-evidence's single sentence-title-plus-exhibit layout as the default `claim` archetype. Could work for `compare`. |
| Geometric primitive diagrams | Architecture shown via basic shapes filled in the accent colour | Compatible with "maximize data-ink" / no stock imagery, no decorative icons. |
| Oversized typographic metrics | Standalone numbers set very large in a geometric sans | Overlaps with `statement` archetype; font choice (Inter/Roboto) conflicts with Centauri's fixed Source Sans 3. |
| Edge-anchored accent borders for quotes | Oversized quote text, no quotation marks, thick accent rule on the left edge instead | Direct alternative to the `quote` archetype's serif treatment. **As built:** combined — `quote-slide` and `statement` set their text beside a thick, round-ended accent line (the emphasis line), and quotations keep the serif. |
| Progressive disclosure via opacity | Future bullet points at 30% opacity, current/past at 100% | Conflicts with "no auto-fit... slides should be static" framing and with removing bullets as the default body; may be acceptable narrowly for `steps`. |
| Monospace kicker headings | Small monospace kicker (`// SESSION 04`) above a bold title on cover slides | Directly conflicts with the fixed Centauri decision: "no eyebrow labels." |
| Terminal-style concept boxes | Rounded box, muted background, accent top border, mimics a CLI frame | No direct conflict, but adds a chrome element the board's "minimal chrome" principle would need to approve explicitly. |

**Read:** roughly two of ten (code blocks, geometric diagrams) merge cleanly; one (kicker headings) is a flat contradiction of an existing decision; the rest either duplicate a board archetype under a different name or need a specific tradeoff decision before adoption.

---

## Licence flag

Metropolis is CC BY-SA 4.0 with share-alike on redistribution — read for ideas only, no code into MIT-licensed Centauri. [CTAN](https://ctan.org/tex-archive/macros/latex/contrib/beamer-contrib/themes/metropolis)

## Decisions

Resolved in 0.2.0:

- **Default slide:** sentence titles. `claim` is the default content slide, and `slide` is an alias for it. The build rejects a title that ends with a full stop.
- **Dark projection:** shipped in 0.2.0 alongside light.
- **Progress indicator:** not built as a bar. Section slides print `Section n of m` with preview cards, and the frame carries the section title on every content slide.
- **Secondary patterns:** context-dimmed code (line highlighting) and the edge-anchored accent line (the emphasis line on statements and quotations) are adopted. Kicker headings are rejected (no eyebrow labels). The rest are not adopted.

Open:

- pdfpc-compatible speaker notes export.
- Whether `steps-slide` gains progressive disclosure across builds.

## Reference library

Evidence and method:
- Michael Alley, assertion–evidence research: https://writing.engr.psu.edu/research.html
- Alley study (ResearchGate): https://www.researchgate.net/publication/286042632_How_the_Design_of_Presentation_Slides_Affects_Audience_Comprehension_A_Case_for_the_Assertion-Evidence_Approach
- Mayer and Fiorella, extraneous-processing principles (PDF): https://edtechuvic.ca/wp-content/uploads/sites/11/2022/09/principles-for-reducing-extraneous-processing-in-multimedia-learning-coherence-signaling-redundancy-spatial-contiguity-and-temporal-contiguity-principles.pdf
- Duarte, Glance Test: https://www.duarte.com/resources/guides-tools/the-glance-test/
- Tufte, The Cognitive Style of PowerPoint: https://archive.org/details/cognitivestyleof0000tuft

Typography and themes:
- Butterick, Presentations: https://practicaltypography.com/presentations.html
- Metropolis design rationale: https://matze.bloerg.net/posts/a-modern-beamer-theme/
- Metropolis source (CC BY-SA 4.0): https://github.com/matze/mtheme
- Touying (Typst slides; themes, speaker notes, pdfpc): https://github.com/touying-typ/touying

Pace and rhythm:
- Takahashi method: https://en.wikipedia.org/wiki/Takahashi_method
- Action-title pattern (unverified, vendor SEO): https://slidescience.co/action-titles/

Galleries (visual browsing; SEO-heavy, quality varies):
- Figma, 100+ funded pitch decks: https://www.figma.com/community/file/1472313491885789708/100-pitch-decks-that-raised-funds
- bestpitchdeck archive: https://bestpitchdeck.com/figma
- Swiss grid generator (layout study tool): https://github.com/longplay45/swiss-grid-generator

## API

The archetype table is implemented. Function signatures, arguments and build rules are in [`reference.md`](reference.md).

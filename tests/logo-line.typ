#import "/lib.typ": *
// Page 1: an image; page 2: a box with text. Both start at 1.2cm, are capped at 0.8cm and must be
// centred on the line's cap-height midline; tests/centre.py measures it.
#set page(width: 10cm, height: 3cm, margin: 0.5cm)
#set text(font: "Atkinson Hyperlegible Next", size: 14pt)
#let red = rgb("#ff0000")
#let img = image(bytes("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 40 24'><rect width='40' height='24' fill='#ff0000'/></svg>"), format: "svg", height: 1.2cm)
#align(horizon, logo-line(height: 0.8cm)[Prepared for #img Client])
#pagebreak()
#align(horizon, logo-line(height: 0.8cm)[Prepared for #box(fill: red, inset: 0.3cm, text(fill: red)[H]) Client])

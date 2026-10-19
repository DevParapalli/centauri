// Fixture for the PDF helpers in checks.py. Page 1: a cover with Centauri's bloom (a radial
// gradient). Page 2: a link in the theme's link colour, its hex printed beside it, and an SVG
// drawn at 40% opacity. Page 3: a cover with an image as its backdrop.
#import "/lib.typ": *
#show: centauri.with(stage: "review")
#cover(tone: "dark", title: [Bloom])
#link("https://example.com")[Example] LINK-HEX-#context theme-now().colors.link.to-hex()
#image(bytes("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10 10' opacity='0.4'><rect width='10' height='10' fill='#000'/></svg>"), format: "svg", width: 1cm)
#cover(title: [Image], backdrop: image(bytes("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 4 4'><image width='4' height='4' href='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='/></svg>"), format: "svg", width: 2cm))

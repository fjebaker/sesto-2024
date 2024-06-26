#import "@preview/polylux:0.3.1": *
#import "tamburlaine.typ": *

#enable-handout-mode(false)

#show: tamburlaine-theme.with(aspect-ratio: "4-3")
#show link: item => underline(text(blue)[#item])

#let uob_logo = read("./figs/UoB_CMYK_24.svg")

#title-slide(
  title_size: 30pt,
  title: [
    Advancements in the theory and practice of
    #move(dy: -0.5em, text(size: 120pt, stack(spacing: 20pt, move(dx: -30pt, "Spectral"), "Variability", "Modelling")))
  ],
  authors: ([Fergus Baker#super("1")], text(weight: "regular", [Andrew Young#super("1")])),
  where: "Sesto",
)[
  #align(right)[#image.decode(uob_logo, width: 20%)]
]

#slide[
  Hello World
]

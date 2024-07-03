#import "@preview/polylux:0.3.1": *
#import "tamburlaine.typ": *

#let HANDOUT_MODE = false
#enable-handout-mode(HANDOUT_MODE)

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


#let im_lamppost = read("figs/lamp-post.traces-export.svg")

// part 1: slide 1
#slide(title: "The lamp post model")[
  A single point-like, axis-symmetric source
  - Geometry depends only on height $h$
  #align(center)[
    #animsvg(
      im_lamppost,
      (i, im) => only(i)[
        #image.decode(im, width: 60%)
      ],
      (),
      (hide: ("g75", "g49")),
      (hide: ("g1",)),
      (display: ("g5",)),
      (hide: ("g6", "g2"), display: ("g7",)),
      (display: ("g73", "g72", "g4")),
      (display: ("path63", "g3")),
      handout: HANDOUT_MODE,
    )
  ]
  // - diagrammatic overview
  // - show the different paths that light can take
]

#slide(title: "The lamp post model")[
  How we use it to model reverberation lags:
  - how we bin a 2D response function showing arrival time as a function of energy
  - how this can be convolved with the reflection spectrum or used as the Green's function (impulse response) for the coronal spectrum
    - take energy bands, calculate cross spectrum, etc.
  - e.g. pivoting power law $e^(Gamma (t))$
]

#slide(title: "Practical approaches")[
  - binning is slow so we need a better way to calculate the 2D transfer functions
  - In time averaged spectroscopy, there are Cunningham transfer functions
    - Re-parameterize the image plane into coordinates on the disc
    - Useful for modelling and sparse
  - For variability? We make them time dependent and solve a 2D integral instead
]

#slide(title: "The lamp post model")[
  - Physical complexities in modelling
  - Different things to take into account for self-consistent modelling
    - Full reflection spectrum on the disc
    - Mastroserio: ionization parameter
    - Instrument response
  - For brevity, ignore those effects today
]

// part 2: slide 4
#slide(title: "Moving out from under the lamp post")[
  - Joke about person searching for keys under the lamp post
    - "Is this the variability you were looking for?" No but the light is much better here
  Extended geometry in reverberation modelling largely under explored
  - Two lamp post model (Chainakun and Young)
  - Extended sources (Wilkins)
]

#slide(title: "Extended coronal models")[
  - Still assume axis symmetry
  - Diagrammatic overview
  - Show decomposition of corona into volumes
  - Reason how we can treat each annulus as an off axis point and weight it
]

#slide(title: "Challenges with extended models")[
  - Time dependent emissivity functions
    - shape of emissivity functions changes dramatically
  - Not all regions of the corona will flash together (travel time)
  - Not all regions of the corona will have the same power law index
  - Continuum transfer function over a face of the corona
]

#slide(title: "Illustrative results")[
  - show the effects of changing some of these parameters
]

// part 3: slide

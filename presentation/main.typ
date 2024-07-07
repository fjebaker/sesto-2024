#import "@preview/polylux:0.3.1": *
#import "tamburlaine.typ": *

#let HANDOUT_MODE = false
#enable-handout-mode(HANDOUT_MODE)

#show: tamburlaine-theme.with(aspect-ratio: "4-3")
#show link: item => underline(text(blue)[#item])

#let COLOR_CD = color.rgb("#56B4E9")
#let COLOR_REFL = color.rgb("#D55E00")
#let COLOR_CONT = color.rgb("#0072B2")

#set par(spacing: 0.7em)

#let uob_logo = read("./figs/UoB_CMYK_24.svg")

#title-slide(
  title_size: 30pt,
  title: [
    Advancements in the theory and practice of
    #move(
      dy: -0.3em,
      text(
        size: 120pt,
        stack(
          spacing: 20pt,
          move(dx: -30pt, "Spectral"),
          "Variability",
          "Modelling"
        )
      )
    )
    #v(0.5em)
  ],
  authors: ([Fergus Baker#super("1")], text(weight: "regular", [Andrew Young#super("1")])),
  where: "Sesto",
)[
  #align(right)[#image.decode(uob_logo, width: 20%)]
]

// ==== Part 1 ============================================================= //

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

#slide(title: "The corona changes the emissivity of the disc")[
  *Flux* into the disc changes as a function of *radius*:

  // TODO: figures showing how number of photons changes per radial bin
  // with different coronal heights
  // also show how the arrival time on each patch of the disc changes

  Observed *steep emissivity profile* motivates the lamp post corona (Fabian et al. 2004).
]

#let cbox(content, ..args) = rect(radius: 3pt, outset: 5pt, ..args, content)

#slide(title: "The observer changes how the disc is seen")[
  #set text(size: 20pt)
  Trace *observer to disc* and bin by relative *redshift* $g$ and *total arrival time* $t_"tot" = #cbox(stroke:COLOR_CD, $t_("corona" -> "disc")$) + #cbox(stroke: COLOR_REFL, $t_("disc" -> "observer")$)$

  #grid(
    columns: (33%, 33%, 1fr),
    column-gutter: 0pt,
    [
      #image("./figs/apparent-image.png", width: 100%)
    ],
    [
      #image("./figs/apparent-image-arrival.png", width: 100%)
    ],
    [
      #move(dx: -0.5em, image("./figs/apparent-image-transfer.png", width: 94%))
    ]
  )

  // TODO: small figure showing the traces we are considering, arrival time of
  // a given radius to the observer, and an example of the 2D transfer function
  // maybe with the redshift equation
  //   show a ray traced image of the black hole, explain that we bin it all together

  - Light bending effects *distorts* the spectrum $g_"obs"$ and arrival time $t_"tot"$ depending on $theta_"observer"$.
]

#slide(title: "Calculating lags")[
  #set text(size: 23pt)
  The *2D transfer functions* are effectively *Green's functions*, that can be *convolved* with other processes:

  #grid(columns: (50%, 1fr),
  [
    #set text(size: 18pt)
  - *Reflection spectrum* (Xillver, Reflionx)
  - Coronal spectrum variability (Mastroserio et al. 2018, 2021)
    - Subtle complexity: *changes in coronal spectrum* propagate through to *changes in emissivity*
    - Skip considering these today for brevity
    #image("figs/lag-frequency.svg")
  ],
  [
    #image("figs/reflection.convolution.png", width: 98%)
  ]
  )
]

#slide(title: "Practicality")[
  Binning 2D transfer functions is slow ($tilde 10$s of seconds)
  #set text(size: 24pt)
  - Spectroscopy: use *Cunningham transfer functions* (CTF)
    - Re-parameterize image plane into coordinates on the disc $(alpha, beta) arrow.r (r_"em", g^star)$
    - Can be efficiently *pre-computed* and *integrated* (e.g. Dauser et al. 2010 `relline/relconv`).

    // TODO: figure showing some transfer functions and the reparameterization,
    // along with maybe some of the time dependence

  #cbox(fill: PRIMARY_COLOR, width: 100%, text(fill: SECONDARY_COLOR)[
    For variability: make *CTF time dependent*, solve a 2D integral instead (*fast*, $tilde 1$ ms).
  ])
]

// ==== Part 2 ============================================================= //

#slide(title: "Moving out from under the lamp post")[
  // - Joke about person searching for keys under the lamp post
  //   - "Is this the variability you were looking for?" No but the light is much better here
  Extended geometry in reverberation modelling largely under explored
  - Often phenomenologically invoked
  - *Two lamp post* model (e.g. Chainakun & Young 2017, Lucchini et al. 2023)
  - Continuous *extended sources* (Wilkins et al. 2016)

  // TODO: include some figures from those papers to show how they approach things

  Motivation to study extended sources in detail to explore what is possible.
]

#slide(title: "Extended coronal models")[
  Assume *axis-symmetric* for computational simplicity.
  #set text(size: 20pt)
  #grid(columns: (50%, 1fr),
    [
    Decomposition:
     - Slice any volume into discs with height $delta h$.
     - Each disc can be split into annuli $(x, x + delta x)$.
     - Weight contribution of each annulus by its volume.
    ],
    [
      #align(center,
        image("./figs/decomposition.svg", width: 88%)
      )
    ]
  )

  #cbox(fill: PRIMARY_COLOR, width: 100%, text(fill: SECONDARY_COLOR)[
    Each ring *modelled by a single point source*. Totals are weighted sums: e.g. emissivity
    $
     epsilon_"tot" (rho, t) = integral_0^R V(x) epsilon_x (rho, t) dif x,
    $
    where $V(x)$ is the volume of the annulus in $(x, x + dif x)$.
  ])
]

#let im_extendpost = read("figs/extended.traces-export.svg")

#slide(title: "An extended picture")[
  As suggested in the last slide, *emissivity* is now *time dependent*. Why? Consider 2D slice of one annulus:
  #place(move(dy: 0.5em, dx: 2em, uncover("3-", block(width: 58%, text(size: 18pt)[
    Sweep 2D plane around the axis to find a geodesic that hits each $phi.alt$. Plotted is the arrival time $t_("corona" -> "disc")$.
  ]))))
  #place(move(dy: 4em, dx: 2.5em, uncover(4, block(width: 50%, text(size: 18pt)[
    Axis symmetry: can treat a single point as a ring up to normalisation.
  ]))))
  #align(center)[
    #animsvg(
      im_extendpost,
      (i, im) => only(i)[
        #image.decode(im, width: 70%)
      ],
      (),
      (hide: ("g126",), display: ("g142",)),
      (display: ("g143", "g133")),
      (),
      handout: HANDOUT_MODE,
    )
  ]
]

#slide(title: "Time-dependent emissivity functions")[
  #align(center,
    image("./figs/ring-corona.transfer-functions.png", width: 80%)
  )
  #set text(size: 20pt)
  *Left*: Kerr spacetime ($a=0.998$). #h(1fr) *Right*: Flat spacetime. \
  The purple-orange surface is for a ring at $rho=11 r_"g"$, whereas the green-pink surface is $rho = 5 r_"g"$ (both at $h = 5 r_"g"$, colour scale is $log_(10)$).
]

#slide(title: "Additional challenges")[
  #set text(size: 20pt)
  Propagating *source* fluctuations: each region of the corona
  #grid(
    columns: (60%, 1fr),
    [
      - may "flash" at different times,
      - may have different spectrum.
      \
      Continuum *arrival time* $t_("corona" -> "observer")$ and *observed spectrum* are blurred:
    ],
    [
      #move(dy: -0.3em, dx: 1em,
        image("./figs/propagation.svg", width: 65%)
      )
    ]
  )
  #v(-1em)
  #align(center,
    image("./figs/continuum.transfer-function.png", width: 70%)
  )
  #text(size: 18pt)[
    *Left*: co-rotating with disc. #h(1fr) *Right*: constant angular velocity. \
    Both have $rho_"max" = 20 r_"g"$, $h = 5 r_"g"$ and $theta_"obs" = 45 degree$.
  ]
]

#slide(title: [Illustrative #super(text(size: 20pt, weight: "regular", "(preliminary)")) results])[
  // - show the effects of changing some of these parameters
]

#slide(title: "Future work")[
  // how the reflection spectrum changes along the radius of the disc
  // model coronal spectrum fully
  // vertically extended sources
  // package for fitting programs other than SpectralFitting.jl
]

// TODO: thank you slide with references and links
#slide(background: PRIMARY_COLOR, foreground: SECONDARY_COLOR)[
  #align(right, text(fill: SECONDARY_COLOR, size: 50pt, weight: "black", "Thank you"))

  #rect(fill: SECONDARY_COLOR, inset: (top: 1em, bottom: 1em), outset: (left: 1em, right: 1em), width: 100%)[
    #set text(size: 20pt)
    #grid(
      columns: (20%, 1fr),
      row-gutter: 0.7em,
      [Gradus.jl:],
      link("https://github.com/astro-group-bristol/Gradus.jl"),
      [Contact:],
      link("fergus.baker@bristol.ac.uk"),
    )
  ]
]

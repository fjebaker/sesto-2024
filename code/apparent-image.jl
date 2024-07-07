include("common.jl")

m = KerrMetric(M=1.0, a=0.998)
x = SVector(0.0, 10_000.0, deg2rad(80), 0.0)
x2 = SVector(0.0, 10_000.0, deg2rad(40), 0.0)
d = ThinDisc(0.0, 30.0)

# CHANGE HERE TO CHANGE FROM REDSHIFT TO ARRIVAL TIME
pf = ConstPointFunctions.redshift(m, x) ∘ ConstPointFunctions.filter_intersected()
pf = PointFunction((m, gp, t) -> gp.x[1]) ∘ ConstPointFunctions.filter_intersected()

α, β, img = rendergeodesics(
    m,
    x,
    d,
    20000.0,
    αlims = (-38, 38), 
    βlims = (-16, 18),
    image_width = 800,
    image_height = 400,
    ensemble = Gradus.EnsembleEndpointThreads(),
    verbose = true,
    pf = pf,
)

α2, β2, img2 = rendergeodesics(
    m,
    x2,
    d,
    20000.0,
    αlims = (-38, 38), 
    βlims = (-33, 33),
    image_width = 800,
    image_height = 400,
    ensemble = Gradus.EnsembleEndpointThreads(),
    verbose = true,
    pf = pf,
)

begin
    iimg1 = img .- minimum(filter(!isnan, img))
    iimg2 = img2 .- minimum(filter(!isnan, img2))

    iimg1 = iimg1 ./ maximum(filter(!isnan, iimg1))
    iimg2 = iimg2 ./ maximum(filter(!isnan, iimg2))
end

begin
    fig = Figure(size = (400, 450),
        backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0)
    )
    ga = fig[1,1] = GridLayout()

    ax = Axis(
        ga[1,1],
        aspect = DataAspect(),
        title = "θ = 80",
        ylabel = "β",
        backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0)

    )
    ax2 = Axis(
        ga[2,1],
        aspect = DataAspect(),
        xlabel = "α",
        ylabel = "β",
        title = "θ = 40",
        backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0)
    )
    
    hidexdecorations!(ax, grid = false)

    cr = (0.2, 0.6)
    cm = heatmap!(ax, α, β, iimg1', colormap = :batlow, colorrange = cr)
    heatmap!(ax2, α2, β2, iimg2', colormap = :batlow, colorrange = cr)
    cb = Colorbar(ga[1:2,2], cm, ticks = ([0.25, 0.55], ["Arrives\nearlier","Arrives\nlater"]), height = 310)
    
    rowsize!(ga, 1, Auto(0.47))
    rowgap!(ga, 5)
    linkxaxes!(ax, ax2)

    Makie.save("presentation/figs/_raw/apparent-image-arrival.png", fig)
    fig
end



function flux_profile(m, x, d, model, radii, gbins, tbins; n_samples = 3000)
    itb = @time Gradus.interpolated_transfer_branches(m, x, d, radii; verbose = true)
    prof = @time emissivity_profile(m, d, model; n_samples = n_samples)
    flux = Gradus.integrate_lagtransfer(
        prof, 
        itb, 
        gbins, 
        tbins; 
        t0 = Gradus.continuum_time(m, x, model),
        n_radii = 4000,
        rmin = minimum(radii),
        rmax = maximum(radii),
    )
    replace!(flux, 0.0 => NaN)
end

d = ThinDisc(0.0, Inf)
radii = Gradus.Grids._inverse_grid(Gradus.isco(m), 800.0, 200)

gbins = collect(range(0.0, 1.6, 500))
tbins = collect(range(0, 160.0, 800))
model = LampPostModel(h = 5.0)

ff1 = flux_profile(m, x, ThinDisc(0.0, Inf), model, radii, gbins, tbins)
ff2 = flux_profile(m, x2, ThinDisc(0.0, Inf), model, radii, gbins, tbins)

begin
    fig = Figure(size = (400, 450),
        backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0)
    )
    ax = Axis(
        fig[1,1],
        ylabel = "E / E₀",
        xlabel = "Time after continuum (GM / c³)",
        yticks = [0.2, 0.6, 1.0, 1.4],
        xticks = [0, 25, 50, 75, 100],
        title = "2D Transfer Function",
        backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0)
    )
    
    xlims!(ax, nothing, 100)
    heatmap!(ax, tbins, gbins, log10.(ff1)', colormap = :greys)
    heatmap!(ax, tbins, gbins, log10.(ff2)', colormap = :batlow)
    
    Legend(
        fig[1,1],
        tellheight = false,
        tellwidth = false,
        halign = 0.9,
        valign = 0.1,
        backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0),
        [
            PolyElement(color = :grey),
            PolyElement(color = "#DF964F"),
        ],
        ["θ = 80°", "θ = 40°"]
    )

    Makie.save("presentation/figs/_raw/apparent-image-transfer.png", fig)
    fig
end
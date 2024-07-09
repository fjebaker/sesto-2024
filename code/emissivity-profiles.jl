include("common.jl")

m = KerrMetric(1.0, 0.998)
m2 = KerrMetric(1.0, 0.0)
d = ThinDisc(0.0, Inf)

heights = [3.0, 5.0, 10.0]

emprofs = map(heights) do h
    model = LampPostModel(h = h)
    emprof = emissivity_profile(m, d, model; n_samples = 2000)
end

emprofs2 = map(heights) do h
    model = LampPostModel(h = h)
    emprof = emissivity_profile(m2, d, model; n_samples = 2000)
end

begin
    _norm = 1e4
    scales = [13.0, 3.2, 1.0]
    fig = Figure(size = (700, 400), backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0))

    ax = Axis(
        fig[2, 1],
        yscale = log10,
        xscale = log10,
        xticks = [1.0, 2.0, 3.0, 5.0, 10.0, 20.0, 30.0, 50.0, 100.0],
        xlabel = "Radius on disc",
        ylabel = "Emissivity (arb.)",
        backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0),
    )
    ax2 = Axis(
        fig[2, 2],
        yscale = log10,
        xscale = log10,
        xticks = [1.0, 2.0, 3.0, 5.0, 10.0, 20.0, 30.0, 50.0, 100.0],
        yticks = [5.0, 10.0, 20.0, 50.0, 100.0],
        xlabel = "Radius on disc",
        ylabel = "Time corona-to-disc",
        backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0),
    )

    dat = []
    palette = _default_palette()
    for (A, ep) in zip(scales, emprofs2)
        lines!(
            ax,
            ep.radii,
            A .* ep.ε ./ _norm,
            linestyle = :dash,
            color = popfirst!(palette),
        )
    end
    palette = _default_palette()
    for (A, ep) in zip(scales, emprofs)
        push!(dat, lines!(ax, ep.radii, A .* ep.ε ./ _norm, color = popfirst!(palette)))
    end

    palette = _default_palette()
    for (A, ep) in zip(scales, emprofs2)
        lines!(ax2, ep.radii, ep.t, linestyle = :dash, color = popfirst!(palette))
    end
    palette = _default_palette()
    for (A, ep) in zip(scales, emprofs)
        lines!(ax2, ep.radii, ep.t, color = popfirst!(palette))
    end

    Legend(
        fig[1, 1:2],
        dat,
        ["h = $(trunc(Int,i))" for i in heights],
        orientation = :horizontal,
        framewidth = 0,
        backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0),
    )

    xlims!(ax, 1.0, 100.0)
    ylims!(ax, 1e-4 / _norm, nothing)
    xlims!(ax2, 1.0, 100.0)
    ylims!(ax2, 5, 200.0)

    vlines!(ax, [Gradus.inner_radius(m), Gradus.inner_radius(m2)])
    vlines!(ax2, [Gradus.inner_radius(m), Gradus.inner_radius(m2)])

    Makie.save("presentation/figs/_raw/emissivity-and-time.svg", fig)
    fig
end

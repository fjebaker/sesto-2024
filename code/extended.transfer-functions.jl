include("common.jl")

function Gradus.continuum_time(m::AbstractMetric, x, model::DiscCorona)
    radii = range(0.9, model.r, 60) |> collect
    itb1 = @time Gradus.interpolated_transfer_branches(
        m,
        x,
        DatumPlane(model.h),
        radii;
        verbose = true,
        β₀ = 7.0,
    )
    all_times = Float64[]
    for branch in itb1.branches
        append!(all_times, branch.lower_t.u, branch.upper_t.u)
    end
    sum(all_times) / length(all_times)
end

function _do_integration(x, itb, gbins, tbins, prof)
    flux = @time Gradus.integrate_lagtransfer(
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

function flux_profile(m, x, d, model, itb, gbins, tbins; n_samples = 10_000, kwargs...)
    prof = @time emissivity_profile(m, d, model; n_samples = n_samples, kwargs...)
    _do_integration(x, itb, gbins, tbins, prof)
end

m = KerrMetric(1.0, 0.998)
x = SVector(0.0, 10000.0, deg2rad(45), 0.0)

# currently needs an infinite disc for the root finder (patch coming soon)
d = ThinDisc(0.0, Inf)
radii = Gradus.Grids._geometric_grid(Gradus.isco(m), 1000.0, 300)
itb = @time Gradus.interpolated_transfer_branches(m, x, d, radii; verbose = true)

model = DiscCorona(30.0, 10.0)

prof = @time emissivity_profile(m, d, model; n_samples = 600, n_rings = 20)

gbins = collect(range(0.0, 1.4, 1000))
tbins = collect(range(-20, 250.0, 1000))

flux2 = _do_integration(x, itb, gbins, tbins, prof)

begin
    lpflux = @time flux_profile(m, x, d, LampPostModel(h = model.h), itb, gbins, tbins)
    freq1, tau1 = @time Gradus.lag_frequency(tbins, lpflux)
    freq2, tau2 = @time Gradus.lag_frequency(tbins, flux2)
end

begin
    fig = Figure(size = (700, 300), backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0))
    ax = Axis(
        fig[1, 1],
        backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0),
        xlabel = "Time after continuum (GM/c³)",
        ylabel = "E / E₀",
        title = "Lamp post h=10.0",
    )
    ax2 = Axis(
        fig[1, 2],
        backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0),
        xlabel = "Time after continuum (GM/c³)",
        title = "Extended corona h=10, x=30",
    )
    p = heatmap!(ax, tbins, gbins, log10.(lpflux'), colormap = :batlow)
    p = heatmap!(ax2, tbins, gbins, log10.(flux2'), colormap = :batlow)
    hideydecorations!(ax2, grid = false)
    xlims!(ax, nothing, 150)
    xlims!(ax2, nothing, 150)
    ylims!(ax, nothing, 1.2)
    ylims!(ax2, nothing, 1.2)
    vlines!(ax, [0.0], color = :black, linestyle = :dash)
    vlines!(ax2, [0.0], color = :black, linestyle = :dash)

    Makie.save("presentation/figs/_raw/extended-transfer-comparison.png", fig)
    fig
end

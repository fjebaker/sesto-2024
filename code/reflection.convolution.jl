include("common.jl")

using DSP
using Reflionx
using SpectralFitting
using DataInterpolations

reftable = Reflionx.parse_run("data/reflionx/grid")
ref_spec = reftable.grids[4, 1, 3]

m = KerrMetric(1.0, 0.998)
x = SVector(0.0, 1000.0, deg2rad(45), 0.0)
d = ThinDisc(0.0, Inf)
model = LampPostModel(h = 5.0)
radii = Gradus.Grids._inverse_grid(Gradus.isco(m), 1000.0, 100)
itb = @time Gradus.interpolated_transfer_branches(m, x, d, radii; verbose = true)

# dispatches special methods for calculating the emissivity profile if available
prof = emissivity_profile(m, d, model; n_samples = 2000)

gbins = collect(range(0.0, 1.2, 800))
tbins = collect(range(0, 125.0, 500))

t0 = Gradus.continuum_time(m, x, model)

flux = Gradus.integrate_lagtransfer(
    prof,
    itb,
    gbins,
    tbins;
    t0 = t0,
    n_radii = 6000,
    rmin = minimum(radii),
    rmax = maximum(radii),
)

# upscale the grid we are interested in
interp = DataInterpolations.LinearInterpolation(ref_spec.flux, ref_spec.energy)

erange = collect(range(0.01, 10.1, 901))
values = interp.(erange)[1:end-1] ./ diff(erange)
erange = erange[1:end-1]

out = Gradus._threaded_map(eachcol(flux)) do col
    tmp = zeros(Float64, length(values) - 1)
    SpectralFitting.convolve!(tmp, values[1:end-1], erange, col[1:end-1], gbins)
    tmp
end

new_flux = map(i -> isapprox(i, 0, atol = 1e-8) ? 0 : i, reduce(hcat, out))

begin
    fig = Figure(size = (600, 600), backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0))
    ga = fig[1, 1] = GridLayout()

    ax1 = Axis(
        ga[1, 1],
        ylabel = "E / E₀",
        xlabel = "Time after continuum (GM/c³)",
        title = "2D Transfer Function",
        backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0),
    )
    ax2 = Axis(
        ga[1, 2],
        yscale = log10,
        xlabel = "Energy (keV)",
        ylabel = "Flux (arb.)",
        title = "Reflionx Reflection Spectrum",
        yaxisposition = :right,
        backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0),
    )
    ax3 = Axis(
        ga[2, 1:2],
        ylabel = "Energy (keV)",
        xlabel = "Time after continuum (GM/c³)",
        yticks = [0, 2, 4, 6, 8],
        backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0),
    )

    heatmap!(
        ax1,
        tbins,
        gbins,
        log10.(replace(flux', 0 => NaN)),
        colormap = Reverse(:matter),
    )
    heatmap!(
        ax3,
        tbins,
        erange,
        log10.(replace(new_flux', 0 => NaN)),
        colormap = Reverse(:matter),
    )

    ylims!(ax3, 0.0, 8.0)
    xlims!(ax2, 0.0, 8.0)

    lines!(ax2, erange, values)
    rowsize!(ga, 1, Auto(0.45))

    Makie.save("presentation/figs/_raw/reflection.convolution.png", fig)
    fig
end

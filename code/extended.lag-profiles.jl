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
        n_radii = 2000,
        rmin = minimum(radii),
        rmax = maximum(radii),
    )
    replace!(flux, 0.0 => NaN)
end

function flux_profile(m, x, d, model, itb, gbins, tbins; n_samples = 10_000, kwargs...)
    prof = @time emissivity_profile(m, d, model; n_samples = n_samples, kwargs...)
    _do_integration(x, itb, gbins, tbins, prof)
end

function lag_energy(data, flow, fhi)
    f_example = data[1][1]
    i1 = findfirst(>(flow), f_example)
    i2 = findfirst(>(fhi), f_example)
    map(data) do (_, tau)
        sum(tau[i1:i2]) / (i2 - i1)
    end
end

function lag_frequency_rowwise(t, f::AbstractMatrix; flo = 1e-5, kwargs...)
    f = f ./ maximum(sum(f, dims = 2))
    map(eachrow(f)) do ψ
        t_extended, ψ_extended = Gradus.extend_domain_with_zeros(t, ψ, 1 / flo)
        Gradus.lag_frequency(t_extended, ψ_extended; kwargs...)
    end
end

m = KerrMetric(1.0, 0.998)
x = SVector(0.0, 10000.0, deg2rad(45), 0.0)

# currently needs an infinite disc for the root finder (patch coming soon)
d = ThinDisc(0.0, Inf)
radii = Gradus.Grids._geometric_grid(Gradus.isco(m), 1000.0, 300)
itb = @time Gradus.interpolated_transfer_branches(m, x, d, radii; verbose = true)

model = DiscCorona(30.0, 10.0)

prof = @time emissivity_profile(m, d, model; n_samples = 600, n_rings = 20)

gbins = collect(range(0.0, 1.4, 1300))
tbins = collect(range(0.0, 2000.0, 3000))

flux2 = _do_integration(x, itb, gbins, tbins, prof)

begin
    lpflux = flux_profile(m, x, d, LampPostModel(h = model.h), itb, gbins, tbins)
    freq1, tau1 = @time Gradus.lag_frequency(tbins, lpflux)
    freq2, tau2 = @time Gradus.lag_frequency(tbins, flux2)
end

data = lag_frequency_rowwise(tbins, replace(flux2, NaN => 0))
lp_data = lag_frequency_rowwise(tbins, replace(lpflux, NaN => 0))

begin
    lims1 = (1e-3, 2e-3)
    lims2 = (4e-3, 8e-3)
    lims3 = (1.9e-2, 4e-2)
    lims4 = (1e-5, 1e-4)

    le1 = lag_energy(data, lims1...)
    le2 = lag_energy(data, lims2...)
    le3 = lag_energy(data, lims3...)
    le4 = lag_energy(data, lims4...)

    lp_le1 = lag_energy(lp_data, lims1...)
    lp_le2 = lag_energy(lp_data, lims2...)
    lp_le3 = lag_energy(lp_data, lims3...)
    lp_le4 = lag_energy(lp_data, lims4...)
end

begin
    fig = Figure(backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0))
    ga = fig[1, 1] = GridLayout()
    ax1 = Axis(
        ga[1, 1],
        backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0),
        xscale = log10,
        title = "Lag Frequency",
        ylabel = "Lag (GM/c³)",
    )
    ax2 = Axis(
        ga[2, 1],
        backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0),
        xscale = log10,
        ylabel = "Lag (GM/c³)",
        xlabel = "Phase Frequency",
    )
    ax3 = Axis(
        ga[1, 2],
        yaxisposition = :right,
        backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0),
        title = "Lag Energy",
        ylabel = "Lag (GM/c³)",
    )
    ax4 = Axis(
        ga[2, 2],
        yaxisposition = :right,
        backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0),
        ylabel = "Lag (GM/c³)",
        xlabel = "E / E₀",
    )

    palette = _default_palette()
    vspan!(
        ax1,
        [lims1[1], lims2[1], lims3[1], lims4[1]],
        [lims1[2], lims2[2], lims3[2], lims4[2]],
        color = [(popfirst!(palette), 0.4) for _ = 1:4],
    )
    palette = _default_palette()
    vspan!(
        ax2,
        [lims1[1], lims2[1], lims3[1], lims4[1]],
        [lims1[2], lims2[2], lims3[2], lims4[2]],
        color = [(popfirst!(palette), 0.4) for _ = 1:4],
    )

    palette = _default_palette()
    cl = popfirst!(palette)
    lines!(ax1, freq1, tau1, color = cl)
    xlims!(ax1, 5e-5, 2e-1)
    ylims!(ax1, -12, 40)

    lines!(ax2, freq2, tau2, color = cl)
    xlims!(ax2, 5e-5, 2e-1)
    ylims!(ax2, -12, 40)

    palette = _default_palette()

    for (le, lple) in zip((le1, le2, le3, le4), (lp_le1, lp_le2, lp_le3, lp_le4))
        color = popfirst!(palette)
        lines!(ax4, gbins, le, color = color)
        lines!(ax3, gbins, lple, color = color)
        # lines!(ax, gbins, lple, color = color, linestyle = :dot)
    end
    xlims!(ax3, 0.4, 1.2)
    xlims!(ax4, 0.4, 1.2)
    ylims!(ax3, -5, 80)
    ylims!(ax4, -5, 80)

    linkxaxes!(ax1, ax2)
    linkxaxes!(ax3, ax4)
    hidexdecorations!(ax1, grid = false)
    hidexdecorations!(ax3, grid = false)

    Makie.save("presentation/figs/_raw/extended-comparison.svg", fig)
    fig
end

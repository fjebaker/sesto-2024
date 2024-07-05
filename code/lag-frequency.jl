include("common.jl")

using Printf

function _format_model(model)
    hh = Printf.@sprintf "%.0f" model.h
    L"h = %$hh r_\text{g}"
end

function calculate_2d_transfer_function(m, x, model, itb, prof, radii)
    bins = collect(range(0.0, 1.5, 300))
    tbins = collect(range(0, 2000.0, 3000))

    t0 = continuum_time(m, x, model)
    @show t0

    flux = @time Gradus.integrate_lagtransfer(
        prof,
        itb,
        bins,
        tbins;
        t0 = t0,
        n_radii = 8000,
        h = 1e-8,
        g_grid_upscale = 10,
        rmin = minimum(radii),
        rmax = maximum(radii),
    )

    flux[flux.==0] .= NaN

    bins, tbins, flux
end

function calculate_lag_transfer(m, d, model, radii, itb)
    prof = @time emissivity_profile(m, d, model; n_samples = 100_000)
    E, t, f = @time calculate_2d_transfer_function(m, x, model, itb, prof, radii)
    ψ = Gradus.sum_impulse_response(f)
    freq, τ = @time Gradus.lag_frequency(t, f)
    freq, τ, ψ, t
end

m = KerrMetric(1.0, 0.998)
x = SVector(0.0, 10_000.0, deg2rad(45), 0.0)
radii = Gradus.Grids._inverse_grid(Gradus.isco(m), 1000.0, 200)

# models
model1 = LampPostModel(h = 2.0)
model2 = LampPostModel(h = 5.0)
model3 = LampPostModel(h = 10.0)
model4 = LampPostModel(h = 20.0)

# thin disc 
d = ThinDisc(0.0, Inf)

itb = Gradus.interpolated_transfer_branches(m, x, d, radii; verbose = true, β₀ = 2.0)

freq1, τ1, impulse1, time1 = calculate_lag_transfer(m, d, model1, radii, itb)
freq2, τ2, impulse2, time2 = calculate_lag_transfer(m, d, model2, radii, itb)
freq3, τ3, impulse3, time3 = calculate_lag_transfer(m, d, model3, radii, itb)
freq4, τ4, impulse4, time4 = calculate_lag_transfer(m, d, model4, radii, itb)

# thick disc
thick_d = ShakuraSunyaev(m)

thick_itb = Gradus.interpolated_transfer_branches(m, x, d, radii; verbose = true, β₀ = 2.0)

thick_freq1, thick_τ1, thick_impulse1, thick_time1 =
    calculate_lag_transfer(m, thick_d, model1, radii, thick_itb)
thick_freq2, thick_τ2, thick_impulse2, thick_time2 =
    calculate_lag_transfer(m, thick_d, model2, radii, thick_itb)
thick_freq3, thick_τ3, thick_impulse3, thick_time3 =
    calculate_lag_transfer(m, thick_d, model3, radii, thick_itb)
thick_freq4, thick_τ4, thick_impulse4, thick_time4 =
    calculate_lag_transfer(m, thick_d, model4, radii, thick_itb)

begin
    @show sum(filter(!isnan, impulse1))
    @show sum(filter(!isnan, impulse2))
    @show sum(filter(!isnan, impulse3))
    @show sum(filter(!isnan, impulse4))
end

begin
    palette = _default_palette()

    fig = Figure(resolution = (460, 300), backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0))
    ax = Axis(
        fig[1,1],
        xscale = log10,
        xminorgridvisible = true,
        xminorticks = IntervalsBetween(10),
        ylabel = "Lag (GM/c³)",
        xlabel = "Frequency (Hz)",
        backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0)
    )

    color = popfirst!(palette)
    l1 = lines!(ax, freq1, τ1, label = _format_model(model1), color = color)
    lines!(
        ax,
        thick_freq1,
        thick_τ1,
        label = _format_model(model1),
        linestyle = :dash,
        color = color,
    )

    color = popfirst!(palette)
    l2 = lines!(ax, freq2, τ2, label = _format_model(model2), color = color)
    lines!(
        ax,
        thick_freq2,
        thick_τ2,
        label = _format_model(model2),
        linestyle = :dash,
        color = color,
    )

    color = popfirst!(palette)
    l3 = lines!(ax, freq3, τ3, label = _format_model(model3), color = color)
    lines!(
        ax,
        thick_freq3,
        thick_τ3,
        label = _format_model(model3),
        linestyle = :dash,
        color = color,
    )

    color = popfirst!(palette)
    l4 = lines!(ax, freq4, τ4, label = _format_model(model4), color = color)
    lines!(
        ax,
        thick_freq4,
        thick_τ4,
        label = _format_model(model4),
        linestyle = :dash,
        color = color,
    )

    lines!(ax, [1e-5, 1], [0, 0], color = :black)

    xx = collect(range(1e-5, 1, 1000))
    yy = @. 1 / (2 * π * x)

    Legend(
        fig[1,2],
        [l1, l2, l3, l4],
        map(_format_model, [model1, model2, model3, model4]),
        orientation = :vertical,
        height = 10,
        framevisible = false,
        padding = (0, 0, 0, 0),
    )

    xlims!(ax, 5e-5, 0.3)
    ylims!(ax, -10, 50)

    Makie.save("presentation/figs/_raw/lag-frequency.svg", fig)
    fig
end

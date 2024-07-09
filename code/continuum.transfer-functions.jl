include("common.jl")

m = KerrMetric(1.0, 0.998)
d = DatumPlane(5.0)
x = SVector(0.0, 1000.0, deg2rad(45), 0.0)
x2 = SVector(0.0, 1000.0, deg2rad(75), 0.0)

radii = range(0.9, 20.0, 60) |> collect

itb1 = @time Gradus.interpolated_transfer_branches(m, x, d, radii; verbose = true, β₀ = 3.0)
itb2 =
    @time Gradus.interpolated_transfer_branches(m, x2, d, radii; verbose = true, β₀ = 5.0)

begin
    all_times = Float64[]
    for branch in itb1.branches
        append!(all_times, branch.lower_t.u, branch.upper_t.u)
    end
    mean_arrival_time1 = sum(all_times) / length(all_times)

    all_times = Float64[]
    for branch in itb2.branches
        append!(all_times, branch.lower_t.u, branch.upper_t.u)
    end
    mean_arrival_time2 = sum(all_times) / length(all_times)
end

gbins = collect(range(0.0, 1.4, 500))
tbins = collect(range(-25, 25.0, 300))

begin
    flux1 = @time Gradus.integrate_lagtransfer(
        identity,
        itb1,
        gbins,
        tbins;
        t0 = mean_arrival_time1,
        rmin = minimum(radii),
        rmax = maximum(radii),
        n_radii = 4000,
    )'
    pflux1 = replace(flux1, 0.0 => NaN)
    extrema(flux1)

    flux2 = @time Gradus.integrate_lagtransfer(
        identity,
        itb2,
        gbins,
        tbins;
        t0 = mean_arrival_time2,
        rmin = minimum(radii),
        rmax = maximum(radii),
        n_radii = 4000,
    )'
    pflux2 = replace(flux2, 0.0 => NaN)
    extrema(flux2)
end

begin
    fig = Figure(size = (650, 280), backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0))
    ax1 = Axis(
        fig[1, 1],
        ylabel = "Observed redshift",
        xlabel = "Time difference from mean",
        yticks = [0.2, 0.4, 0.6, 0.8, 1.0, 1.2],
        backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0),
    )
    ax2 = Axis(
        fig[1, 2],
        ylabel = "Observed redshift",
        xlabel = "Time difference from mean",
        yticks = [0.2, 0.4, 0.6, 0.8, 1.0, 1.2],
        yaxisposition = :right,
        backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0),
    )
    xlims!(ax1, -24, 24)
    xlims!(ax2, -24, 24)
    ylims!(ax1, 0.1, 1.3)
    ylims!(ax2, 0.1, 1.3)

    heatmap!(ax1, tbins, gbins, log10.(abs.(pflux1)), colormap = :batlow)
    heatmap!(ax2, tbins, gbins, log10.(abs.(pflux2)), colormap = :batlow)
    linkyaxes!(ax1, ax2)
    vlines!(ax1, [0.0], color = :black, linestyle = :dash)
    vlines!(ax2, [0.0], color = :black, linestyle = :dash)


    Makie.save("presentation/figs/_raw/continuum.transfer-function.png", fig)
    fig
end

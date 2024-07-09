include("common.jl")

function ring_transfer_function(m, d, model, rs, ts)
    prof = @time emissivity_profile(m, d, model)

    img_total = zeros(Float64, (length(ts), length(rs)))
    for (i, r) in enumerate(rs)
        interp = Gradus.emissivity_interp(prof, r)
        @views for (j, t) in enumerate(ts[1:end-1])
            dt = ts[j+1] - t
            img_total[j, i] += interp(t) * dt
        end
    end
    replace!(img_total, 0 => NaN)

    img_total
end


m = KerrMetric(1.0, 0.998)
d = ThinDisc(0.0, 1000.0)

rs = collect(10 .^ range(log10(max(1, Gradus.isco(m))), 1.5, 300))
ts = collect(10 .^ range(0, log10(45), 500))

ring_radius_1 = 3.0
ring_radius_2 = 11.0

tf1 = ring_transfer_function(m, d, RingCorona(ring_radius_1, 5.0), rs, ts)
tf2 = ring_transfer_function(m, d, RingCorona(ring_radius_2, 5.0), rs, ts)

flat_tf1 = ring_transfer_function(
    Gradus.SphericalMetric(),
    d,
    RingCorona(ring_radius_1, 5.0),
    rs,
    ts,
)
flat_tf2 = ring_transfer_function(
    Gradus.SphericalMetric(),
    d,
    RingCorona(ring_radius_2, 5.0),
    rs,
    ts,
)

begin
    fig = Figure(size = (800, 400), backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0))
    ax1 = Axis(
        fig[1, 1],
        yscale = log10,
        ytickformat = values -> ["$(trunc(Int, v))" for v in values],
        yticks = [1, 2, 5, 10, 20, 30],
        ylabel = "Radius on disc",
        xlabel = "Corona to disc time",
        backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0),
    )
    ax2 = Axis(
        fig[1, 2],
        yscale = log10,
        ytickformat = values -> ["$(trunc(Int, v))" for v in values],
        yticks = [1, 2, 5, 10, 20, 30],
        xlabel = "Corona to disc time",
        yaxisposition = :right,
        ylabel = "Radius on disc",
        backgroundcolor = RGBAf(0.0, 0.0, 0.0, 0.0),
    )

    ylims!(ax1, 1.23, nothing)
    xlims!(ax1, nothing, 45)
    ylims!(ax2, 1.23, nothing)
    xlims!(ax2, nothing, 45)


    crange = (-2, 0.7)
    heatmap!(ax1, ts, rs, log10.(tf2), colormap = Reverse(:matter), colorrange = crange)
    heatmap!(ax1, ts, rs, log10.(tf1), colormap = :batlow, colorrange = crange)
    hlines!(ax1, [ring_radius_1], color = :black, linestyle = :dash)
    hlines!(ax1, [ring_radius_2], color = :black, linestyle = :dash)

    heatmap!(
        ax2,
        ts,
        rs,
        log10.(flat_tf2),
        colormap = Reverse(:matter),
        colorrange = crange,
    )
    heatmap!(ax2, ts, rs, log10.(flat_tf1), colormap = :batlow, colorrange = crange)
    hlines!(ax2, [ring_radius_1], color = :black, linestyle = :dash)
    hlines!(ax2, [ring_radius_2], color = :black, linestyle = :dash)

    linkyaxes!(ax1, ax2)

    Makie.save("presentation/figs/_raw/ring-corona.transfer-functions.png", fig)
    fig
end

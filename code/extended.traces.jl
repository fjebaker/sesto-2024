include("common.jl")

function _example(
    m::AbstractMetric,
    d::AbstractAccretionGeometry,
    model::RingCorona,
    offset;
    rot = 0,
    callback = domain_upper_hemisphere(),
    kwargs...,
)
    θ₀ = atan(model.r, model.h)
    δs = deg2rad.(range(0, 179.9, 33)) .+ offset
    x, v = Gradus.sample_position_velocity(m, model)
    velfunc = Gradus.rotated_polar_angle_to_velfunc(m, x, v, δs, rot; θ₀ = θ₀)
    sols = tracegeodesics(
        m,
        x,
        velfunc,
        d,
        10000,
        # save_on = false,
        # ensemble = EnsembleEndpointThreads(),
        callback = callback,
        trajectories = length(δs),
        kwargs...,
    )
    filter(i -> i.prob.p.status[] != StatusCodes.WithinInnerBoundary, [i for i in sols])
end

function calc_emission(m, d, model, rot)
    gps1 = _example(m, d, model, 0; rot = rot)
    gps2 = _example(m, d, model, π; rot = rot)

    gps = vcat(gps2, gps1)
    rs = map(i -> Gradus._equatorial_project(unpack_solution(i).x), gps)
    _, i = findmin(rs)
    left, right = gps[1:i-1], gps[i:end]
    left_r, right_r = rs[1:i-1], rs[i:end]

    # find the radius that is closest and the two indices
    difference, index = findmin([
        abs(left_r[i] - right_r[j]) for i in eachindex(left_r), j in eachindex(right_r)
    ])
    left_r[index.I[1]], left, right
end

m = KerrMetric(1.0, 0.9)
model = RingCorona(9.0, 10.0)
d = ThinDisc(0.0, 1000.0)
rr, left, right = calc_emission(m, d, model, deg2rad(00.0));

x0 = SVector(0.0, sqrt(model.r^2 + model.h^2), atan(model.h, model.r), 0.0)
imps = impact_parameters_for_radius(m, x0, d, rr)
vs = [map_impact_parameters(m, x0, a, b) for (a, b) in zip(imps...)]
xs = fill(x0, size(vs))
simsols = tracegeodesics(
    m,
    xs,
    vs,
    d,
    2000.0;
    save_on = false,
    ensemble = Gradus.EnsembleEndpointThreads(),
)
times = map(i -> i.x[1], simsols)
phis = map(i -> i.x[4], simsols)

dim = 20.0
begin
    fig = Figure(size = (800, 600))
    ax = Axis3(
        fig[1, 1],
        aspect = (1, 1, 1),
        limits = (-dim, dim, -dim, dim, -dim, dim),
        elevation = π / 23, #π / 12,
        azimuth = -deg2rad(65),
        viewmode = :fitzoom,
        xgridvisible = false,
        ygridvisible = false,
        zgridvisible = false,
        xlabelvisible = false,
        ylabelvisible = false,
        xspinewidth = 0,
        yspinewidth = 0,
        zspinewidth = 0,
    )
    hidedecorations!(ax)

    R = Gradus.inner_radius(m)
    bounding_sphere!(ax; R = R, color = :black)
    plotring(
        ax,
        model.r;
        horizon_r = R,
        height = model.h,
        color = :black,
        dim = dim,
        linestyle = :dash,
        linewidth = 1.0,
    )

    for r in range(2.4 + ((rr - 2.4) % 3), 19.0, step = 3)
        plotring(ax, r; horizon_r = R, color = :black, dim = dim)
    end

    palette = _default_palette()
    for sol in right
        plot_sol(
            ax,
            sol;
            color = popfirst!(palette),
            horizon_r = R,
            dim = dim,
            show_intersect = true,
        )
    end
    for sol in left
        plot_sol(
            ax,
            sol;
            color = popfirst!(palette),
            horizon_r = R,
            dim = dim,
            show_intersect = true,
            linestyle = :dash,
        )
    end

    plot_obscured_line!(
        ax,
        SVector(0.0, 0.0, 0.0),
        SVector(model.r, 0.0, model.h);
        horizon_r = R - 0.2,
        color = :black,
        linestyle = :dash,
        linewidth = 1.0,
    )


    plotring(
        ax,
        model.r;
        horizon_r = R,
        height = -model.h,
        color = :black,
        dim = dim,
        linewidth = 1.0,
    )

    delay_times = 4.0 * times ./ maximum(times)
    plot_along_ring!(ax, rr, phis, delay_times; N = 100, zero = -model.h)

    Makie.save("presentation/figs/_raw/extended.traces.pdf", fig)
    fig
end

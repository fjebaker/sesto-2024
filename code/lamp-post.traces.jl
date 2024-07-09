include("common.jl")

function trace_even(m, d, model; δs = deg2rad.(range(0.01, 179.99, 40)))
    x, v = Gradus.sample_position_velocity(m, model)
    vs = map(δs) do δ
        Gradus.sky_angles_to_velocity(m, x, v, δ, π)
    end
    xs = fill(x, size(vs))

    sols = tracegeodesics(m, xs, vs, d, 2000.0)
end

function plot_path_xz!(ax, sol; N = 700, kwargs...)
    x, y, z = Gradus._extract_path(sol, N, t_span = 1000.0)
    lines!(ax, x, z; kwargs...)
end

function plot_paths_xz!(ax, sols; kwargs...)
    for sol in sols
        plot_path_xz!(ax, sol; kwargs...)
    end
end

m = KerrMetric(a = 0.9)
d = ShakuraSunyaev(m, eddington_ratio = 0.2)

model = LampPostModel(h = 7.0, θ = 1e-6)
sols1 = trace_even(m, d, model)

sols_all = vcat(sols1.u[1:8], sols1.u[10:end]);
sols_selected = sols1.u[8:9]


R = Gradus.inner_radius(m)
angles = collect(range(0.0, 2π, 100))

horizon_x = @. cos(angles) * R
horizon_y = @. sin(angles) * R

begin
    radii = collect(range(0.0, 55.0, 500))
    heights = Gradus.cross_section.(d, radii)
    I = findfirst(>(0), heights)
    radii = radii[I-1:end]
    heights = heights[I-1:end]
end

# those that intersect the disc
begin
    intersected = filter(sols1.u) do sol
        sol.prob.p.status[] == StatusCodes.IntersectedWithGeometry
    end

    targets = map(intersected) do sol
        gpx = unpack_solution(sol).x
        R = Gradus._equatorial_project(gpx)
        H = Gradus._spinaxis_project(gpx)
        (R, H)
    end

    targets = filter(i -> i[1] < 15, targets)

    x = SVector(0.0, 50.0, deg2rad(55), 0.0)
    impact_params = map(targets) do ((r, H))
        th = -π / 2
        R, _ = find_offset_for_radius(m, x, Gradus.DatumPlane(H), r, th)
        α = R * cos(th)
        β = R * sin(th)
        (α, β)
    end

    vs = [map_impact_parameters(m, x, a, b) for (a, b) in impact_params]
    xs = fill(x, size(vs))

    ob_sols = tracegeodesics(m, xs, vs, d, 2000.0)
end

# returning radiation
begin
    origin_gp = unpack_solution(sols1.u[19])
    model2 = LampPostModel(h = origin_gp.x[2], θ = origin_gp.x[3])

    returnsols = trace_even(m, d, model2; δs = collect(range(0, 2π, 50)))
end

begin
    a0, b0, _, _ = Gradus.optimize_for_target(SVector(0.0, model.h, model.θ, 0.0), m, x)
    # don't want the full solution, just up until the spin axis
    function _kill_callback()
        function _positive_domain(u, t, integrator)
            X = @views Gradus.spherical_to_cartesian(u[2:4])
            X[2] < 0
        end
        Gradus.DiscreteCallback(
            _positive_domain,
            Gradus.terminate_with_status!(StatusCodes.OutOfDomain),
        )
    end
    direct = tracegeodesics(
        m,
        x,
        map_impact_parameters(m, x, a0, b0),
        2000.0,
        callback = _kill_callback(),
    )
end

begin
    fig = Figure(size = (500, 400))
    ax2 = Axis(
        fig[1, 1],
        aspect = DataAspect(),
        yticks = LinearTicks(3),
        topspinevisible = false,
        leftspinevisible = false,
        rightspinevisible = false,
        bottomspinevisible = false,
    )
    hidedecorations!(ax2)
    xlims!(ax2, -5, 45)
    ylims!(ax2, -5, 35)
    lines!(ax2, horizon_x, horizon_y, color = :black, linewidth = 3.0)

    # plot_paths_xz!(ax2, sols1)
    # plot_paths_xz!(ax2, ob_sols)
    plot_paths_xz!(ax2, returnsols)
    # plot_path_xz!(ax2, direct)

    draw_observer_eye!(
        ax2,
        x[2] * sin(x[3]) + 2,
        x[2] * cos(x[3]) + 1.6,
        1.0;
        rot = deg2rad(40 + 180),
        linewidth = 2.3,
    )

    begin
        lines!(ax2, radii, heights, color = :black)
        lines!(ax2, radii, -heights, color = :black)
        lines!(ax2, -radii, heights, color = :black)
        lines!(ax2, -radii, -heights, color = :black)
    end
    Makie.save("presentation/figs/_raw/lamp-post.traces.svg", fig)
    fig
end

nothing

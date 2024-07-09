using Gradus, Makie, CairoMakie, LaTeXStrings
using CoordinateTransformations, Rotations, LinearAlgebra
import Gradus.DataInterpolations as DataInterpolations

_default_palette() = Iterators.Stateful(Iterators.Cycle(Makie.wong_colors()))

function clip_plot_lines!(ax, x, y, z; dim = 10.0, kwargs...)
    mask = @. (x > dim) | (x < -dim) | (y > dim) | (y < -dim) | (z > 1.05dim)
    mask = .!mask
    Makie.lines!(ax, x[mask], y[mask], z[mask]; kwargs...)
end
function clip_plot_scatter!(ax, x, y, z; horizon_r = 1.0, kwargs...)
    if first(is_visible(ax, [x; y; z], horizon_r))
        clip_plot_scatter!(ax, [x], [y], [z]; kwargs...)
    end
end
function clip_plot_scatter!(
    ax,
    x::AbstractArray,
    y::AbstractArray,
    z::AbstractArray;
    linewidth = nothing,
    linestyle = nothing,
    dim = 10.0,
    kwargs...,
)
    mask = @. (x > dim) | (x < -dim) | (y > dim) | (y < -dim) | (z > 1.1dim)
    mask = .!mask
    Makie.scatter!(ax, x[mask], y[mask], z[mask]; kwargs...)
end

spher_to_cart(r, θ, ϕ) = (r * sin(θ) * cos(ϕ), r * sin(θ) * sin(ϕ), r * cos(θ))

function plot_obscured_line!(ax, A, B; horizon_r = 1.0, kwargs...)
    p = A
    dvec = B - A
    for i = 1:1000
        if first(is_visible(ax, [p[1]; p[2]; p[3]], horizon_r)) &&
           (LinearAlgebra.norm(p) > horizon_r)
            break
        end
        p += dvec * 0.001
    end

    x, y, z = [p[1], B[1]], [p[2], B[2]], [p[3], B[3]]
    clip_plot_lines!(ax, x, y, z; linewidth = 0.6, kwargs...)
end

function plot_line_occluded!(ax, x, y, z, R; kwargs...)
    points_ = reduce(hcat, [x, y, z])'
    mask = is_visible(ax, points_, R)

    s = 1
    e = 1
    for i in mask
        if !i
            if s != e
                clip_plot_lines!(
                    ax,
                    x[s:e-1],
                    y[s:e-1],
                    z[s:e-1],
                    linewidth = 0.8,
                    ;
                    kwargs...,
                )
            end
            s = e
        end
        e += 1
    end
    if s != e
        clip_plot_lines!(ax, x[s:e-1], y[s:e-1], z[s:e-1], linewidth = 0.8, ; kwargs...)
    end
end

function circle_points(θ; N = 100, r = 1.0)
    ϕ = range(0.0, 1, N) * 2π # 0.0:0.01:2π
    x = @. r * sin(θ) * cos(ϕ)
    y = @. r * sin(θ) * sin(ϕ)
    z = r * cos(θ) .* ones(length(ϕ))
    x, y, z
end

function bounding_sphere!(ax; R = 1.005, kwargs...)
    phi_circ = 0.0:0.001:2π
    x = @. R * cos(phi_circ)
    y = @. R * sin(phi_circ)
    z = zeros(length(y))

    t = LinearMap(RotZ(ax.azimuth.val - π)) ∘ LinearMap(RotY(ax.elevation.val - π / 2))
    points = reduce(hcat, [x, y, z])'
    translated = reduce(hcat, map(t, eachcol(points)))


    clip_plot_lines!(
        ax,
        translated[1, :],
        translated[2, :],
        translated[3, :];
        linewidth = 1.9,
        kwargs...,
    )
    #translated
end

function is_visible(ax, points, R)
    # transform viewing angle to normal vector in data coordinates
    a = ax.azimuth.val - π
    e = ax.elevation.val - π / 2
    n = [spher_to_cart(R, e, a)...]
    n = n ./ LinearAlgebra.norm(n)
    # clip_plot_scatter!(ax, [n[1]], [n[2]], [n[3]])
    map(eachcol(points)) do p
        k = (p ⋅ n)
        if k > 0 # infront
            true
        else
            Pp = p - (k .* n)
            sqrt(abs(Pp ⋅ Pp)) > R
        end
    end
end

function plot_sol(
    ax,
    x;
    show_intersect = false,
    R = 1.0,
    dim = 10.0,
    horizon_r = R,
    kwargs...,
)
    cart_points = []
    for t in range(x.t[1], min(200, x.t[end]), 5_000)
        p = x(t)[1:4]
        if p[2] > (1.08 * horizon_r)
            push!(cart_points, [spher2cart(p...)...])
        end
    end
    res = reduce(hcat, cart_points)'
    # Plots.plot3d!(res[:, 1], res[:, 2], res[:, 3] ; color = COLOR)
    # plot_line_occluded!(ax, res[:, 1], res[:, 2], res[:, 3], R)
    mask = is_visible(ax, res', R)

    # plot disconnected continuous regions
    s = 1
    e = findnext(==(0), mask, s)
    if isnothing(e)
        e = lastindex(mask)
    end
    @views while e < lastindex(mask)
        clip_plot_lines!(
            ax,
            res[s:e, 1],
            res[s:e, 2],
            res[s:e, 3];
            linewidth = 0.8,
            kwargs...,
        )
        s = findnext(==(true), mask, e)
        if isnothing(s)
            s = lastindex(mask)
        end
        e = findnext(==(false), mask, s)
        if isnothing(e)
            e = lastindex(mask)
        end
    end
    clip_plot_lines!(
        ax,
        res[s:e, 1],
        res[s:e, 2],
        res[s:e, 3];
        linewidth = 0.8,
        dim = dim,
        kwargs...,
    )
    if show_intersect && x.prob.p.status[] == Gradus.StatusCodes.IntersectedWithGeometry
        clip_plot_scatter!(
            ax,
            res[e, 1],
            res[e, 2],
            res[e, 3];
            dim = dim,
            horizon_r = horizon_r,
            markersize = 8,
            kwargs...,
        )
    end
end

function plot_along_ring!(
    ax,
    r,
    Xs,
    Ys;
    N = 100,
    rot = 0,
    linewidth = 1.0,
    zero = 0.0,
    band_alpha = 0.1,
    kwargs...,
)
    XX = mod2pi.(Xs)
    I = sortperm(XX)
    _interp = @views DataInterpolations.LinearInterpolation(Ys[I], XX[I])
    Xlow, Xhigh = extrema(XX)

    function interp(v)
        if v >= Xlow && v <= Xhigh
            _interp(v)
        else
            NaN
        end
    end

    upper = Point3f[]
    lower = Point3f[]
    for phi in range(0.0, 2π, N)
        X, Y, Z = spher2cart(r, π / 2, phi)
        val = interp(mod2pi(phi + rot))
        if isnan(val)
            continue
        end
        p1 = Point3f(X, Y, Z + zero + val)
        p2 = Point3f(X, Y, zero)
        push!(upper, p1)
        push!(lower, p2)
    end

    push!(upper, first(upper))
    push!(lower, first(lower))

    band!(ax, lower, upper; kwargs..., alpha = band_alpha)
    lines!(ax, upper; linewidth = linewidth, kwargs...)
end

function plotring(ax, r; height = 0, horizon_r = 1.0, kwargs...)
    x = Float64[]
    y = Float64[]
    z = Float64[]
    for ϕ in range(0.0, 2π, 500)
        X, Y, Z = spher2cart(r, π / 2, ϕ)
        push!(x, X)
        push!(y, Y)
        push!(z, Z + height)
    end
    # clip_plot_lines!(ax, x, y, z, color=COLOR, linewidth = 0.8)
    plot_line_occluded!(ax, x, y, z, horizon_r; linewidth = 0.8, kwargs...)
end

spher2cart(r, θ, ϕ) = r * sin(θ) * cos(ϕ), r * sin(θ) * sin(ϕ), r * cos(θ)
cart2sphere(x, y, z) = (√(x^2 + y^2 + z^2), atan(y, x), atan(√(x^2 + y^2), z))
spher2cart(_, r, θ, ϕ) = spher2cart(r, θ, ϕ)

# this function is absolutely terrible but it does the job of drawing an eye
function draw_observer_eye!(ax, x0, y0, scale; flip = false, linewidth = 4.0, rot = 0)
    rotmat = [cos(rot) -sin(rot); sin(rot) cos(rot)]

    x_xfm(x) = @. scale * x * (flip ? -1 : 1) + x0
    y_xfm(y) = @. scale * y + y0

    function xfm(x, y)
        rotated = map(eachindex(x)) do i
            rotmat * [x[i], y[i]]
        end
        xr = first.(rotated)
        yr = last.(rotated)
        x_xfm(xr), y_xfm(yr)
    end

    ls = collect(range(0, 2, 20))
    x1 = ls
    y1 = @. exp(0.3 * ls) - 1

    kwargs = (; color = :black, linewidth = linewidth)
    lines!(ax, xfm(x1, y1)...; kwargs...)
    lines!(ax, xfm(x1[1:end-1], -y1[1:end-1])...; kwargs...)

    i1 = 2
    θ1 = atan(y1[end-i1], x1[end-1])
    θ2 = atan(-y1[end-i1], x1[end-1])

    theta = collect(range(θ1, θ2, 20))

    x2 = @. x1[end-i1] * cos(theta)
    y2 = @. x1[end-i1] * sin(theta)

    lines!(ax, xfm(x2, y2)...; kwargs...)

    i2 = 1
    phi1 = atan(y2[i2], x2[i2])
    phi2 = atan(y2[end-i2], x2[end-i2])

    phi = collect(range(phi1, phi2, 20))
    x3 = @. -1.7 * cos(phi) + (1.7 + x1[end-i1] - 0.15)
    y3 = @. 1 * sin(phi)

    lines!(ax, xfm(x3, y3)...; kwargs...)
end

include("common.jl")

function flux_profile(m, x, d, model, itb, gbins, tbins; n_samples = 3000)
    prof = @time emissivity_profile(m, d, model; n_samples = n_samples)
    flux = Gradus.integrate_lagtransfer(
        prof, 
        itb, 
        gbins, 
        tbins; 
        t0 = x[2],
        n_radii = 2000,
        rmin = minimum(radii),
        rmax = maximum(radii),
    )
    replace!(flux, 0.0 => NaN)
end

m = KerrMetric(1.0, 0.998)
x = SVector(0.0, 10000.0, deg2rad(45), 0.0)

# currently needs an infinite disc for the root finder (patch coming soon)
d = ThinDisc(0.0, Inf)
radii = Gradus.Grids._inverse_grid(Gradus.isco(m), 1300.0, 200)
itb = @time Gradus.interpolated_transfer_branches(m, x, d, radii; verbose = true)

model = DiscCorona(10.0, 10.0)

prof = @time emissivity_profile(m, d, model; n_samples = 200)

gbins = collect(range(0.0, 1.4, 300))
tbins = collect(range(0, 800.0, 900))

# dispatches special methods for calculating the emissivity profile if available
function _velocity_function(r)
    0
end

flux = @time flux_profile(m, x, d, model, itb, gbins, tbins; n_samples = 600)

begin
    p = heatmap(
        tbins,
        gbins,
        log10.(flux')
    )
end

begin
    lpflux = flux_profile(m, x, d, LampPostModel(h = model.h), itb, gbins, tbins)
    freq1, tau1 = @time Gradus.lag_frequency(tbins, lpflux)
    freq2, tau2 = @time Gradus.lag_frequency(tbins, flux)
end

begin
    fig = Figure()
    ax = Axis(
        fig[1,1],
        xscale = log10,
    )    
    
    lines!(ax, freq1, tau1)
    lines!(ax, freq2, tau2)
    xlims!(ax, 1e-4, 1)
    ylims!(ax, -5, 30)

    fig
end


function lag_energy(data, flow, fhi)
    f_example = data[1][1]
    i1 = findfirst(>(flow), f_example)
    i2 = findfirst(>(fhi), f_example)
    lE = map(data) do (_, tau)
        sum(tau[i1:i2]) / (i2 - i1)
    end
end

function lag_frequency_rowwise(t, f::AbstractMatrix; flo = 1e-5, kwargs...)
    map(eachrow(f)) do ψ
        t_extended, ψ_extended = Gradus.extend_domain_with_zeros(t, ψ, 1 / flo)
        Gradus.lag_frequency(t_extended, ψ_extended; kwargs...)
    end
end


data = lag_frequency_rowwise(tbins, replace(flux, NaN => 0))
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
    fig = Figure()
    ax = Axis(
        fig[1,1],
    )    
    
    palette = _default_palette()
    
    for (le, lple) in zip((le1, le2, le3, le4), (lp_le1, lp_le2, lp_le3, lp_le4))
        color = popfirst!(palette)
        lines!(ax, gbins, le, color = color)
        lines!(ax, gbins, lple, color = color, linestyle = :dot)
    end

    fig
end

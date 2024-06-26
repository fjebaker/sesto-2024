OUTPUT_DIRECTORY = "../presentation/figs/"

macro buildfigure(path)
    quote
        @info "Building figure: " * $(path)
        @time include($path)
    end |> esc
end


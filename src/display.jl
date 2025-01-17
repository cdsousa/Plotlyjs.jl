# ----------- #
# Blink setup #
# ----------- #

const _js_path = joinpath(dirname(dirname(@__FILE__)),
                          "deps", "plotly-latest.min.js")

function html_body(p::Plot)
    """
    <div id="$(p.divid)"></div>

    <script>
       thediv = document.getElementById('$(p.divid)');
       var data = $(json(p.data))
       var layout = $(json(p.layout))

       Plotly.plot(thediv, data,  layout, {showLink: false});
     </script>
    """
end

stringmime(::MIME"text/html", p::Plot) =  """
    <html>
    <head>
        <script src="$(_js_path)"></script>
    </head>

    <body>
      $(html_body(p))
    </body>
    </html>
    """

Base.writemime(io::IO, ::MIME"text/html", p::Plot) =
    print(io, stringmime(MIME"text/html"(), p))


get_blink() = Blink.AtomShell.shell()

function get_window(p::Plot)
    if !isnull(p.window) && active(get(p.window))
        w = get(p.window)
    else
        width, height = size(p)
        w = Window(get_blink(), Dict{Any,Any}(:width=>width, :height=>height))
        p.window = Nullable{Window}(w)
    end
    w
end

function Base.show(p::Plot)
    w = get_window(p)
    Blink.load!(w, _js_path)
    Blink.body!(w, html_body(p))
    p
end

# ---------------------- #
# Jupyter notebook setup #
# ---------------------- #

# if we're in IJulia call setupnotebook to load js and css
if isdefined(Main, :IJulia) && Main.IJulia.inited
    # the first script is some hack I needed to do in order for the notebook
    # to not complain about Plotly being undefined
    display("text/html", """
        <script type="text/javascript">
            require=requirejs=define=undefined;
        </script>
        <script type="text/javascript">
            $(open(readall, _js_path, "r"))
        </script>
     """)
    display("text/html", "<p>Plotly javascript loaded.</p>")
end

# -------------- #
# Javascript API #
# -------------- #

function _call_js(p::Plot, code::AbstractString)
    Blink.js(get_window(p), Blink.JSString(code))
    p
end

prep_kwarg{T}(a::Tuple{Symbol,T}) = (symbol(replace(string(a[1]), "_", ".")), a[2])

function restyle!(p::Plot, update; kwargs...)
    thediv = "document.getElementById('$(p.divid)')"
    update = json(merge(update, Dict(map(prep_kwarg, kwargs))))
    _call_js(p, "Plotly.restyle($thediv, $update);")
end

function restyle!(p::Plot; kwargs...)
    thediv = "document.getElementById('$(p.divid)')"
    update = json(Dict(map(prep_kwarg, kwargs)))
    _call_js(p, "Plotly.restyle($thediv, $update);")
end

# function restyle!(p::Plot, stuff::AbstractPlotlyElement...)
#     thediv = "document.getElementById('$(p.divid)')"
#     Blink.js(w, Blink.JSString("Plotly.restyle($thediv, $update);"))
# end

# TODO: consider the array stuff

function relayout!(p::Plot, update; kwargs...)
    thediv = "document.getElementById('$(p.divid)')"
    update = json(merge(update, Dict(map(prep_kwarg, kwargs))))
    _call_js(p, "Plotly.relayout($thediv, $update);")
end

function relayout!(p::Plot; kwargs...)
    thediv = "document.getElementById('$(p.divid)')"
    update = json(Dict(map(prep_kwarg, kwargs)))
    _call_js(p, "Plotly.relayout($thediv, $update);")
end

function addtraces!(p::Plot, traces::AbstractTrace...)
    thediv = "document.getElementById('$(p.divid)')"
    update = json(traces)
    _call_js(p, "Plotly.addTraces($thediv, $update);")
end

# TODO: add method for where to add trace

function deletetraces!(p::Plot, traces::Int...)
    thediv = "document.getElementById('$(p.divid)')"
    update = length(traces) == 1 ? traces[1] : json(collect(traces))
    _call_js(p, "Plotly.deleteTraces($thediv, $update);")
end

function movetraces!(p::Plot, to_end::Int)
    thediv = "document.getElementById('$(p.divid)')"
    _call_js(p, "Plotly.moveTraces($thediv, $to_end);")
end

function movetraces!(p::Plot, to_end::Vector{Int})
    thediv = "document.getElementById('$(p.divid)')"
    update = json(to_end)
    _call_js(p, "Plotly.moveTraces($thediv, $update);")
end

movetraces!(p::Plot, to_end...) = movetraces!(p, collect(to_end))

function movetraces!(p::Plot, src::Vector{Int}, dest::Vector{Int})
    thediv = "document.getElementById('$(p.divid)')"
    src = json(src)
    dest = json(dest)
    _call_js(p, "Plotly.moveTraces($thediv, $src, $dest);")
end

function redraw!(p::Plot)
    thediv = "document.getElementById('$(p.divid)')"
    _call_js(p, "Plotly.redraw($thediv);")
end

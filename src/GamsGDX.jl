module GamsGDX

export Gdx
export path, sets, parameters, variables

using PyCall
using DataFrames

"""
Wrapper around a GAMS Data eXchange file read using the Python gamstransfer package.
On request, variables and parameters are converted to DataFrames with their name and description as metadata.

To open a gdx file use the constructor: Gdx(file_path)

Variables or parameters can be accessed with dot or index notation.

Example:
    db = Gdx(file_path)
    foo = db.foo
    bar = db[:bar]
"""
struct Gdx
    path::String
    data::Dict{Symbol, PyObject}
    sets::Vector{Symbol}
    parameters::Vector{Symbol}
    variables::Vector{Symbol}
end

"""Return the path of the loaded gdx file"""
path(db::Gdx) = db.path

"""Return a vector of sets available in the gdx file"""
sets(db::Gdx) = db.sets

"""Return a vector of parameters available in the gdx file"""
parameters(db::Gdx) = db.parameters

"""Return a vector of variables available in the gdx file"""
variables(db::Gdx) = db.variables


function Gdx(file_path)
    gt = pyimport("gamstransfer")
    db = gt.ConstContainer()
    db.read(file_path)

    data = Dict(Symbol(k) => v for (k, v) in db.data)
    sets = Symbol.(db.listSets())
    parameters = Symbol.(db.listParameters())
    variables = Symbol.(db.listVariables())

    return Gdx(file_path, data, sets, parameters, variables)
end

parse_if(type, s) = isnothing(tryparse(type, s)) ? s : tryparse(type, s)

function __dataframe_from_variable_or_parameter(gt_obj, value_field, try_int_parse)
    df = DataFrame()
    for property in ["name", "description"]
        metadata!(df, property, gt_obj[property], style=:default)
    end
    for (name, label) in zip(gt_obj.domain_names, gt_obj.domain_labels)
        set = string.(gt_obj.records[label])
        if try_int_parse
            set = parse_if.(Int64, set)
        end
        df[!,name] = set
    end
    df[!,"value"] = Float64.(gt_obj.records[value_field])
    return df
end

dataframe_from_parameter(gt_obj, try_int_parse=true) = __dataframe_from_variable_or_parameter(gt_obj, "value", try_int_parse)
dataframe_from_variable(gt_obj, try_int_parse=true) = __dataframe_from_variable_or_parameter(gt_obj, "level", try_int_parse)

function Base.getproperty(db::Gdx, symbol::Symbol)
    if symbol in getfield(db, :variables)
        return dataframe_from_variable(db.data[symbol])
    elseif symbol in getfield(db, :parameters)
        return dataframe_from_parameter(db.data[symbol])
    else
        return getfield(db, symbol)
    end
end

Base.getindex(db::Gdx, symbol::Symbol) = getproperty(db, symbol)

end # module GamsGDX
# TimeBars.jl

## Goals
This package exists in order to attempt to satisfy the following requirements (that I haven't seen to be satisifed by other time series or general table packages):
* fully inferred dispatch on whatever kind of table you want: write efficient methods to dispatch on tables with particular sets of columns
* dispatch on particular sets of columns easily with good code reuse (ie using type inheritance or traits)
* ability to work with different kinds of array storage formats
* ability to work with regularly and irregularly indexed series
* single / multi-valued tables
* single / multi-indexed tables
* single / multi-dimensional tables
* ability to expand and contract multi-indexed tables to single or multi-dim tables (like unstack / stack in pandas)

While some table packages do have fully inferred dispatch on different table types, they tend to lack the ability to do so easily with a high degree of code reuse. I want to use type inheritance and/or traits to have fully inferred dispatch that also keeps code reuse and readability high so that these methods are easy to maintain.

The StructArrays.jl package gives us the ability to store a list of arrays that are associated with the fields of a collection of a given struct type. While a `StructArray` looks like an array-of-structures (AOS) it does not store the array of structs, only the underlying component arrays (making it SOA underneath the hood).

Using StructArrays.jl, not only do we get to keep our table in a particular structure without having to materialize that structure, we get to use whatever underlying storage format we want! Creating a method to work for a particular set of columns is as easy as: `fn(StructArray{<:MyCols})` or `fn(StructArray{<:MyAbstractCols})`.

This is in contrast to other tables where every table field would need to be included in the method, something like: `fn(OtherTable{a::Int, b::Float32, c<:AbstractString, ...})`. While this might give us the fully inferred dispatch we want, it is unwieldly and harder to maintain for certain applications.

TimeBars.jl is for cases when the tables you are using have natural structure that is worth encoding in their own types as you will be using them within structured data pipelines (eg mirroring the structure of long running SQL tables). On the other hand, for cases when you need a high degree of adhoc flexibility the approaches offered by DataFrames.jl, TypedTables.jl, or some of the other table packages would be more appropriate.

TimeBars.jl offers element types attached to methods that work with `StructArray` / `StructVector` array types to give us the time series functionality that meet the above requirements.

## Install
Install this package to your project environment as you would any other unregistered package.

From the Julia REPL:
```
julia> ]
(MyProject) pkg> add https://github.com/kpa28-git/TimeBars.jl
```

<!-- ## Overview -->
<!-- `TimeBars.jl` supplies abstract element types to be used with `StructArray`s (from [StructArrays.jl](https://juliaarrays.github.io/StructArrays.jl/stable/)). As the abstract types move from most to least abstract, they gain functionality and assumptions. --> 

<!-- ### Type Tree and Subtyping -->
<!-- The type tree is a simple line (`Bar` is the root type): -->

<!-- ``` -->
<!-- Bar >: IndexedBar >: SeriesBar >: TimeSeriesBar >: TimeTypeBar -->
<!-- ``` -->

<!-- Subtype them with your own struct element types to gain the functionality. See `src/bar/concrete/ohlc.bar.jl` for a simple example of subtyping a `TimeTypeBar`. -->

<!-- This package is intended mainly for time series use; only the following types are exported: `TimeSeriesBar`, `TimeTypeBar`. The others exist mainly to organize functionality, but can still be subtyped directly if you want (e.g. non-time series or other uniquely indexed observations). View the docstrings of each type for their semantics and other details. -->

<!-- ### `IndexedBar` and `TimeBars.index` -->
<!-- Most useful bars directly or indirectly subtype `IndexedBar`. Any `MyBar <: IndexedBar` must supply methods for a function called `TimeBars.index`. Specifically, the following: -->

<!-- * `TimeBars.index(bar::MyIndexedBar)`: returns index field(s) of a bar -->
<!-- * `TimeBars.index(arr::StructArray{<:MyIndexedBar})`: return index array of a `StructArray{<:IndexedBar}` -->

<!-- For a single-valued index, we just use the values themselves. For a multi-valued index, we use a `NamedTuple` / `StructArray{<:NamedTuple}` though this may change in the future. See the docstring for `IndexedBar` and `TimeBars.index` for more details. --> 

<!-- ### `Base.isvalid` -->
<!-- * Caling `isvalid` on your struct bar type will verify that your type validly implements the parent bar interface. It is good practice to `@assert isvalid(MyBar)` after defining the struct type `MyBar`. -->
<!-- * Calling `isvalid` on an instance of your bar will verify runtime attributes (can be slow). -->

<!-- ### `Base.convert` -->
<!-- `StructArray.jl`'s SOA memory layout makes it simple and efficient to convert between tables. -->
<!-- #### Downconversions -->
<!-- If one struct bar type, `BarA`, is a subset of another struct bar type, `BarB`, then `StructArray{BarB}`->`StructArray{BarA}` is free. This allows us to define our methods which only need the fields of `BarA` and efficiently use them will all superset Bars like `BarB` (`Base.convert` still need to be explicitly called, but wrapper functions dont need to know anything about the content of `BarA` or `BarB`). -->

<!-- #### Upconversions -->
<!-- If you want to convert to a bar with more fields (`StructArray{BarA}`->`StructArray{BarB}`), then you need to define `Base.convert` methods for this purpose. This is also typically a cheap and easy operation with StructArrays. -->

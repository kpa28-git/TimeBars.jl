"""
$(TYPEDSIGNATURES)
Create empty `StructArray{<:Bar, N}` using field type replacements `Y`...
"""
function Base.empty(::Type{T}, N::Integer=1, Y::Pair{<:Type, <:Type}...) where {T<:Bar}
	nd = (0 for _=1:N)
	F = replace(fieldtypes(T), Y...)
	cols = NamedTuple{fieldnames(T)}(Array{I,N}(undef, nd...) for I in F)
	StructArray{T}(cols)
end

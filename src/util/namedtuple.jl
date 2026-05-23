"""
$(TYPEDSIGNATURES)
Produce a `StructArray{<:NamedTuple}` equivalent where missings are allowed.
"""
function allowmiss(sa::StructArray)
	comps = StructArrays.components(sa)
	nt = NamedTuple{keys(comps)}(map(allowmissing, values(comps)))
	StructArray(nt)
end

"""
$(TYPEDSIGNATURES)
Produce a `StructArray{<:T}` equivalent where missings are disallowed.
"""
function disallowmiss(T::Type, sa::StructArray)
	comps = StructArrays.components(sa)
	nt = NamedTuple{keys(comps)}(map(disallowmissing, values(comps)))
	StructArray{T}(nt)
end

# """
# $(TYPEDSIGNATURES)
# Construct a `StructArray{<:NamedTuple}`, where only the provided `data` are defined and the rest are undefined.

# This is not a `StructArray{<:NamedTuple}` constructor because we want to avoid type piracy.
# """
# function emptysa(::Type{T}, data::Pair{Symbol, <:AbstractArray}...) where {T<:NamedTuple}
# 	arr = StructArray{T}(undef, size(last(first(data))))
# 	for (k,v) in data
# 		getproperty(arr, k) .= v
# 		# setproperty!(arr, k, v)
# 	end
# 	arr
# end

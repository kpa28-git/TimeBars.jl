findgaps(idx::AbstractVector, τ) = findall(>(τ), diff(idx))

function index_range((f,l)::Pair, τ; excl_f=true, excl_l=true)
	(f+τ*excl_f):τ:(l-τ*excl_l)
end

"""
$(TYPEDSIGNATURES)
Return filled-in index based on period, τ.
Return new index and filled-in (hole) locations.
"""
function fillin(idx::AbstractVector, τ)
	newidx = idx |> copy
	gaps = findgaps(idx, τ)
	offset = 0
	holes = Int[]
	for gap in gaps
		realgap = gap + offset
		gapr = index_range(idx[gap]=>idx[gap+1], τ)
		for (i, val) in enumerate(gapr)
			insert!(newidx, realgap+i, val)
			push!(holes, realgap+i)
		end
		offset += length(gapr)
	end
	newidx, holes
end

"""
$(TYPEDSIGNATURES)
Return index with head and tail extended based on period, τ, and range `to`.
Return new index and hole locations.
XXX - Untested
"""
function fillout(idx::AbstractVector, τ, (f,l)::Pair)
	newidx = idx
	holes = Int[]
	if f < first(idx)
		headidx = index_range(f=>first(idx), τ; excl_f=false)
		holes = append!(holes, eachindex(headidx))
		newidx = vcat(headidx, newidx)
	end
	if last(idx) < l
		tailidx = index_range(last(idx)=>l, τ; excl_l=false)
		holes = append!(holes, eachindex(tailidx) .+ length(newidx))
		newidx = vcat(newidx, tailidx)
	end
	newidx, holes
end

"""
$(TYPEDSIGNATURES)
Return `out` with interior holes filled in from `vals`
"""
function fillin!(out::AbstractVector, vals::AbstractVector, holes::AbstractVector{<:Integer})
	i = firstindex(out)
	a = firstindex(vals)
	h = firstindex(holes)
	while h ≤ length(holes)
		if i != holes[h]
			out[i] = vals[a]
			a += 1
		else
			h += 1
		end
		i += 1
	end
	while i ≤ length(out)
		out[i] = vals[a]
		a += 1
		i += 1
	end
	out
end

"""
$(TYPEDSIGNATURES)
Return a `Vector{Union{Missing, T}}`` with missing values at the interior `holes` indices.
"""
function holedvalues(vals::AbstractVector{T}, holes::AbstractVector{<:Integer}) where {T}
	mvals = Vector{Union{Missing, T}}(missing, length(vals) + length(holes))
	fillin!(mvals, vals, holes)
end

"""
$(TYPEDSIGNATURES)
Return a `Vector{Union{Missing, T}}`` with missing values at the interior `holes` indices, with any initial offset from `holesout`.
XXX - Untested
"""
function holedvalues(vals::AbstractVector{T}, holes::AbstractVector{<:Integer}, holesout::AbstractVector{<:Integer}) where {T}
	inner = length(vals) + length(holes)
	mvals = Vector{Union{Missing, T}}(missing, inner + length(holesout))
	offset = 0 
	for i = eachindex(holesout)
		i != holesout[i] && break
		offset = i
	end
	fillin!(view(mvals, 1+offset:offset+inner), vals, holes)
	mvals
end

"""
$(TYPEDSIGNATURES)
Same imputation for all fields (in-place)
"""
function imputevalues!(mvals, imputer, _)
	Impute.impute!(mvals, imputer)
end

"""
$(TYPEDSIGNATURES)
Per-field imputation (in-place)
"""
function imputevalues!(mvals, imputer::NamedTuple, k::Symbol)
	Impute.impute!(mvals, imputer[k])
end

"""
$(TYPEDSIGNATURES)
Imputation for a columntable of vectors (inner imputation only).
"""
function imputevec(bars::T, τ, imputer; idxkey::Symbol)::T where {T<:NamedTuple}
	newidx, holes = fillin(getfield(bars, idxkey), τ)

	newvals = Vector[]
	for k in keys(bars)
		if k == idxkey
			vals = newidx
		else
			mvals = holedvalues(getfield(bars, k), holes)
			vals = imputevalues!(mvals, imputer, k) |> disallowmissing
		end
		push!(newvals, vals)
	end
	NamedTuple{keys(bars)}(Tuple(newvals))
end

"""
$(TYPEDSIGNATURES)
Imputation for a columntable of vectors (inner imputation only).
"""
function imputevec(bars::T, τ, ::Nothing, imputer; idxkey)::T where {T<:NamedTuple}
	imputevec(bars, τ, imputer; idxkey=idxkey)
end

"""
$(TYPEDSIGNATURES)
Imputation for a columntable of vectors (inner and outer imputation).
XXX - Untested
"""
function imputevec(bars::T, τ, to::Pair, imputer; idxkey::Symbol)::T where {T<:NamedTuple}
	newidx, holes = fillin(getfield(bars, idxkey), τ)
	newidx, holesout = fillout(newidx, τ, to)

	newvals = Vector[]
	for k in keys(bars)
		if k == idxkey
			vals = newidx
		else
			mvals = holedvalues(getfield(bars, k), holes, holesout)
			vals = imputedvalues(mvals, imputer, k) |> disallowmissing
		end
		push!(newvals, vals)
	end
	NamedTuple{keys(bars)}(Tuple(newvals))
end

"""
$(TYPEDSIGNATURES)
StructVector imputation.
Assumes single index bar type
XXX - using a non-nothing `to` is untested.
"""
function impute(bars::StructVector{T}, τ, to=nothing, imputer=imputer(T)) where {T<:SeriesBar}
	isempty(bars) && return bars
	nt = StructArrays.components(bars)
	imputevec(nt, τ, to, imputer; idxkey=index(T)) |> StructVector{T}
end

"""
$(TYPEDSIGNATURES)
Imputation.
Assumes single index bar type
"""
function impute(bars::StructVector{T}, τ, method::Symbol, to=nothing; rng=Random.default_rng()) where {T<:SeriesBar}
	if method == :locf
		imp = Impute.LOCF()
	elseif method == :sub
		imp = Impute.Substitute(; statistic=Impute.defaultstats)
	elseif method == :srs
		imp = Impute.SRS(; rng=rng)
	else
		imp = imputer(T)
	end
	impute(bars, τ, to, imp)
end



# """
# $(TYPEDSIGNATURES)
# Expand outer index range.
# Assumes single index bar type.
# XXX - Deprecated
# """
# function expandouter(sv::StructVector{T}, τ, to::Pair; idxkey) where {T<:NamedTuple}
# 	idx = StructArrays.component(sv, idxkey)
# 	if first(to) < first(idx)
# 		newidx = index_range(first(to)=>first(idx), τ; excl_f=false)
# 		sv = vcat(emptysa(T, idxkey=>newidx), sv)
# 	end
# 	if last(idx) < last(to)
# 		newidx = index_range(last(idx)=>last(to), τ; excl_l=false)
# 		sv = vcat(sv, emptysa(T, idxkey=>newidx))
# 	end
# 	sv
# end

# """
# $(TYPEDSIGNATURES)
# Do not expand outer index range. Used for dispatch.
# XXX - Deprecated
# """
# expandouter(sa::StructArray, ::Any, ::Nothing; kwargs...) = sa

# """
# $(TYPEDSIGNATURES)
# XXX - Deprecated
# """
# function impute_old(bars::StructVector{T}, τ, to, imputer=imputer(T); idxkey=index(T)) where {T<:SeriesBar}
# 	sa = imputevec(bars, τ, nothing, imputer; idxkey=idxkey)
# 	sa = expandouter(sa, τ, to; idxkey=idxkey)
# 	sa = Impute.impute(sa, imputer)
# 	disallowmiss(T, sa)
# end

# """
# $(TYPEDSIGNATURES)
# XXX - Deprecated
# """
# function impute_old(bars::StructVector{T}, τ, method::Symbol, to=nothing; idxkey=index(T), rng=Random.default_rng()) where {T<:SeriesBar}
# 	if method == :locf
# 		imp = Impute.LOCF()
# 	elseif method == :sub
# 		imp = Impute.Substitute(; statistic=Impute.defaultstats)
# 	elseif method == :srs
# 		imp = Impute.SRS(; rng=rng)
# 	else
# 		imp = imputer(T)
# 	end
# 	impute_old(bars, τ, to, imp; idxkey=idxkey)
# end

# struct LocalSRS{R<:AbstractRNG} <: Impute.Imputor
# 	rng::R
# 	n::Int
# end

# LocalSRS(; rng=Random.default_rng(), n=6) = LocalSRS(rng, n)

# function _impute!(data::AbstractVector{Union{T, Missing}}, imp::LocalSRS) where T
# 	obs_values = collect(skipmissing(data))
# 	if !isempty(obs_values)
# 		for i in eachindex(data)
# 			if ismissing(data[i])
# 				flim = max(firstindex(obs_values),i-(imp.n÷2))
# 				llim = min(lastindex(obs_values),i+(imp.n÷2))
# 				data[i] = rand(imp.rng, obs_values[flim, llim])
# 			end
# 		end
# 	end

# 	return data
# end

"""
$(TYPEDSIGNATURES)
Display method for `StructVector{<:Bar}` table.
"""
function Base.show(io::IO, ::MIME"text/plain", bars::StructArrays.StructVector{T}; ttb=text_table_borders__ascii_dots) where {T<:Bar}
	title = @sprintf "%.3g %s" length(bars) nameof(T)
	tf = TextTableFormat(borders=ttb)
	pretty_table(io, StructArrays.components(bars);
		backend=:text,
		table_format=tf,
		title=title,
		alignment=:l,
		vertical_crop_mode=:middle,
		show_omitted_cell_summary=false,
	)
end

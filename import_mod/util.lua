local import_mod = ...

function import_mod.get_mapblock_pos(pos)
	return vector.floor( vector.divide(pos, 16))
end

function import_mod.get_chunkpos(pos)
	local mapblock_pos = import_mod.get_mapblock_pos(pos)
	local aligned_mapblock_pos = vector.add(mapblock_pos, 2)
	return vector.floor( vector.divide(aligned_mapblock_pos, 5) )
end
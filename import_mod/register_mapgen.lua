local import_mod = ...

local function get_mapblock_pos(pos)
	return vector.floor( vector.divide(pos, 16))
end

local function get_chunkpos(pos)
	local mapblock_pos = get_mapblock_pos(pos)
	local aligned_mapblock_pos = vector.add(mapblock_pos, 2)
	return vector.floor( vector.divide(aligned_mapblock_pos, 5) )
end

function import_mod.register_mapgen(manifest)
	minetest.register_on_generated(function(minp)
		import_mod.load_chunk(get_chunkpos(minp), manifest)
	end)
end

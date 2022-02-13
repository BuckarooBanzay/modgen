---------
-- common utility functions

-- copy environment to local scope
local env = ...

------
-- Mapblock position
-- @field x the x position in mapblocks
-- @field y the y position in mapblocks
-- @field z the z position in mapblocks
-- @table mapblock_pos


function modgen.sort_pos(pos1, pos2)
	pos1 = {x=pos1.x, y=pos1.y, z=pos1.z}
	pos2 = {x=pos2.x, y=pos2.y, z=pos2.z}
	if pos1.x > pos2.x then
		pos2.x, pos1.x = pos1.x, pos2.x
	end
	if pos1.y > pos2.y then
		pos2.y, pos1.y = pos1.y, pos2.y
	end
	if pos1.z > pos2.z then
		pos2.z, pos1.z = pos1.z, pos2.z
	end
	return pos1, pos2
end

--- returns the chunk position from a node position
-- @param pos the node-position
-- @return the chunk position
function modgen.get_chunkpos(pos)
	local mapblock_pos = modgen.get_mapblock(pos)
	local aligned_mapblock_pos = vector.add(mapblock_pos, 2)
	return vector.floor( vector.divide(aligned_mapblock_pos, 5) )
end

--- returns the lower and upper chunk bounds for the given position
-- @param pos the node-position
function modgen.get_chunk_bounds(pos)
	local chunk_pos = modgen.get_chunkpos(pos)
	local mapblock_min, mapblock_max = modgen.get_mapblock_bounds_from_chunk(chunk_pos)
	local min = modgen.get_mapblock_bounds(mapblock_min)
	local _, max = modgen.get_mapblock_bounds(mapblock_max)
	return min, max
end

--- returns the chunk_bounds from a mapblock-position
-- @param mapblock_pos @{mapblock_pos}
-- @return the lower node-position
-- @return the upper node-position
function modgen.get_chunk_bounds_from_mapblock(mapblock_pos)
	local min = vector.multiply(mapblock_pos, 16)
	local max = vector.add(min, 15)
	return min, max
end

--- calculates the mapblock position from a node position
-- @param pos the node-position
-- @return @{mapblock_pos} the mapblock position
function modgen.get_mapblock(pos)
	return vector.floor( vector.divide(pos, 16))
end

function modgen.get_mapblock_bounds(pos)
	local mapblock = modgen.get_mapblock(pos)
	return modgen.get_mapblock_bounds_from_mapblock(mapblock)
end

function modgen.get_mapblock_bounds_from_chunk(chunk_pos)
	local min = vector.subtract( vector.multiply(chunk_pos, 5), 2)
	local max = vector.add(min, 4)
	return min, max
end


function modgen.get_mapblock_bounds_from_mapblock(mapblock)
	local min = vector.multiply(mapblock, 16)
	local max = vector.add(min, 15)
	return min, max
end

function modgen.get_chunk_filename(chunk_pos, create_dirs)
	local map_dir = modgen.export_path .. "/map"

	if create_dirs then
		minetest.mkdir(map_dir)
	end

	return map_dir .. "/chunk_" ..
		chunk_pos.x .. "_" .. chunk_pos.y .. "_" .. chunk_pos.z .. ".bin"
end

function modgen.remove_chunk(chunk_pos)
	env.os.remove(modgen.get_chunk_filename(chunk_pos))
end

--- Creates a unique identifier
-- see: https://gist.github.com/jrus/3197011
-- @return the uuid
function modgen.create_uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

--- Returns the filesize of the specified file
-- @param filename the filename
-- @return the size in bytes or 0 if not found
function modgen.get_filesize(filename)
	local file = env.io.open(filename,"r")
	if file then
		local size = file:seek("end")
		file:close()
		return size
	else
		return 0
	end
end

--- copies a files from the source to the target
-- @param src the source file
-- @param target the target file
function modgen.copyfile(src, target)
	local infile = env.io.open(src, "r")
	local instr = infile:read("*a")
	infile:close()

	if not instr then
		return
	end

	local outfile, err = env.io.open(target, "w")
	if not outfile then
		error("File " .. target .. " could not be opened for writing! " .. err or "")
	end
	outfile:write(instr)
	outfile:close()

	return #instr
end

--- copies the modgen-import skeleton to the specified patch
-- @param path the path to use
function modgen.write_mod_files(path)
	local basepath = modgen.MOD_PATH .. "/import_mod/"
	local files = minetest.get_dir_list(basepath, false)
	for _, filename in ipairs(files) do
		modgen.copyfile(basepath .. filename, path .. "/" .. filename)
	end
end

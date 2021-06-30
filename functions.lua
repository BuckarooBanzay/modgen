---------
-- common utility functions

-- copy environment to local scope
local env = ...

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

--- calculates the mapblock position from a node position
-- @param pos the node-position
-- @return the mapblock position
function modgen.get_mapblock(pos)
	return vector.floor( vector.divide(pos, 16))
end

function modgen.get_mapblock_bounds(pos)
	local mapblock = modgen.get_mapblock(pos)
	return modgen.get_mapblock_bounds_from_mapblock(mapblock)
end


function modgen.get_mapblock_bounds_from_mapblock(mapblock)
	local min = vector.multiply(mapblock, 16)
	local max = vector.add(min, 15)
	return min, max
end

--- Converts an integer number to two bytes
-- @param i the integer number
-- @return a table with to bytes/chars
function modgen.int_to_bytes(i)
	local x =i + 32768
	local h = math.floor(x/256) % 256;
	local l = math.floor(x % 256);
	return(string.char(h, l));
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

--- Deletes a mapblock file
-- @param filename filename the filename of the mapblock
function modgen.delete_mapblock(filename)
	local size = modgen.get_filesize(filename)
	if size > 0 then
		-- update size
		modgen.manifest.size = modgen.manifest.size - size
		modgen.manifest.mapblock_count = modgen.manifest.mapblock_count - 1
	end

	if env.os.remove then
		env.os.remove(filename)
	end
end

--- Deletes a metadata mapblock file
-- @param filename filename the filename of the mapblock
function modgen.delete_metadata(filename)
	local size = modgen.get_filesize(filename)
	if size > 0 then
		-- update size
		modgen.manifest.size = modgen.manifest.size - size
		modgen.manifest.metadata_count = modgen.manifest.metadata_count - 1
	end

	if env.os.remove then
		env.os.remove(filename)
	end
end

--- writes the mapblock data to the specified filename
-- @param filename the filename to use
-- @param node_ids the nodeid data as table
-- @param param1 the param1 data as table
-- @param param2 the param2 data as table
-- @return the bytes written to disk
function modgen.write_mapblock(filename, node_ids, param1, param2)
	local previous_size = modgen.get_filesize(filename)

	local file = env.io.open(filename,"wb")
	local data = ""

	assert(#node_ids == 4096) -- entire mapblock
	assert(#node_ids == #param1)
	assert(#node_ids == #param2)

	for i=1,#node_ids do
		data = data .. modgen.int_to_bytes(node_ids[i])
	end
	for i=1,#param1 do
		data = data .. string.char(param1[i])
	end
	for i=1,#param2 do
		data = data .. string.char(param2[i])
	end

	local compressed_data = minetest.compress(data, "deflate")
	local new_size = #compressed_data
	file:write(compressed_data)

	if previous_size == 0 then
		-- increment mapblock count
		modgen.manifest.mapblock_count = modgen.manifest.mapblock_count + 1
	end

	-- update size
	modgen.manifest.size = modgen.manifest.size + new_size - previous_size

	if file and file:close() then
		return #compressed_data
	else
		error("write to '" .. filename .. "' failed!")
	end
end

--- writes the mapblock metadatadata to the specified filename
-- @param filename the filename to use
-- @param metadata the metadata as table
-- @return the bytes written to disk
function modgen.write_metadata(filename, metadata)
	local previous_size = modgen.get_filesize(filename)

	local file = env.io.open(filename,"wb")
	local json = minetest.write_json(metadata)

	local compressed_metadata = minetest.compress(json, "deflate")
	local new_size = #compressed_metadata
	file:write(compressed_metadata)

	if previous_size == 0 then
		-- increment metadata count
		modgen.manifest.metadata_count = modgen.manifest.metadata_count + 1
	end

	-- update size
	modgen.manifest.size = modgen.manifest.size + new_size - previous_size

	if file and file:close() then
		return #compressed_metadata
	else
		error("write to '" .. filename .. "' failed!")
	end
end

--- Writes the manifest to a file in json format
-- @param filename the filename to write to
function modgen.write_manifest(filename)
	local file = env.io.open(filename,"w")
	local json = minetest.write_json(modgen.manifest, true)

	file:write(json)
	file:close()
end

--- Reads a minfest from a json file
-- @param filename the filename of the manifest
function modgen.read_manifest(filename)
	local infile = io.open(filename, "r")
	if not infile then
		-- no manifest file found
		return
	end

	local instr = infile:read("*a")
	infile:close()

	if instr then
		-- use existing manifest
		modgen.manifest = minetest.parse_json(instr)
	end
end

--- returns the mapblock filename
-- @param prefix the directory or file-prefix to use
-- @param pos the mapblock position as vector
-- @param suffix the filename suffix to use
-- @param create_dirs create intermediate directories or not (read-only)
-- @return the resulting filename
function modgen.get_mapblock_name(prefix, pos, suffix, create_dirs)
	local xstride_dir = prefix .. "/" .. pos.x
	if create_dirs then
		if env.os.execute then
			-- call os function for mkdir
			-- TODO: portability
			env.os.execute("mkdir -p " .. xstride_dir)
		else
			minetest.mkdir(xstride_dir)
		end
	end
	return xstride_dir .. "/mapblock_" .. pos.y .. "_" .. pos.z .. "." .. suffix
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

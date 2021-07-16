---------
-- mapblock/metadata read/write functions

-- copy environment to local scope
local env = ...


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
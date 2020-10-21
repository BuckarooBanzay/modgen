
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

function modgen.get_mapblock_bounds(pos)
	local mapblock = vector.floor( vector.divide(pos, 16))
	return modgen.get_mapblock_bounds_from_mapblock(mapblock)
end


function modgen.get_mapblock_bounds_from_mapblock(mapblock)
	local min = vector.multiply(mapblock, 16)
  local max = vector.add(min, 15)
	return min, max
end

function modgen.int_to_bytes(i)
	local x =i + 32768
	local h = math.floor(x/256) % 256;
	local l = math.floor(x % 256);
	return(string.char(h, l));
end

function modgen.write_mapblock(filename, node_ids, param1, param2)
  local file = io.open(filename,"wb")
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

  file:write(minetest.compress(data, "deflate"))

  if file and file:close() then
    return
  else
    error("write to '" .. filename .. "' failed!")
  end
end

function modgen.write_metadata(filename, metadata)
	local file = io.open(filename,"wb")
	local json = minetest.write_json(metadata)

	file:write(minetest.compress(json, "deflate"))
	file:close()
end

function modgen.write_manifest(filename, ctx)
	local file = io.open(filename,"w")
	local json = minetest.write_json({
		size_mapblocks = ctx.size_mapblocks,
		spawn_pos = ctx.spawn_pos,
		total_parts = ctx.total_parts,
		node_mapping = ctx.node_mapping
	})

	file:write(json)
	file:close()
end

function modgen.get_mapblock_name(prefix, pos, suffix)
	return prefix .. "mapblock-" ..
		pos.x .. "_" .. pos.y .. "_" .. pos.z .. "." .. suffix
end

function modgen.copyfile(src, target)
	local infile = io.open(src, "r")
	local instr = infile:read("*a")
	infile:close()

	if not instr then
		return
	end

	local outfile, err = io.open(target, "w")
	if not outfile then
		error("File " .. target .. " could not be opened for writing! " .. err or "")
	end
	outfile:write(instr)
	outfile:close()

	return #instr
end


function modgen.write_mod_files(path)
	local files = {
		"config.lua",
		"deserialize.lua",
		"read_manifest.lua",
		"init.lua",
		"mapgen.lua",
		"spawn.lua"
	}

	for _, filename in ipairs(files) do
		modgen.copyfile(modgen.MOD_PATH .. "/import_mod/" .. filename, path .. "/" .. filename)
	end
end

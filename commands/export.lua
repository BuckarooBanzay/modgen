
minetest.register_chatcommand("export", {
	func = function(name)

    local pos1 = block2mod.get_pos(1, name)
    local pos2 = block2mod.get_pos(2, name)

    if not pos1 or not pos2 then
      return false, "you need to set /pos1 and /pos2 first!"
    end

		local total_parts =
			math.ceil(math.abs(pos1.x - pos2.x) / block2mod.PART_LENGTH) *
			math.ceil(math.abs(pos1.y - pos2.y) / block2mod.PART_LENGTH) *
			math.ceil(math.abs(pos1.z - pos2.z) / block2mod.PART_LENGTH)

			pos1, pos2 = block2mod.sort_pos(pos1, pos2)

    local ctx = {
			current_pos = { x=pos1.x, y=pos1.y, z=pos1.z },
			pos1 = pos1,
			pos2 = pos2,
			total_parts = total_parts,
			node_mapping = {},
			schemapath = block2mod.export_path,
			playername = name,
			current_part = 0
		}

		minetest.mkdir(ctx.schemapath)

		minetest.after(0, block2mod.worker, ctx)

		return true, "Export started!"
  end
})

local function int_to_bytes(i)
	local x =i + 32768
	local h = math.floor(x/256) % 256;
	local l = math.floor(x % 256);
	return(string.char(h, l));
end

local function write_mapblock(node_ids, param1, param2, filename)
  local file = io.open(filename,"wb")
  local data = ""
	assert(#node_ids == #param1)
	assert(#node_ids == #param2)

  for i=1,#node_ids do
    data = data .. int_to_bytes(node_ids[i])
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

local function write_metadata(filename, metadata)
	local file = io.open(filename,"wb")
	local json = minetest.write_json(metadata)

	file:write(minetest.compress(json, "deflate"))
	file:close()
end

local function write_manifest(filename, ctx)
	local file = io.open(filename,"w")
	local json = minetest.write_json({
		pos1 = ctx.pos1,
		pos2 = ctx.pos1,
		total_parts = ctx.total_parts,
		node_mapping = ctx.node_mapping
	})

	file:write(json)
	file:close()
end

function block2mod.worker(ctx)

	-- shift position
	ctx.current_pos = block2mod.iterator_next(ctx.pos1, ctx.pos2, ctx.current_pos)
	ctx.current_part = ctx.current_part + 1
  ctx.progress_percent = math.floor(ctx.current_part / ctx.total_parts * 100 * 10) / 10

	if not ctx.current_pos then
		-- done
		write_manifest(ctx.schemapath .. "/manifest.json", ctx)
		minetest.chat_send_player(ctx.playername, "[block2mod] Export done")
		return
	end

	minetest.chat_send_player(ctx.playername, "[block2mod] Export pos: " .. minetest.pos_to_string(ctx.current_pos) ..
    " Progress: " .. ctx.progress_percent .. "% (" .. ctx.current_part .. "/" .. ctx.total_parts .. ")")

	local pos2 = vector.add(ctx.current_pos, block2mod.PART_LENGTH - 1)
	pos2.x = math.min(pos2.x, ctx.pos2.x)
  pos2.y = math.min(pos2.y, ctx.pos2.y)
  pos2.z = math.min(pos2.z, ctx.pos2.z)

	local relative_pos = vector.subtract(ctx.current_pos, ctx.pos1)
  local data = block2mod.serialize_part(ctx.current_pos, pos2)

	-- populate node_mapping and check if the mapblock contains only air
	local only_air = true
	for name, id in pairs(data.node_mapping) do
		ctx.node_mapping[name] = id
		if name ~= "air" then
			-- mapblock is not empty
			only_air = false
		end
	end

	if only_air then
		-- nothing to see here
		minetest.after(0.2, block2mod.worker, ctx)

	else
		-- write mapblock to disk
		write_mapblock(
			data.node_ids, data.param1, data.param2,
			ctx.schemapath .. "/mapblock-" .. relative_pos.x .. "_" .. relative_pos.y .. "_" .. relative_pos.z .. ".bin"
		)

		-- write metadata if available
		if data.has_metadata then
			write_metadata(
				ctx.schemapath .. "/mapblock-" .. relative_pos.x .. "_" .. relative_pos.y .. "_" .. relative_pos.z .. ".meta.bin",
				data.metadata
			)
		end

		minetest.after(0.5, block2mod.worker, ctx)
	end

end

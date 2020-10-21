
minetest.register_chatcommand("export", {
	func = function(name)

    local pos1 = modgen.get_pos(1, name)
    local pos2 = modgen.get_pos(2, name)

    if not pos1 or not pos2 then
      return false, "you need to set /pos1 and /pos2 first!"
    end

		-- sort by lower position first
		pos1, pos2 = modgen.sort_pos(pos1, pos2)

		-- get mapblock edges
		local min = modgen.get_mapblock_bounds(pos1)
	  local _, max = modgen.get_mapblock_bounds(pos2)

		-- get player position for spawn-point
		local player = minetest.get_player_by_name(name)
		local spawn_pos = vector.floor(vector.subtract(player:get_pos(), min))

		local size_mapblocks = {
			x = math.ceil(math.abs(min.x - max.x) / modgen.PART_LENGTH),
			y = math.ceil(math.abs(min.y - max.y) / modgen.PART_LENGTH),
			z = math.ceil(math.abs(min.z - max.z) / modgen.PART_LENGTH)
		}

		local total_parts = size_mapblocks.x * size_mapblocks.y * size_mapblocks.z

    local ctx = {
			current_pos = nil,
			pos1 = min,
			pos2 = max,
			spawn_pos = spawn_pos,
			size_mapblocks = size_mapblocks,
			total_parts = total_parts,
			node_mapping = {},
			schemapath = modgen.export_path,
			playername = name,
			current_part = 0
		}

		minetest.mkdir(ctx.schemapath)
		minetest.mkdir(ctx.schemapath .. "/map")

		minetest.after(0, modgen.worker, ctx)

		return true, "Export started!"
  end
})


function modgen.worker(ctx)

	-- shift position
	ctx.current_pos = modgen.iterator_next(ctx.pos1, ctx.pos2, ctx.current_pos)
	ctx.current_part = ctx.current_part + 1
  ctx.progress_percent = math.floor(ctx.current_part / ctx.total_parts * 100 * 10) / 10

	if not ctx.current_pos then
		-- done, write manifest, config and lua code files
		modgen.write_manifest(ctx.schemapath .. "/manifest.json", ctx)
		modgen.write_mod_files(ctx.schemapath)
		minetest.chat_send_player(ctx.playername, "[modgen] Export done")
		return
	end

	minetest.chat_send_player(ctx.playername, "[modgen] Export pos: " .. minetest.pos_to_string(ctx.current_pos) ..
    " Progress: " .. ctx.progress_percent .. "% (" .. ctx.current_part .. "/" .. ctx.total_parts .. ")")

	local relative_pos = vector.subtract(ctx.current_pos, ctx.pos1)
  local data = modgen.serialize_part(ctx.current_pos)

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
		minetest.after(0.1, modgen.worker, ctx)

	else
		-- write mapblock to disk
		modgen.write_mapblock(
			modgen.get_mapblock_name(ctx.schemapath .. "/map/", relative_pos, "bin"),
			data.node_ids, data.param1, data.param2
		)

		-- write metadata if available
		if data.has_metadata then
			modgen.write_metadata(
				modgen.get_mapblock_name(ctx.schemapath .. "/map/", relative_pos, "meta.bin"),
				data.metadata
			)
		end

		minetest.after(0.1, modgen.worker, ctx)
	end

end

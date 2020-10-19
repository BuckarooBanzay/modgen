
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


function block2mod.worker(ctx)

	-- shift position
	ctx.current_pos = block2mod.iterator_next(ctx.pos1, ctx.pos2, ctx.current_pos)
	ctx.current_part = ctx.current_part + 1
  ctx.progress_percent = math.floor(ctx.current_part / ctx.total_parts * 100 * 10) / 10

	if not ctx.current_pos then
		-- done
		block2mod.write_manifest(ctx.schemapath .. "/manifest.json", ctx)
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
		block2mod.write_mapblock(
			block2mod.get_mapblock_name(relative_pos, "bin"),
			data.node_ids, data.param1, data.param2
		)

		-- write metadata if available
		if data.has_metadata then
			block2mod.write_metadata(
				block2mod.get_mapblock_name(relative_pos, "meta.bin"),
				data.metadata
			)
		end

		minetest.after(0.5, block2mod.worker, ctx)
	end

end

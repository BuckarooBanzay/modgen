
minetest.register_chatcommand("export", {
	func = function(name, param)

		local schemaname = param or "block2mod-export"

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
			schemaname = schemaname,
			current_part = 0
		}

		minetest.after(0, block2mod.worker, ctx)

		return true
  end
})


function block2mod.worker(ctx)

	-- shift position
	ctx.current_pos = block2mod.iterator_next(ctx.pos1, ctx.pos2, ctx.current_pos)
	ctx.current_part = ctx.current_part + 1
  ctx.progress_percent = math.floor(ctx.current_part / ctx.total_parts * 100 * 10) / 10

	if not ctx.currentpos then
		-- done
		return
	end

	minetest.chat_send_player(ctx.playername, "[block2mod] Upload pos: " .. minetest.pos_to_string(ctx.current_pos) ..
    " Progress: " .. ctx.progress_percent .. "% (" .. ctx.current_part .. "/" .. ctx.total_parts .. ")")

	minetest.after(0.5, block2mod.worker, ctx)

end

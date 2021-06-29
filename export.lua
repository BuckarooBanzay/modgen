---------
-- export functions

--- exports the specified region to the mapgen-mod
-- @param name the playername to report infos to
-- @param pos1 the first position of the export region
-- @param pos2 the second position of the export region
-- @param fast if true: export a mapblock every server-step
-- @param verbose if true: report detailed stats while exporting
function modgen.export(name, pos1, pos2, fast, verbose)
	-- get mapblock edges
	local min = modgen.get_mapblock_bounds(pos1)
	local _, max = modgen.get_mapblock_bounds(pos2)

	local size_mapblocks = {
		x = math.ceil(math.abs(min.x - max.x) / modgen.PART_LENGTH),
		y = math.ceil(math.abs(min.y - max.y) / modgen.PART_LENGTH),
		z = math.ceil(math.abs(min.z - max.z) / modgen.PART_LENGTH)
	}

	local total_parts = size_mapblocks.x * size_mapblocks.y * size_mapblocks.z
	local delay = 0.1

	if fast then
		-- fast mode, no delay
		delay = 0
	end

	local ctx = {
		current_pos = nil,
		pos1 = min,
		pos2 = max,
		size_mapblocks = size_mapblocks,
		total_parts = total_parts,
		schemapath = modgen.export_path,
		playername = name,
		current_part = 0,
		delay = delay,
		verbose = verbose,
		-- bytes written to disk
		bytes = 0
	}

	if not modgen.enable_inplace_save then
		-- create directories if not saving in-place
		minetest.mkdir(ctx.schemapath)
		minetest.mkdir(ctx.schemapath .. "/map")
	end

	-- initial call to worker
	modgen.worker(ctx)
end


function modgen.worker(ctx)

	-- shift position
	ctx.current_pos = modgen.iterator_next(ctx.pos1, ctx.pos2, ctx.current_pos)
	ctx.current_part = ctx.current_part + 1
	ctx.progress_percent = math.floor(ctx.current_part / ctx.total_parts * 100 * 10) / 10

	if not ctx.current_pos then
		-- done, write manifest, config and lua code files
		modgen.write_manifest(ctx.schemapath .. "/manifest.json")
		modgen.write_mod_files(ctx.schemapath)
		if ctx.verbose then
			minetest.chat_send_player(ctx.playername, "[modgen] Export done with " .. ctx.bytes .. " bytes")
		end
		return
	end

	local mapblock_pos = modgen.get_mapblock(ctx.current_pos)
	local data = modgen.serialize_part(ctx.current_pos)

	if ctx.verbose then
		minetest.chat_send_player(ctx.playername, "[modgen] Export mapblock: " .. minetest.pos_to_string(mapblock_pos) ..
		" Progress: " .. ctx.progress_percent .. "% (" .. ctx.current_part .. "/" .. ctx.total_parts .. ")")
	end

	local mapblock_filename = modgen.get_mapblock_name(ctx.schemapath .. "/map/", mapblock_pos, "bin", true)
	local mapblock_meta_filename = modgen.get_mapblock_name(ctx.schemapath .. "/map/", mapblock_pos, "meta.bin", true)

	if data.only_air then
		-- remove mapblock if it exists
		modgen.delete_mapblock(mapblock_filename)
		modgen.delete_metadata(mapblock_meta_filename)
		minetest.after(ctx.delay, modgen.worker, ctx)

	else
		-- write mapblock to disk
		local count = modgen.write_mapblock(
			mapblock_filename,
			data.node_ids, data.param1, data.param2
		)

		-- write metadata if available
		if data.has_metadata then
			count = count + modgen.write_metadata(
				mapblock_meta_filename,
				data.metadata
			)
		else
			-- remove metadata if it exists
			modgen.delete_metadata(mapblock_meta_filename)
		end

		-- increment byte count
		ctx.bytes = ctx.bytes + count
		minetest.after(ctx.delay, modgen.worker, ctx)
	end

end

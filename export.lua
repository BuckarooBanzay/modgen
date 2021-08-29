---------
-- export functions

--- Export worker function, triggered async by the main export function
-- @param ctx the current export context
local function worker(ctx)

	-- shift position
	ctx.current_pos = modgen.iterator_next(ctx.pos1, ctx.pos2, ctx.current_pos)
	ctx.current_part = ctx.current_part + 1
	ctx.progress_percent = math.floor(ctx.current_part / ctx.total_parts * 100 * 10) / 10

	if not ctx.current_pos then
		-- done, write manifest and lua code files
		modgen.manifest.size = modgen.manifest.size + ctx.bytes
		modgen.write_manifest(modgen.manifest, ctx.schemapath .. "/manifest.json")
		modgen.write_mod_files(ctx.schemapath)
		if ctx.verbose then
			minetest.chat_send_player(ctx.playername, "[modgen] Export done with " .. ctx.bytes .. " bytes")
		end
		if ctx.callback then
			-- execute optional callback
			ctx.callback({
				bytes = ctx.bytes
			})
		end
		return
	end

	local filename = modgen.get_chunk_filename(ctx.current_pos, true)

	local existing_filesize = modgen.get_filesize(filename)
	local count = modgen.export_chunk(ctx.current_pos, filename)

	if existing_filesize > 0 and count == 0 then
		-- chunk removed
		modgen.remove_chunk(ctx.current_pos)

		-- decrement byte and chunk count
		ctx.bytes = ctx.bytes - existing_filesize
		modgen.manifest.chunks = modgen.manifest.chunks + 1
	elseif existing_filesize == 0 and count > 0 then
		-- new chunk
		modgen.manifest.chunks = modgen.manifest.chunks + 1

		-- increment byte count
		ctx.bytes = ctx.bytes + count
	else
		-- contents modified

		-- increment byte count
		ctx.bytes = ctx.bytes + count
	end


	minetest.after(ctx.delay, worker, ctx)
end


--- exports the specified region to the mapgen-mod
-- @param name the playername to report infos to
-- @param pos1 the first position of the export region
-- @param pos2 the second position of the export region
-- @param fast if true: export a chunk every server-step
-- @param verbose if true: report detailed stats while exporting
-- @param callback[opt] optional callback function on completion
function modgen.export(name, pos1, pos2, fast, verbose, callback)
	-- get chunk edges
	pos1, pos2 = modgen.sort_pos(pos1, pos2)
	local min = modgen.get_chunkpos(pos1)
	local max = modgen.get_chunkpos(pos2)

	local size_chunks = {
		x = math.ceil(math.abs(min.x - max.x) / modgen.CHUNK_LENGTH),
		y = math.ceil(math.abs(min.y - max.y) / modgen.CHUNK_LENGTH),
		z = math.ceil(math.abs(min.z - max.z) / modgen.CHUNK_LENGTH)
	}

	local total_parts = size_chunks.x * size_chunks.y * size_chunks.z
	local delay = 0.1

	if fast then
		-- fast mode, no delay
		delay = 0
	end

	local ctx = {
		current_pos = nil,
		pos1 = min,
		pos2 = max,
		total_parts = total_parts,
		schemapath = modgen.export_path,
		playername = name,
		current_part = 0,
		delay = delay,
		verbose = verbose,
		-- bytes written to disk
		bytes = 0,
		callback = callback
	}

	if not modgen.enable_inplace_save then
		-- create directories if not saving in-place
		minetest.mkdir(ctx.schemapath)
		minetest.mkdir(ctx.schemapath .. "/map")
	end

	-- initial call to worker
	worker(ctx)
end

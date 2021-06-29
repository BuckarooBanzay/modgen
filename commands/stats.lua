

minetest.register_chatcommand("modgen_stats", {
	func = function()
		if not modgen.import_manifest then
			return true, "Nothing to report"
		end

		return true, "Size: " .. modgen.import_manifest.size .. " bytes, " ..
			" Mapblocks: " .. modgen.import_manifest.mapblock_count ..
			" Metadata-blocks: " .. modgen.import_manifest.metadata_count
	end
})

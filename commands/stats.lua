

minetest.register_chatcommand("modgen_stats", {
	func = function()
		if not modgen.manifest then
			return true, "Nothing to report"
		end

		return true, "Size: " .. modgen.manifest.size .. " bytes, " ..
			" Mapblocks: " .. modgen.manifest.mapblock_count ..
			" Metadata-blocks: " .. modgen.manifest.metadata_count
	end
})

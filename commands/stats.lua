

minetest.register_chatcommand("modgen_stats", {
	func = function()
		if not modgen.manifest then
			return true, "Nothing to report"
		end

		return true, "Size: " .. modgen.manifest.size .. " bytes, " ..
			" Chunks: " .. modgen.manifest.chunks
	end
})

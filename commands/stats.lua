

minetest.register_chatcommand("modgen_stats", {
	func = function()
		if not modgen.manifest then
			return true, "Nothing to report"
		end

		return true, "Size: " .. modgen.pretty_size(modgen.manifest.size) .. ", " ..
			" Chunks: " .. modgen.manifest.chunks
	end
})

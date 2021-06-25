

minetest.register_chatcommand("autosave", {
	func = function(_, params)
		if params == "on" then
			modgen.autosave = true
			return true, "Autosave enabled"
		else
			modgen.autosave = false
			return true, "Autosave disabled"
		end
	end
})

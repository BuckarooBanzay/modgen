

minetest.register_chatcommand("autosave", {
	func = function(name, params)
		if params == "on" then
			modgen.set_autosave(name, true)
			return true, "Autosave enabled"
		else
			modgen.set_autosave(name, false)
			return true, "Autosave disabled"
		end
	end
})

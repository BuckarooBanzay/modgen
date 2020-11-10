

-- playername -> true
local player_autosaves = {}

minetest.register_chatcommand("autosave", {
	func = function(name, params)
		if params == "on" then
			player_autosaves[name] = true
			return true, "Autosave enabled"
		else
			player_autosaves[name] = nil
			return true, "Autosave disabled"
		end
	end
})

local function autosave()
	for _, player in ipairs(minetest.get_connected_players()) do
		local playername = player:get_player_name()
		if player_autosaves[playername] then
			local ppos = player:get_pos()
			local pos1 = vector.subtract(ppos, 16)
			local pos2 = vector.add(ppos, 16)

			modgen.export(playername, pos1, pos2, true, false)
		end
	end

	minetest.after(2, autosave)
end

minetest.after(1, autosave)

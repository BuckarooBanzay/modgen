local modname = minetest.get_current_modname()
local MP = minetest.get_modpath(modname)

return function()
	local infile = io.open(MP .. "/manifest.json", "r")
	local instr = infile:read("*a")
	infile:close()

  return minetest.parse_json(instr or "{}")
end

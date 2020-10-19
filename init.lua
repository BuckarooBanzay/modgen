local MP = minetest.get_modpath("block2mod")

-- mod namespace
block2mod = {
  pos1 = {},
  pos2 = {},
  PART_LENGTH = 16
}

dofile(MP.."/functions.lua")
dofile(MP.."/markers.lua")
dofile(MP.."/serialize.lua")
dofile(MP.."/iterator_next.lua")
dofile(MP.."/commands/export.lua")
dofile(MP.."/commands/pos.lua")

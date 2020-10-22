
-- used as callback from already exported mods
function modgen.register_import_mod(manifest)

  -- set current map export limits to modgen.pos1/pos2
  -- this allows re-exporting a map 1:1 with just the /export command
  minetest.after(0, function()
    local origin = { x=0, y=0, z=0 }
    modgen.set_pos(1, "singleplayer", origin)
    modgen.set_pos(2, "singleplayer", vector.multiply(manifest.size_mapblocks, 16))
  end)

end

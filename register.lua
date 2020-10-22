
-- used as callback from already exported mods
function modgen.register_import_mod(manifest)

  -- set current map export limits to modgen.pos1/pos2
  -- this allows re-exporting a map 1:1 with just the /export command
  minetest.after(0, function()
    modgen.set_pos(1, "singleplayer", manifest.pos1)
    modgen.set_pos(2, "singleplayer", manifest.pos2)
  end)

end

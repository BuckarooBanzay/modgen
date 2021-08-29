---------
-- serialization functions



-- collect nodes with on_timer attributes
local node_names_with_timer = {}
minetest.register_on_mods_loaded(function()
  for _,node in pairs(minetest.registered_nodes) do
    if node.on_timer then
      table.insert(node_names_with_timer, node.name)
    end
  end
  minetest.log("action", "[modgen] collected " .. #node_names_with_timer .. " items with node timers")
end)

local air_content_id = minetest.get_content_id("air")
local ignore_content_id = minetest.get_content_id("ignore")

-- mapping from local node-id to export-node-id
local external_node_id_mapping = {}

--- Serializes the mapblock at the given position
-- @param pos the node-position
-- @return the serialized mapblock as table
function modgen.serialize_part(pos)
  local pos1, pos2 = modgen.get_mapblock_bounds(pos)
	local mapblock_pos = modgen.get_mapblock(pos)

  assert((pos2.x - pos1.x) == 15)
  assert((pos2.y - pos1.y) == 15)
  assert((pos2.z - pos1.z) == 15)

  local manip = minetest.get_voxel_manip()
  local e1, e2 = manip:read_from_map(pos1, pos2)
  local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

  local node_data = manip:get_data()
  local param1 = manip:get_light_data()
  local param2 = manip:get_param2_data()

  assert(#node_data == 4096)
  assert(#param1 == 4096)
  assert(#param2 == 4096)

  local node_id_count = {}

  -- prepare data structure
  local data = {
    node_ids = {},
    param1 = {},
    param2 = {},
    metadata = {},
    has_metadata = false,
    only_air = true,
    pos = mapblock_pos
  }

  -- loop over all blocks and fill cid,param1 and param2
  for z=pos1.z,pos2.z do
  for x=pos1.x,pos2.x do
  for y=pos1.y,pos2.y do
    local i = area:index(x,y,z)

    local node_id = node_data[i]
    if node_id == ignore_content_id then
      -- replace ignore blocks with air
      node_id = air_content_id
    end

    if node_id ~= air_content_id then
      data.only_air = false
    end

    if not external_node_id_mapping[node_id] then
      -- lookup node_id
      local nodename = minetest.get_name_from_content_id(node_id)

      if not modgen.manifest.node_mapping[nodename] then
        -- mapping does not exist yet, create it
        modgen.manifest.node_mapping[nodename] = modgen.manifest.next_id
        external_node_id_mapping[node_id] = modgen.manifest.next_id

        -- increment next external id
        modgen.manifest.next_id = modgen.manifest.next_id + 1
      else
        -- mapping exists, look it up
        local external_id = modgen.manifest.node_mapping[nodename]
        external_node_id_mapping[node_id] = external_id
      end
    end

    -- map node_id
    node_id = external_node_id_mapping[node_id]

    table.insert(data.node_ids, node_id)
    table.insert(data.param1, param1[i])
    table.insert(data.param2, param2[i])

    local count = node_id_count[node_id] or 0
    node_id_count[node_id] = count + 1
  end
  end
  end

  -- serialize metadata
  local pos_with_meta = minetest.find_nodes_with_meta(pos1, pos2)
  for _, meta_pos in ipairs(pos_with_meta) do
    local relative_pos = vector.subtract(meta_pos, pos1)
    local meta = minetest.get_meta(meta_pos):to_table()

    -- Convert metadata item stacks to item strings
    for _, invlist in pairs(meta.inventory) do
      for index = 1, #invlist do
        local itemstack = invlist[index]
        if itemstack.to_string then
          invlist[index] = itemstack:to_string()
          data.has_metadata = true
        end
      end
    end

    -- dirty workaround for https://github.com/minetest/minetest/issues/8943
    if next(meta) and (next(meta.fields) or next(meta.inventory)) then
      data.has_metadata = true
      data.metadata.meta = data.metadata.meta or {}
      data.metadata.meta[minetest.pos_to_string(relative_pos)] = meta
    end

  end

  -- serialize node timers
  if #node_names_with_timer > 0 then
    data.metadata.timers = {}
    local list = minetest.find_nodes_in_area(pos1, pos2, node_names_with_timer)
    for _, timer_pos in pairs(list) do
      local timer = minetest.get_node_timer(timer_pos)
      local relative_pos = vector.subtract(timer_pos, pos1)
      if timer:is_started() then
        data.has_metadata = true
        local timeout = timer:get_timeout()
        local elapsed = timer:get_elapsed()
        data.metadata.timers[minetest.pos_to_string(relative_pos)] = {
          timeout = timeout,
          -- round down elapsed timer
          elapsed = math.min(math.floor(elapsed/10)*10, timeout)
        }
      end
    end

  end

  return data
end

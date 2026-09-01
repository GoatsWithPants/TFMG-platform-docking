local math2d = require("__core__/lualib/math2d")

local dock_parts_filter = {"TFMG-docking-port","TFMG-docking-belt","TFMG-docking-pipe","TFMG-docking-radar"}
local dock_belts_filter = {"TFMG-docking-belt"}
local dock_pipes_filter = {"TFMG-docking-pipe"}
local max_dock_size = 1000

local offsets = {
  [defines.direction.north] = { x = 0, y = -1 },
  [defines.direction.east] = { x = 1, y = 0 },
  [defines.direction.south] = { x = 0, y = 1 },
  [defines.direction.west] = { x = -1, y = 0 },
}

local splitter_offsets = {
  [defines.direction.north] = { x = -0.5, y = 0 },
  [defines.direction.east] = { x = 0, y = 0.5 },
  [defines.direction.south] = { x = 0.5, y = 0 },
  [defines.direction.west] = { x = 0, y = -0.5 },
}

local direction_string = {
  [defines.direction.north] = "north",
  [defines.direction.east] = "east",
  [defines.direction.south] = "south",
  [defines.direction.west] = "west",
}

local opposite = {--just get me the opposite direction lmfao
  [defines.direction.north] = defines.direction.south,
  [defines.direction.east] = defines.direction.west,
  [defines.direction.south] = defines.direction.north,
  [defines.direction.west] = defines.direction.east,
  ["north"] = "south",
  ["east"] = "west",
  ["south"] = "north",
  ["west"] = "east",
  ["output"] = "input",
  ["input"] = "output"
}

local belt_types = {
  "linked-belt",
  "loader",
  "loader-1x1",
  "splitter",
  "transport-belt",
  "underground-belt",
}

local docking = {}
--docking belt manager

  local function snap_dock_belt_direction(docking_part)
    if docking_part.linked_belt_neighbour then
      docking_part.disconnect_linked_belts()
    end
    local surface = docking_part.surface
    local direction = docking_part.direction
    if docking_part.linked_belt_type == "output" then direction = opposite[direction] end--flip direction when the belt is an output, because reasons
    local search_coordinate = math2d.position.subtract(docking_part.position,offsets[direction])
    local belt = surface.find_entities_filtered{position = search_coordinate, type = belt_types, limit = 1}[1]
    if not belt then return end
    local belt_direction = belt.direction
    if direction == belt_direction then
      docking_part.linked_belt_type = "input"
    elseif direction == opposite[belt_direction] then
      docking_part.linked_belt_type = "output"
    end

    local position = docking_part.position
    local dock
    if docking_part.direction == 4 or docking_part.direction == 12 then --we need to know what axis to check.
      dock = docking.find_parent("y",position,surface)
    else
      dock = docking.find_parent("x",position,surface)
    end

    if dock then
      link.refresh_dock_data(dock.unit_number) --refresh the dock so that shit will work or whatever
      --TFMG.block(docking_part)
    end
  end

  local function find_dock_normal_belt(belt)
    local surface = belt.surface
    do--search infront
      local search_coordinate = math2d.position.add(belt.position,offsets[belt.direction])
      docking_part = surface.find_entities_filtered{position = search_coordinate, name = dock_belts_filter, limit = 1}
      if docking_part[1] then snap_dock_belt_direction(docking_part[1]) end
    end
    do--and behind of the belt
      local search_coordinate = math2d.position.subtract(belt.position,offsets[belt.direction])
      docking_part = surface.find_entities_filtered{position = search_coordinate, name = dock_belts_filter, limit = 1}
      if docking_part[1] then snap_dock_belt_direction(docking_part[1]) end
    end
  end

  local function find_dock_underground(belt)
    local surface = belt.surface
    if  belt.belt_to_ground_type == "input" then
      docking_part = surface.find_entities_filtered{position = math2d.position.subtract(belt.position,offsets[belt.direction]), name = dock_belts_filter, limit = 1}
    else
      docking_part = surface.find_entities_filtered{position = math2d.position.add(belt.position,offsets[belt.direction]), name = dock_belts_filter, limit = 1}
    end
    if docking_part[1] then snap_dock_belt_direction(docking_part[1]) end
  end
  
  local function find_dock_splitter(belt)
    local surface = belt.surface --this was probably not an amazingly clean way to do it, but its functional
    do
      local position = math2d.position.add(belt.position,splitter_offsets[belt.direction])
      do--search infront
        docking_part = surface.find_entities_filtered{position = math2d.position.add(position,offsets[belt.direction]), name = dock_belts_filter, limit = 1}
        if docking_part[1] then snap_dock_belt_direction(docking_part[1]) end
      end
      do--and behind of the belt
        docking_part = surface.find_entities_filtered{position = math2d.position.subtract(position,offsets[belt.direction]), name = dock_belts_filter, limit = 1}
        if docking_part[1] then snap_dock_belt_direction(docking_part[1]) end
      end
    end
    do
      local position = math2d.position.subtract(belt.position,splitter_offsets[belt.direction])
      do--search infront
        docking_part = surface.find_entities_filtered{position = math2d.position.add(position,offsets[belt.direction]), name = dock_belts_filter, limit = 1}
        if docking_part[1] then snap_dock_belt_direction(docking_part[1]) end
      end
      do--and behind of the belt
        docking_part = surface.find_entities_filtered{position = math2d.position.subtract(position,offsets[belt.direction]), name = dock_belts_filter, limit = 1}
        if docking_part[1] then snap_dock_belt_direction(docking_part[1]) end
      end
    end
  end

  local function find_dock_belt(belt) --when placing belts, we search for a docking connector to snap.
    if not belt.valid then return end
    if belt.type == "transport-belt" or belt.type == "loader" or belt.type == "loader-1x1" or belt.type == "linked_belt" then
      find_dock_normal_belt(belt)
    end
    if belt.type == "underground-belt" then
      find_dock_underground(belt)
    elseif belt.type == "splitter" then
      find_dock_splitter(belt)
    end
  end
  function docking.is_docking_part(entity)--returns weather or not an object is a docking part
    for _,part in pairs(dock_parts_filter) do
      if entity.name == part then return true end
    end
  return false end
  


--local functions
  local function search_shift(axis,position,i,shift) --shifts a cordinate for iterative searches
    local search_coordinate = table.deepcopy(position)
      if i == 1 then
        search_coordinate[axis] = position[axis] + shift --apply our shift
      else
        search_coordinate[axis] = position[axis] - shift
      end
  return search_coordinate end

  local function iterate_children(axis,position,surface,dock_storage)
    for i = 1,2 do
      for shift = 1,max_dock_size do --while true works, but just in case I make a mistake, i dont want this to go on forever.
        local search_coordinate = search_shift(axis,position,i,shift)
        local docking_part = surface.find_entities_filtered{position = search_coordinate, name = dock_parts_filter, limit = 1}

        if not docking_part[1] then break end --if the next shift doesnt have a connector on it, we break the loop.

        if docking_part[1].name == "TFMG-docking-port" then --conflict check, if we find another docking port while iterating, we disconnect all our docks to prevent ambiguous behaviour.
          game.print("parental conflict detected, unlinking docking belts. Make sure you have only one docking core per dock")
          game.print(dock_storage.dock)
          game.print(docking_part[1])
          dock_storage.children = {positive = {},negative = {}}
        return end

        if i == 1 then--add our children to the storage table
          table.insert(dock_storage.children["positive"],docking_part[1])
        else
          table.insert(dock_storage.children["negative"],docking_part[1])
        end
      end
    end
  end

  local function make_children(dock)--this should update what linked belts are connected to the docking port
    local direction = dock.direction
    local position = dock.position
    local surface = dock.surface
    local dock_storage = storage.docking_ports[dock.unit_number]
    if not dock_storage then return end

    link.divorce(dock.unit_number)
    dock_storage.children = {positive = {},negative = {}}
    
    if direction == 4 or direction == 12 then --we need to know what axis to check.
      iterate_children("y",position,surface,dock_storage)
    else
      iterate_children("x",position,surface,dock_storage)
    end
    --game.print(serpent.block(dock_storage.children))
    link.refresh_dock_data(dock.unit_number) --finally lets refesh the docks data
  end

  function docking.find_parent(axis,position,surface)--find a docking port by iterating through adjacent dock entities.
    for i = 1,2 do
      for shift = 1,(max_dock_size*2) do --double the max dock size, since we could be starting from the outer edge of a dock
        local search_coordinate = search_shift(axis,position,i,shift)
        local docking_part = surface.find_entities_filtered{position = search_coordinate, name = dock_parts_filter, limit = 1}

        if not docking_part[1] then break end --if the next shift doesnt have a connector on it, we break the loop.
        if docking_part[1].name == "TFMG-docking-port" then --conflict check, if we find another docking port while iterating, we disconnect all our docks to prevent ambiguous behaviour.
        return docking_part[1] end
      end
    end
  end

  local function make_parent(connector)
    local direction = connector.direction
    local position = connector.position
    local surface = connector.surface
    local dock
    if direction == 4 or direction == 12 then --we need to know what axis to check.
      dock = docking.find_parent("y",position,surface)
    elseif direction == 0 then -- not rotatable entities, check both axes
      dock = docking.find_parent("x",position,surface)
      if not dock then 
        dock = docking.find_parent("y",position,surface) 
      end
    else
      dock = docking.find_parent("x",position,surface)
    end
    if not dock then return end
    make_children(dock)
  end

--create destroy events

  local function create_collider(event) --creates a collider entity
    local entity = event.entity
    local surface = entity.surface
    local unit_number = entity.unit_number
    local direction = entity.direction
    if entity.name == "TFMG-docking-belt" then --if docking belt we should check if we must flip it.
      belt_type = entity.linked_belt_type
      if belt_type then
        --game.print(belt_type)
        if belt_type == "output" then
            direction = opposite[direction]
            --game.print("flip")
        end
      end
    elseif entity.name == "TFMG-docking-pipe" then -- I don't know why docking pipe needs to be flipped, but when placed, collision detection gets reversed. Very strange, flipping it here fixes it (mostly?)
      direction = opposite[direction]
    end
    script.register_on_object_destroyed(entity)
    local collider = surface.create_entity{
      name = "TFMG-dock-collider",
      position = entity.position,
      direction = direction,
    }
    storage.colliders[unit_number] = collider
  end

  local function on_docking_port_created(event)
    local dock = event.entity
    local _reg_number, unit_number, _type = script.register_on_object_destroyed(dock)
    storage.docking_ports[unit_number] = {
      dock = dock, --docking port luaentity
      linked = nil, --id of linked docking port
      space_location = nil, --name of location dock is orbiting, or was last at.
      children = {--table of all the children owned by this dock
        positive = {},
        negative = {},
      },
      direction = direction_string[dock.direction],
      docking_signal = nil,
      zero_dock = true,
    }
    dock.rotatable = false --for now, imma prevent rotating a placed dock, just cause theres no real sense in it being possible.
    make_children(dock)
    create_collider(event)
  end

  local function on_docking_port_destroyed(unit_number)
    link.clear_dock_data(unit_number)
  end

  local function on_docking_belt_created(event)
    local connector = event.entity
    connector.rotatable = false
    make_parent(connector)
    snap_dock_belt_direction(connector)
    create_collider(event)
  end

  local function on_docking_pipe_created(event)
    local connector = event.entity
    connector.rotatable = false
    make_parent(connector)
    create_collider(event)
  end


  local function on_docking_radar_created(event)
    local connector = event.entity
    connector.rotatable = false
    connector.operable = false  -- don't want player to access gui of radar
    connector.disabled_by_script = true -- disable on build, gets enabled on link and disabled on unlink 
    make_parent(connector)   

  end


--callable functions
  function docking.handle_build_event(event)
    if event.entity.name == "TFMG-docking-port" then
      on_docking_port_created(event)
    elseif event.entity.name == "TFMG-docking-belt" then
      on_docking_belt_created(event)
    elseif event.entity.name == "TFMG-docking-pipe" then
      on_docking_pipe_created(event)
    elseif event.entity.name == "TFMG-docking-radar" then   
      on_docking_radar_created(event)
    else
      find_dock_belt(event.entity)
    end
  end

  function docking.handle_rotate_event(event)
    find_dock_belt(event.entity)
  end

  function docking.belt_flip(event)
    local selected = event.selected_prototype
    if not selected or selected.name ~= "TFMG-docking-belt" then return end
    --this is the check from TFMG thermal core, that prevents futher code from running in instances where rotations would not be expected.
    local player = game.players[event.player_index]
    if not player.is_cursor_empty() then
      local cursor_stack
      if player.cursor_stack and player.cursor_stack.valid_for_read then
        cursor_stack = player.cursor_stack.prototype
      elseif player.cursor_ghost then
        cursor_stack = player.cursor_ghost.name
      end
      if not cursor_stack then return end
      if cursor_stack.place_result then return end
    end

    local surface = player.surface
    local connector_entity = surface.find_entity(selected.name,event.cursor_position)--get our actual selected entity
    if not connector_entity or not connector_entity.linked_belt_type then return end

    --get parent dock.
    local direction = connector_entity.direction
    local position = connector_entity.position

    if direction == 4 or direction == 12 then --honestly, i should have baked this part into the find parent function. Fuck me
      dock = docking.find_parent("y",position,surface)
    else
      dock = docking.find_parent("x",position,surface)
    end

    if not dock then return end
    link.undock(dock.unit_number) --the docks must be disconnected to be modified like this. I shouldn't need to fully rebuild the dock, since structurally, it should still be the same.
    connector_entity.linked_belt_type = opposite[connector_entity.linked_belt_type]
  end

  function docking.handle_destroy_event(event)
    local unit_number = event.useful_id
    local dock_data = storage.docking_ports[unit_number]
    if dock_data then on_docking_port_destroyed(unit_number) end --only if we have an appropriate entry we should run this script. just in case

    local collider = storage.colliders[unit_number]
    if collider then
      collider.destroy()
      storage.colliders[unit_number] = nil
    end
  end

return docking
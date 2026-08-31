--local flib_table = require("__flib__/table")

local direction_string = {
  [defines.direction.north] = "north",
  [defines.direction.east] = "east",
  [defines.direction.south] = "south",
  [defines.direction.west] = "west",
}
local direction_is_north_or_east = { --returns true if direction is north or east.
  ["north"] = true,
  ["east"] = true,
  ["south"] = false,
  ["west"] = false,
  [defines.direction.north] = true,
  [defines.direction.east] = true,
  [defines.direction.south] = false,
  [defines.direction.west] = false,
}

local opposite = {--just get me the opposite direction lmfao
  ["north"] = "south",
  ["east"] = "west",
  ["south"] = "north",
  ["west"] = "east",
}


local link = {} --technically this revison might be less optimized due to redundant work but it should be cleaner code wise.

--ready and unready docks. handles docks.direction.location

  function link.ready_dock(dock_id)--register a dock by its id to their location. if theyre in orbit.
    --get important information about the dock
    local dock_storage = storage.docking_ports[dock_id]
    if dock_storage.linked then return end --docks shouldnt be made ready if theyre presently linked
    if not dock_storage.docking_signal then return end --dont ready a dock that doesnt have a set docking signal
    local dock_entity = dock_storage.dock--using this we can retreive the entity.
    if not dock_entity.valid then return end -- cant ready a dock thats kaput
    local dock_space_location = dock_entity.surface.platform.space_location

    if not dock_space_location then return end --if this dock isnt parked in orbit, we don't add it to the list
    

    local direction = dock_storage.direction

    storage.docks[direction][dock_space_location.name][dock_id] = true --the index already contains the id, so boolean it is
    dock_storage.space_location = dock_space_location
  end


  function link.unready_dock(dock_id) --unregister a dock from the dynamic storage table, so other docks dont attempt to connect to it
    local dock_storage = storage.docking_ports[dock_id]
    local direction = dock_storage.direction
    local dock_last_space_location = dock_storage.space_location

    if not dock_last_space_location then return end --if a platform changes state while not in orbit, this function ends up being called while the dock already is unregistered, and doesnt have a space location.
    storage.docks[direction][dock_last_space_location.name][dock_id] = nil
  end

--deal with space location storage in storage.docking_ports, should be called whenever a platform changes locations

  function link.update_dock_location(dock_entity,space_location) --update the stored location of an individual dock
    if not dock_entity then return end --this may occur, since space platforms can return an empty table.
    local dock_storage = storage.docking_ports[dock_entity.unit_number]

    dock_storage.space_location = space_location --save our location name, may also be nil for no location.
  end

--linked_docks handlers, simply adds and removes docks to the list of currently conencted docks.

  function link.add_to_linked_docks(dock_id) --we're only gonna keep north and east docks in this storage.
    if direction_is_north_or_east[storage.docking_ports[dock_id].direction] then
      storage.linked_docks[dock_id] = true
    end
  end

  function link.remove_from_linked_docks(dock_id) --removes dock id from list of linked docks
    storage.linked_docks[dock_id] = nil
  end

--link subhandlers, responsible for actually connecting and disconnecting docking ports.

  local function link_child(alice,bob)--attempts to link two entities

    --game.print(serpent.block(alice))
    --game.print(serpent.block(bob))

    if alice.type ~= bob.type then return end --if they arent the same prototype, we don't link them

    if alice.type == "linked-belt" then --linked belt method
      if alice.linked_belt_type == bob.linked_belt_type then return end --we can't connect if theyre the same direction.
      alice.connect_linked_belts(bob)
    elseif alice.type == "pipe-to-ground" then--fluid method
      alice.add_fluid_box_linked_connection(1,bob,1)
    elseif alice.type == "radar" then--circuit method"
      local aliceConnectorGreen = alice.get_wire_connector(defines.wire_connector_id.circuit_green, true)
      local aliceConnectorRed = alice.get_wire_connector(defines.wire_connector_id.circuit_red, true)
      local bobConnectorGreen = bob.get_wire_connector(defines.wire_connector_id.circuit_green, true)
      local bobConnectorRed = bob.get_wire_connector(defines.wire_connector_id.circuit_red, true)
      aliceConnectorGreen.connect_to(bobConnectorGreen, false, defines.wire_origin.script)
      aliceConnectorRed.connect_to(bobConnectorRed, false, defines.wire_origin.script)
      alice.disabled_by_script = false
      bob.disabled_by_script = false
    end
  end

  function link.marriage(dock_id_1,dock_id_2)--iterates through all children of a dock, and attempts to link them.

    local port_1 = storage.docking_ports[dock_id_1]
    --game.print(serpent.block(port_1.children))
    local port_2 = storage.docking_ports[dock_id_2]
    --game.print(serpent.block(port_2.children))

    for _,alice in pairs(port_1.children.positive) do --link positive side connections
      if not alice.valid then return end
      local bob = port_2.children.positive[_]
      if not bob then break end --if we don't have a corresponding child, on dock 2 that means dock 1 is larger, and we can stop checking.
      if not bob.valid then return end
      link_child(alice,bob)
    end

    for _,alice in pairs(port_1.children.negative) do --link negative side connections
      if not alice.valid then return end
      local bob = port_2.children.negative[_]
      if not bob then break end
      if not bob.valid then return end
      link_child(alice,bob)
    end
  end

  function link.unlink_child(alice) --unlinks an entity if it is linked
    if not alice.valid then return end

    if alice.type == "linked-belt" then --linked belt method
      alice.disconnect_linked_belts()
    elseif alice.type == "pipe-to-ground" then--fluid method
      alice.remove_fluid_box_linked_connection(1)
    elseif alice.type == "radar" then--radar  method 
      for wire_ID,wire_connector in pairs(alice.get_wire_connectors()) do
        wire_connector.disconnect_all(defines.wire_origin.script) -- remove all wires added by script 
        alice.disabled_by_script = true
      end
    end
  end

  function link.divorce(dock_id_1) --unlinks all of a docks children.
    local port_1 = storage.docking_ports[dock_id_1]
  
    for _, alice in pairs(port_1.children.positive) do 
      if not alice.valid then return end 
      link.unlink_child(alice)
    end

    for _, alice in pairs(port_1.children.negative) do 
      if not alice.valid then return end 
      unlink_child(alice)
    end
  end

--Dock and undock handlers, these call the link subhandlers, and also call the appropriate data modification functions.

  function link.undock(dock_id) --disconnects a dock for any reason.
    local dock_storage = storage.docking_ports[dock_id]

    local dock_id_2 = dock_storage.linked
    if not dock_id_2 then return end --we cannot at all undock a dock that is not docked.
    link.divorce(dock_id) --physically undock the entities
    link.divorce(dock_id_2) --physically undock the entities

    -- divorce 1 and 2 here
    link.remove_from_linked_docks(dock_id_2) --remove from the currently linked docks list
    link.remove_from_linked_docks(dock_id)

    local dock_storage_2 = storage.docking_ports[dock_id_2] --get the storage entry for the dock we're just now undocking

    dock_storage_2.linked = nil
    dock_storage.linked = nil

    --set docks to be ready. will only ready docks that have a space location.
    link.ready_dock(dock_id_2)
    link.ready_dock(dock_id)

  end


  function link.dock(dock_id_1,dock_id_2) --connects two docks.

    link.marriage(dock_id_1,dock_id_2) --handles physically connecting the docks

    link.add_to_linked_docks(dock_id_1) --add dock_id to currently linked docks list
    link.add_to_linked_docks(dock_id_2)

    --save the ids of our linked docks for later refrence.
    local dock_storage_1 = storage.docking_ports[dock_id_1]
    dock_storage_1.linked = dock_id_2

    local dock_storage_2 = storage.docking_ports[dock_id_2]
    dock_storage_2.linked = dock_id_1

    --unready both docks
    link.unready_dock(dock_id_1)
    link.unready_dock(dock_id_2)
  end

--docking checks
  local function debug_connectability_checks(dock_storage_1,dock_storage_2)
    --verify that storage for both docks exists
    if not dock_storage_1 then return false end
    if not dock_storage_2 then return false end
    return true end
  
  local function get_dock_signals(dock_entity,signal)
    local green = dock_entity.get_signal(signal,defines.wire_connector_id.circuit_green)
    local red = dock_entity.get_signal(signal,defines.wire_connector_id.circuit_red)
    local signal_value = red + green
  return signal_value end

  function link.check_dock_connectability(dock_id_1,dock_id_2) --checks weather two docks
    local dock_storage_1 = storage.docking_ports[dock_id_1]
    local dock_storage_2 = storage.docking_ports[dock_id_2]
    if not debug_connectability_checks(dock_storage_1,dock_storage_2) then return false end --these checks shouldn't be necessary for the function of the mod but might help me find out if anything weird is happening

    if not dock_storage_1.dock.valid then return false end
    if not dock_storage_2.dock.valid then return false end


    if dock_storage_1.dock.surface.index == dock_storage_2.dock.surface.index then return false end --if both docks are on the same platform, they cannot connect.
    local docking_signal_1 = dock_storage_1.docking_signal
    local docking_signal_2 = dock_storage_2.docking_signal
    if docking_signal_1.name ~= docking_signal_2.name then return false end --if the docking signals set arent equal, we dont dock
    if docking_signal_1.quality ~= docking_signal_2.quality then return false end

    local dock_input_signal_1 = get_dock_signals(dock_storage_1.dock,docking_signal_1)
    local dock_input_signal_2 = get_dock_signals(dock_storage_2.dock,docking_signal_1)

    if dock_input_signal_1 ~= dock_input_signal_2 then return false end

    if not dock_storage_1.zero_dock  and dock_input_signal_1 == 0 then return false end --dont dock if either signal is zero and the dock with 0 signal isnt enabled
    if not dock_storage_2.zero_dock  and dock_input_signal_2 == 0 then return false end
  
   --signal matching code here
  return true end

--find dockable
  function link.attempt_connection(dock_id_1,direction,location_name) --attempt to find a corresponding dock in the same location to connect to.
    local candidates = storage.docks[opposite[direction]][location_name]

    for dock_id_2,v in pairs(candidates) do
      if link.check_dock_connectability(dock_id_1,dock_id_2) then --if we return true, we dock and then break the loop.
        link.dock(dock_id_1,dock_id_2)
      break end
    end
  end


--platform update functions
  function link.space_platform_changed_state(event) --readys docks when a platform arrives in orbit, undocks and unreadies when a platform leaves
    local platform = event.platform
    local surface = platform.surface
    if not surface then return end
    local platform_docks = surface.find_entities_filtered{name = "TFMG-docking-port"} --get all our docks
    
    if not platform_docks[1] then return end --if there aren't any docks on this platform, don't do anything.

    local space_location = platform.space_location
    
    if space_location then --if our platform is in orbit of something, we prepare our docks for docking
      for _,dock_entity in pairs(platform_docks) do
        local dock_id = dock_entity.unit_number
        link.update_dock_location(dock_entity,space_location) --this updates our space location
        link.ready_dock(dock_id) --this must come after we update our space location
      end
    else --if our platform is not in orbit, then we make sure all docks are undocked and unready.
      for _,dock_entity in pairs(platform_docks) do
        local dock_id = dock_entity.unit_number
        link.unready_dock(dock_id) --this still needs space location to exist
        link.update_dock_location(dock_entity,space_location)
        link.undock(dock_id) --undocks all connected ports. expects space location to be nil or it will put the platforms docks into ready state.
      end
    end
  end

--dock data functions
  function link.refresh_dock_data(dock_id) --resets a docking port status, used when a dock is modified or first built.
    local dock_entity = storage.docking_ports[dock_id].dock
    local space_location = dock_entity.surface.platform.space_location
    link.update_dock_location(dock_entity,space_location)
    link.undock(dock_id) -- todo check here 
    link.unready_dock(dock_id) --Sets dock unready, incase it hasnt already.
    link.ready_dock(dock_id) --sets dock to ready if appropriate   
  end

  function link.clear_dock_data(dock_id) --cleans up dock data
    link.undock(dock_id)
    link.unready_dock(dock_id)
    storage.docking_ports[dock_id] = nil

  end

--on tick functions


  function link.connect_ready_docks(direction) --check our ready docks and see if we can link any.
    for location_name,docks_at_location in pairs(storage.docks[direction]) do
      storage.dock_k[direction][location_name] = TFMG_table.for_n(docks_at_location, storage.dock_k[direction][location_name], 1,
      function(v,dock_id) --weird but its value, key, and we need the key
        link.attempt_connection(dock_id,direction,location_name)
      end)
    end
  end

  function link.check_linked_docks()--check active connections to see if we should disconnect them.
    storage.linked_docks_k = TFMG_table.for_n( storage.linked_docks, storage.linked_docks_k, 1,
    function(v,dock_id_1) --weird but its Value, Key, and we need the key
      local dock_id_2 = storage.docking_ports[dock_id_1].linked
      if not link.check_dock_connectability(dock_id_1,dock_id_2) then --if this returns false, we need to undock
        link.undock(dock_id_1)
      end
    end)
  end

  function link.on_tick()--we're gonna take the normal approch of checking a finite number of docking ports per tick
    link.connect_ready_docks("north")
    link.connect_ready_docks("east")
    link.check_linked_docks()
  end

return link
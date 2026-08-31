--local functions

local function setup_storage()--make sure all important storage tables are ready.
  if not storage.docking_ports then
    storage.docking_ports = {} --this should contain a full list of all existing docking ports, and useful information about them.
  end

  if not storage.linked_docks then
    storage.linked_docks = {}
  end

  if not storage.docks then --this will be the table containing all my dock ids as they move around and such
    storage.docks = {}
  end
  --setup each directional dock table.
  if not storage.docks.north then storage.docks.north = {} end
  if not storage.docks.east then storage.docks.east = {} end
  if not storage.docks.south then storage.docks.south = {} end
  if not storage.docks.west then storage.docks.west = {} end
  local space_locations = prototypes.space_location
  for direction, table in pairs(storage.docks) do --create a subtable for each space location in the game.
    for _, location in pairs(space_locations) do
      if not table[location.name] then table[location.name] = {} end
    end
  end
  --repeat but for the flib from k thingy --now the TFMG for_n thing !

  if not storage.dock_k then
    storage.dock_k = {}
  end

  if not storage.linked_docks_k then
    storage.linked_docks_k = {}
  end

  --setup each directional dock table.
  if not storage.dock_k.north then storage.dock_k.north = {} end
  if not storage.dock_k.east then storage.dock_k.east = {} end
  

  for direction, table in pairs(storage.dock_k) do --create a subtable for each space location in the game.
    for _, location in pairs(space_locations) do
      if not table[location.name] then table[location.name] = {} end
    end
  end

  if not storage.player_ui then storage.player_ui = {} end
  if not storage.player_gui_boxes then storage.player_gui_boxes = {} end

  for player_index, player in pairs(game.players) do
    if not storage.player_ui[player_index] then storage.player_ui[player_index] = {} end
  end

  if not storage.colliders then storage.colliders = {} end

end

local function setup_gui_storage(event)
  --player gui storage
  local player_index = event.player_index
  if not storage.player_ui[player_index] then storage.player_ui[player_index] = {} end
end

local build_event_filter = {--what entities the on build events should check for.
  {
  	filter = "name",
  	name = "TFMG-docking-port",
  	mode = "or"
  },
  {
  	filter = "name",
  	name = "TFMG-docking-belt",
  	mode = "or"
  },
  {
  	filter = "name",
  	name = "TFMG-docking-pipe",
  	mode = "or"
  },
  {
  	filter = "name",
  	name = "TFMG-docking-radar",
  	mode = "or"
  },
  {
    filter = "transport-belt-connectable",
    mode = "or"
  },
}


--init functions

script.on_init(function()
  setup_storage()
end)

script.on_configuration_changed(function()
  setup_storage()
end)

script.on_event(defines.events.on_player_created,
  function(event)
    setup_gui_storage(event)
  end
)

--build events


script.on_event( defines.events.on_built_entity,
  function(event)
    docking.handle_build_event(event)
  end,build_event_filter
)
script.on_event( defines.events.on_robot_built_entity,
  function(event)
    docking.handle_build_event(event)
  end,build_event_filter
)
script.on_event( defines.events.on_space_platform_built_entity,
  function(event)
    docking.handle_build_event(event)
  end,build_event_filter
)
script.on_event( defines.events.on_entity_cloned,
  function(event)
    docking.handle_build_event(event)
  end,build_event_filter
)
script.on_event( defines.events.on_object_destroyed,
	function(event)
		docking.handle_destroy_event(event)
	end
)
script.on_event( defines.events.on_player_rotated_entity,
  function(event)
    docking.handle_rotate_event(event)
  end
)
script.on_event( defines.events.on_player_flipped_entity,
  function(event)
    docking.handle_rotate_event(event)
  end
)

script.on_event( defines.events.on_space_platform_changed_state,
  function(event)
    link.space_platform_changed_state(event)
  end
)
--on tick
script.on_event( defines.events.on_tick,--Its HaNlDeR sHoUldNt InCluDe PeRfOrMaNce HeAvY CoDe. You cant tell me what to do.
  function()
    link.on_tick()
    ui.on_tick()
  end
)

--UI interaction events
script.on_event( defines.events.on_gui_opened,
  function(event)
    ui.on_gui_opened(event)
  end
)

script.on_event( defines.events.on_gui_click,
  function(event)
    ui.on_gui_click(event)
  end
)

script.on_event( defines.events.on_gui_closed,
  function(event)
    ui.on_gui_closed(event)
  end
)

script.on_event( defines.events.on_gui_elem_changed,
  function(event)
    ui.on_gui_elem_changed(event)
  end
)

script.on_event( defines.events.on_gui_checked_state_changed,
  function(event)
    ui.on_gui_checked_state_changed(event)
  end
)

--rotate/flip events
script.on_event("interface-rotate",
  function (event)
    docking.belt_flip(event)
  end
)
script.on_event("interface-rotate-reverse",
  function (event)
    docking.belt_flip(event)
  end
)
script.on_event("interface-flip-horizontal",
  function (event)
    docking.belt_flip(event)
  end
)
script.on_event("interface-flip-vertical",
  function (event)
    docking.belt_flip(event)
  end
)

script.on_event("on_selected_entity_changed",
  function(event)
    ui.selection(event)
  end)



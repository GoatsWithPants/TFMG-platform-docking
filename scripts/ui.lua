local ui = {}

--utlity functions
  function ui.find_parent_frame(element)--find the uppermost frame which this element is in.
    local frame = element
    while frame do
      if frame.tags["TFMG_dock_ui"] then return frame end
      frame = frame.parent
    end
  return nil end

  function ui.change_signal_picker(event) --changes the value of the signal picker and saves it to the docks storage
    local element = event.element
    local main_frame = ui.find_parent_frame(element)
    local dock_id = main_frame.tags["dock_id"]
    storage.docking_ports[dock_id].docking_signal = element.elem_value
    link.refresh_dock_data(dock_id) -- refresh the dock incase it should be unreadied or whatever
  end

  function ui.zero_signal_toggle(event) --toggles the 0 signal value
    local element = event.element
    local main_frame = ui.find_parent_frame(element)
    local dock_id = main_frame.tags["dock_id"]
    storage.docking_ports[dock_id].zero_dock = not storage.docking_ports[dock_id].zero_dock
    link.refresh_dock_data(dock_id) -- refresh the dock incase it should be unreadied or whatever
  end

--dock ui sub frame functions

  function ui.main_title_bar(main_frame,caption) --adds the main title bar
    local title_bar = main_frame.add{type = "flow"}
    title_bar.drag_target = main_frame
    title_bar.add{
      type = "label",
      style = "frame_title",
      caption = caption,
      ignored_by_interaction = true
    }

    local empty = title_bar.add {
      type = "empty-widget",
      style = "draggable_space",
      ignored_by_interaction = true,
    }

    empty.style.height = 24
    empty.style.horizontally_stretchable = true
    title_bar.add {
      type = "sprite-button",
      name = "TFMG_dock_ui_x_button",
      style = "frame_action_button",
      sprite = "utility/close",
      tooltip = {"gui.close-instruction"},
    }
  end

  function ui.circuit_control_panel(frame,dock_storage)--add a signal picker
    local control_panel = frame.add{
      type = "flow",
      direction = "horizontal",
      style = "player_input_horizontal_flow",
    }
    control_panel.add{
      type = "label",
      caption = {"docking-ui.signal-picker-label"},
    }
    control_panel.add{--little info icon to hover over
      type = "sprite",
      sprite = "info",
      tooltip = {"docking-ui.signal-picker-description"}
    }
    local signal_picker = control_panel.add{ --signal picker thingy
      type = "choose-elem-button",
      name = "TFMG_dock_signal_picker",
      elem_type = "signal",
    }
    signal_picker.elem_value = dock_storage.docking_signal
    control_panel.add{
      type = "label",
      caption = {"docking-ui.zero-signal-toggle"},
    }
    control_panel.add{--little info icon to hover over
      type = "sprite",
      sprite = "info",
      tooltip = {"docking-ui.zero-signal-toggle-description"}
    }
    local dock_toggle = control_panel.add{ --signal picker thingy
      type = "checkbox",
      name = "TFMG_dock_zero_signal",
      state = dock_storage.zero_dock
    }
    --control_panel.add{ --worry about this feature later
    --  type = "slider",
    --  name = "TFMG_dock_zoom_slider",
    --  value = player.mod_settings["TFMG-dock-preview-zoom"].value,
    --}
  end

  function ui.connected_dock_preview(frame,player) --creates the connected dock preview frame
    local view_panel = frame.add{
      type = "frame",
      name = "TFMG_dock_view_panel",
      style = "inside_deep_frame",
      direction = "vertical",
    }
    
    view_panel.style.horizontally_stretchable = true
    view_panel.style.vertically_stretchable = true
    view_panel.style.minimal_width = player.mod_settings["TFMG-dock-preview-size-x"].value --scale for gui scale
    view_panel.style.minimal_height = player.mod_settings["TFMG-dock-preview-size-y"].value
    view_panel.style.horizontal_align = "center"
    view_panel.style.vertical_align = "center"
    
  return view_panel end

  function ui.set_view_panel_camera(view_panel,dock_storage,player) --sets dock camera
    view_panel.clear()

    if dock_storage.linked then --if we have a currently linked entity.
      local linked_entity = storage.docking_ports[dock_storage.linked].dock
      local camera = view_panel.add{
        type = "camera",
        name = "TFMG_dock_view_camera",
        position = {0,0}
      }
      camera.style.horizontally_stretchable = true
      camera.style.vertically_stretchable = true
      camera.entity = linked_entity
      if player.mod_settings["TFMG-dock-preview-dynamic-zoom"] then
        camera.zoom = player.zoom
      else
        camera.zoom = player.mod_settings["TFMG-dock-preview-zoom"].value
      end
    else --show no dock connected
      view_panel.add{
        type = "label",
        caption = {"docking-ui.view-panel-no-dock"}
      }
    end
  end

--create dock ui primary
  function ui.create_main_frame(event) --primary dock ui creator function
  local player = game.get_player(event.player_index) --get our useful information
  local dock_id = event.entity.unit_number
  local dock_storage = storage.docking_ports[dock_id]

  local main_frame = player.gui.screen.add{
    type = "frame",
    name = "dock_gui",
    direction = "vertical",
    tags = {
      TFMG_dock_ui = true,
      dock_id = dock_id,
    }
  }
  player.opened = main_frame
  main_frame.style.vertically_stretchable = true
  main_frame.style.horizontally_stretchable = true
  main_frame.auto_center = true

  ui.main_title_bar(main_frame,{"docking-ui.main-ui-title"})
  ui.circuit_control_panel(main_frame,dock_storage)
  main_frame.add{type = "line"}
  local view_panel = ui.connected_dock_preview(main_frame,player)
  ui.set_view_panel_camera(view_panel,dock_storage,player)

  return main_frame end

  function ui.update_ui(main_frame,player)
    --update the view panel
    if not main_frame or not main_frame.valid then
      storage.player_ui[player.index] = nil 
    return end
    local dock_storage = storage.docking_ports[main_frame.tags["dock_id"]]
    if not dock_storage then
       ui.find_parent_frame(main_frame).destroy() 
       storage.player_ui[player.index] = nil 
      return end
    local view_panel = main_frame["TFMG_dock_view_panel"]
    ui.set_view_panel_camera(view_panel,dock_storage,player)
  end

--on event functions
  function ui.on_gui_opened(event)
    --conditions to create ui, basically player must exist, you must be clicking on a docking port
    if not event.entity or event.entity.name ~= "TFMG-docking-port" then return end
    if not game.get_player(event.player_index) then return end

    main_frame = ui.create_main_frame(event) --actually create the ui
    storage.player_ui[event.player_index] = main_frame --save the ui to storage
  end

  function ui.on_gui_click(event)
    if not event.element then return end
    if event.element.name == "TFMG_dock_ui_x_button" then
      ui.find_parent_frame(event.element).destroy()
    elseif event.element.name == "TFMG_dock_view_camera" then
      ui.camera_window_clicked(event)
    end
  end

  function ui.camera_window_clicked(event)
    --TFMG.block(event)
    local camera_focus = event.element.entity
    local player = game.players[event.player_index]

    player.centered_on = camera_focus
    player.opened = camera_focus
  end

  function ui.zoom_in(event)
    TFMG.block(event)
  end

  function ui.zoom_out(event)
    TFMG.block(event)
  end
  function ui.on_gui_closed(event)
    if event.element and event.element.tags["TFMG_dock_ui"] then
      event.element.destroy()
      storage.player_ui[event.player_index] = nil --delete ui
    end
  end
  local function create_highlight_box(entity,player_index) --create a highlight box
    if not entity.valid then return end
    local surface = entity.surface
    local box_type = "electricity"
    --change the colour of the highlight boxes if the child is currently linked
    if entity.type == "linked-belt" then --linked belt method
      if entity.linked_belt_neighbour then box_type = "pair" end
    elseif entity.type == "pipe-to-ground" then--fluid method
      if entity.get_fluid_box_linked_connection(1) then box_type = "pair" end
    end

    local guibox = surface.create_entity({
      type = "highlight-box",
      name = "highlight-box",
      box_type = box_type,
      position = entity.position,
      source = entity,
      render_player_index = player_index,
    })

    if not storage.player_gui_boxes[player_index] then storage.player_gui_boxes[player_index] = {} end
    local gui_boxes = storage.player_gui_boxes[player_index]
    table.insert(gui_boxes,guibox) --save this guibox so we can delete it when the player deselects the port later
  end

  local function delete_highlight_boxes(player_index) --clear out a players highlight boxes
    local gui_boxes = storage.player_gui_boxes[player_index]
    if not gui_boxes then return end
    for _,gui_box in pairs(gui_boxes) do
      gui_box.destroy()
    end
    storage.player_gui_boxes[player_index] = nil --cleanup our guiboxes storage
  end
  function ui.selection(event) --create selection boxes for the children of a docking port when hovering over it
    local player_index = event.player_index
    local player = game.players[player_index]
    local entity = player.selected
    if not entity or entity.name ~= "TFMG-docking-port" then
      delete_highlight_boxes(player_index)
    return end

    local dock_storage = storage.docking_ports[entity.unit_number]
    for _,child in pairs(dock_storage.children.positive) do create_highlight_box(child,player_index) end
    for _,child in pairs(dock_storage.children.negative) do create_highlight_box(child,player_index) end
  end

  function ui.on_gui_elem_changed(event)
    local element = event.element
    if element and element.valid and element.name == "TFMG_dock_signal_picker" then
      ui.change_signal_picker(event)
    end
  end

  function ui.on_gui_checked_state_changed(event)
    local element = event.element
    if element and element.valid and element.name == "TFMG_dock_zero_signal" then
      ui.zero_signal_toggle(event)
    end
  end

  function ui.on_tick()
    for _,player in pairs(game.connected_players) do
      local main_frame = storage.player_ui[player.index]
      if main_frame and main_frame.valid then
        ui.update_ui(main_frame,player) --why are we updating the ui every tick?
      end
    end
  end

return ui
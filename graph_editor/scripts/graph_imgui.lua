local style          = require("graph_editor.scripts.imgui_style")
local data           = require("graph_editor.scripts.editor_data")
local const          = require("graph_editor.scripts.editor_const")
local graph          = require("graph_editor.scripts.editor_graph")
local utils          = require("graph_editor.scripts.editor_utils")
local file           = require("graph_editor.scripts.editor_file")

-- =======================================
-- MODULE
-- =======================================
local graph_imgui    = {}

-- =======================================
-- VARS
-- =======================================
local flags          = bit.bor(imgui.WINDOWFLAGS_NOTITLEBAR)
local changed        = false
local checked        = false
local int_value      = 0
local float_value    = 0.0
local x, y, z        = 0.0, 0.0, 0.0

local save_file_name = ""



-- =======================================
-- Helpers
-- =======================================

local function get_key_for_value(t, value)
	for k, v in pairs(t) do
		if v == value then return k end
	end
	return "Select a Style"
end

-- =======================================
-- Window Callback
-- =======================================
local function window_callback(self, event, data)
	if event == window.WINDOW_EVENT_FOCUS_LOST then
		--	print("window.WINDOW_EVENT_FOCUS_LOST")
	elseif event == window.WINDOW_EVENT_FOCUS_GAINED then
		--print("window.WINDOW_EVENT_FOCUS_GAINED")
	elseif event == window.WINDOW_EVENT_ICONFIED then
		--	print("window.WINDOW_EVENT_ICONFIED")
	elseif event == window.WINDOW_EVENT_DEICONIFIED then
		--	print("window.WINDOW_EVENT_DEICONIFIED")
	elseif event == window.WINDOW_EVENT_RESIZED then
		print("Window resized: ", data.width, data.height)
		-- NO EFFECT?
		imgui.set_display_size(data.width, data.height)
	end
end

-- =======================================
-- Init
-- =======================================
function graph_imgui.init()
	imgui.set_display_size(1920, 1080)
	imgui.set_ini_filename("graph_editor.ini")
	style.set()
	utils.set_title()

	window.set_listener(window_callback)
end

-- =======================================
-- Main Menu
-- =======================================
local function main_menu_bar(self)
	if imgui.begin_main_menu_bar() then
		-- File
		if imgui.begin_menu("File") then
			if imgui.menu_item("New", nil) then
				data.selected_file = -1
				graph.reset()
				graph.init()
				utils.set_title()
			end

			if imgui.menu_item("Load", nil) then
				data.modals.open_file = true
			end

			if imgui.menu_item("Save", nil) then
				if data.selected_file > -1 then
					file.save()
				else
					data.modals.open_save = true
				end
			end

			if imgui.menu_item("Export JSON", nil) then
				file.export_json()
			end

			--[[	if imgui.menu_item("Export LUA", nil) then
				file.export_lua()
			end]]

			if imgui.menu_item("Quit", nil) then
				sys.exit(0)
			end

			imgui.end_menu()
		end

		-- View
		if imgui.begin_menu("View") then
			local clicked, selected = imgui.menu_item("Nodes", nil, data.options.draw.nodes)
			if clicked then
				data.options.draw.nodes = selected
				utils.set_nodes_visiblity()
			end

			local clicked, selected = imgui.menu_item("Edges", nil, data.options.draw.edges)
			if clicked then
				data.options.draw.edges = selected
			end

			local clicked, selected = imgui.menu_item("Paths", nil, data.options.draw.paths)
			if clicked then
				data.options.draw.paths = selected
			end

			local clicked, selected = imgui.menu_item("Smooth Paths", nil, data.options.draw.smooth_path)
			if clicked then
				data.options.draw.smooth_path = selected
			end

			imgui.end_menu()
		end
		-- About
		if imgui.begin_menu("About") then
			imgui.menu_item("Defold v" .. sys.get_engine_info().version, nil, nil, false)

			imgui.end_menu()
		end

		imgui.text_colored(data.save_load_text, 0, 1, 0, 1)
		imgui.end_main_menu_bar()
	end
end

-- =======================================
-- TOOLS
-- =======================================
local function tools()
	imgui.set_next_window_size(180, 400)
	imgui.begin_window("TOOLS", nil, flags)

	if imgui.radio_button("Add Node", data.editor_state == const.EDITOR_STATES.ADD_NODE) then
		graph.clear()
		data.editor_state = const.EDITOR_STATES.ADD_NODE
		data.action_status = const.EDITOR_STATUS.ADD_NODE
	end

	if imgui.radio_button("Remove Node", data.editor_state == const.EDITOR_STATES.REMOVE_NODE) then
		graph.clear()
		data.editor_state = const.EDITOR_STATES.REMOVE_NODE
		data.action_status = const.EDITOR_STATUS.REMOVE_NODE
	end

	if imgui.radio_button("Move Node", data.editor_state == const.EDITOR_STATES.MOVE_NODE) then
		graph.clear()
		data.editor_state = const.EDITOR_STATES.MOVE_NODE
		data.action_status = const.EDITOR_STATUS.MOVE_NODE
	end

	imgui.separator()

	if imgui.radio_button("Add Edge", data.editor_state == const.EDITOR_STATES.ADD_EDGE) then
		graph.clear()
		data.editor_state = const.EDITOR_STATES.ADD_EDGE
		data.action_status = const.EDITOR_STATUS.ADD_EDGE_1
	end

	if imgui.radio_button("Add A->B Edge", data.editor_state == const.EDITOR_STATES.ADD_DIRECTIONAL_EDGE) then
		graph.clear()
		data.editor_state = const.EDITOR_STATES.ADD_DIRECTIONAL_EDGE
		data.action_status = const.EDITOR_STATUS.ADD_EDGE_1
	end

	if imgui.radio_button("Remove Edge", data.editor_state == const.EDITOR_STATES.REMOVE_EDGE) then
		graph.clear()
		data.editor_state = const.EDITOR_STATES.REMOVE_EDGE
		data.action_status = const.EDITOR_STATUS.REMOVE_EDGE
	end

	imgui.separator()

	if imgui.radio_button("Add Agent", data.editor_state == const.EDITOR_STATES.ADD_AGENT) then
		graph.clear()
		data.editor_state = const.EDITOR_STATES.ADD_AGENT
		data.action_status = const.EDITOR_STATUS.ADD_AGENT
	end

	imgui.separator()

	if imgui.button("Reset Camera") then
		msg.post(const.VIEWPORT, hash("reset"))
	end



	imgui.separator()

	imgui.end_window()
end

-- =======================================
-- STATS
-- =======================================
local function stats()
	imgui.set_next_window_size(700, 150)
	imgui.begin_window("STATS", nil, flags)

	imgui.text("Editor Status: ")
	imgui.same_line()
	imgui.text_colored(data.action_status, 0, 1, 0, 1)

	if data.stats.path_cache then
		imgui.text("Path Cache - Current Entries: " ..
			data.stats.path_cache.current_entries ..
			" | Max Capacity: " ..
			data.stats.path_cache.max_capacity .. " | Hit Rate: " .. data.stats.path_cache.hit_rate .. "%")
	end

	if data.stats.distance_cache then
		imgui.text("Distance Cache - Current Entries: " ..
			data.stats.distance_cache.current_size ..
			" | Hit Count: " ..
			data.stats.distance_cache.hit_count ..
			" | Miss Count: " ..
			data.stats.distance_cache.miss_count .. " | Hit Rate: " .. data.stats.distance_cache.hit_rate .. "%")
	end

	if data.stats.spatial_index then
		imgui.text("Spatial Index - Cell Count: " ..
			data.stats.spatial_index.cell_count ..
			" |  Edge Count: " ..
			data.stats.spatial_index.edge_count ..
			" | Avg. Edges per Cell: " ..
			data.stats.spatial_index.avg_edges_per_cell ..
			" | Max Edges per Cell: " .. data.stats.spatial_index.max_edges_per_cell)
	end
	imgui.separator()

	imgui.text_colored("Cache results are mixed. It's always better to test one path at a time!", 1, 0, 0, 1)

	imgui.end_window()
end

-- =======================================
-- NODE
-- =======================================
local function node()
	if not data.is_node_selected then
		return
	end

	imgui.set_next_window_size(400, 175)
	imgui.begin_window("NODE", nil)

	imgui.text("Pathfinder Node ID: " .. data.selected_node.pathfinder_node_id)
	imgui.text("AABB ID: " .. data.selected_node.aabb_id)
	imgui.text("UUDI: " .. data.selected_node.uuid)
	imgui.text("URL: " .. data.selected_node.url)
	imgui.set_next_item_width(250)

	changed, x, y, z = imgui.input_float3("Position", data.selected_node.position.x, data.selected_node.position.y,
		data.selected_node.position.z)

	if changed then
		data.selected_node.position.x = x
		data.selected_node.position.y = 0
		data.selected_node.position.z = z
		utils.move_selected_node(data.selected_node.position)
	end

	imgui.end_window()
end

-- =======================================
-- SETTINGS
-- =======================================
local function settings()
	imgui.set_next_window_size(475, 755)
	imgui.begin_window("SETTINGS", nil)

	data.is_window_hovered = imgui.is_window_hovered()

	imgui.begin_tab_bar("tabs")

	-- =======================================
	-- PATHS
	-- =======================================
	local paths_tab_open = imgui.begin_tab_item("Paths")
	if paths_tab_open then
		-- =======================================
		-- AGENT
		-- =======================================
		imgui.spacing()
		imgui.text_colored("AGENT", 1, 0, 0, 1)
		imgui.separator()
		if imgui.begin_combo("AGENT MODE##selectable", get_key_for_value(const.AGEND_MODE, data.agent_mode)) then
			for key, mode in pairs(const.AGEND_MODE) do
				if imgui.selectable(key, mode == data.agent_mode) then
					data.agent_mode = mode
				end
			end
			imgui.end_combo()
		end

		-- =======================================
		-- NODE TO NODE
		-- =======================================
		imgui.spacing()
		imgui.text_colored("NODE TO NODE", 1, 0, 0, 1)
		imgui.separator()

		changed, checked = imgui.checkbox("Node to Node", data.options.node_to_node.is_active)
		if changed then
			data.options.node_to_node.is_active = checked
		end

		imgui.text("Status: ")
		imgui.same_line()
		local status_color = data.path.node_to_node.status == pathfinder.PathStatus.SUCCESS and const.COLORS.GREEN or
			const.COLORS.RED
		imgui.text_colored(data.path.node_to_node.status_text, status_color.x, status_color.y, status_color.z, 1)

		imgui.set_next_item_width(250)
		changed, int_value = imgui.input_int("Start Node Id##node_to_node", data.options.node_to_node.start_node_id)
		if changed then
			data.options.node_to_node.start_node_id = int_value
		end

		imgui.set_next_item_width(250)
		local changed, int_value = imgui.input_int("Goal Node Id##node_to_node", data.options.node_to_node.goal_node_id)
		if changed then
			data.options.node_to_node.goal_node_id = int_value
		end

		imgui.set_next_item_width(250)
		local changed, int_value = imgui.input_int("Max Path Lenght##node_to_node", data.options.node_to_node.max_path)
		if changed then
			data.options.node_to_node.max_path = int_value
			print(data.options.node_to_node.max_path)
		end

		-- =======================================
		-- PROJECTED TO NODE
		-- =======================================
		imgui.spacing()
		imgui.text_colored("PROJECTED TO NODE", 1, 0, 0, 1)
		imgui.separator()

		changed, checked = imgui.checkbox("Projected to Node", data.options.projected_to_node.is_active)
		if changed then
			data.options.projected_to_node.is_active = checked
		end

		imgui.text("Status: ")
		imgui.same_line()
		local status_color = data.path.projected_to_node.status == pathfinder.PathStatus.SUCCESS and const.COLORS.GREEN or
			const.COLORS.RED
		imgui.text_colored(data.path.projected_to_node.status_text, status_color.x, status_color.y, status_color.z, 1)

		imgui.set_next_item_width(250)
		changed, int_value = imgui.input_int("Goal Node Id##projected_to_node",
			data.options.projected_to_node.goal_node_id)
		if changed then
			data.options.projected_to_node.goal_node_id = int_value
		end

		imgui.set_next_item_width(250)
		changed, int_value = imgui.input_int("Max Path Lenght##projected_to_node",
			data.options.projected_to_node.max_path)
		if changed then
			data.options.projected_to_node.max_path = int_value
		end

		-- =======================================
		-- NODE TO PROJECTED
		-- =======================================
		imgui.spacing()
		imgui.text_colored("NODE TO PROJECTED", 1, 0, 0, 1)
		imgui.separator()

		changed, checked = imgui.checkbox("Node to Projected", data.options.node_to_projected.is_active)
		if changed then
			data.options.node_to_projected.is_active = checked
		end

		imgui.text("Status: ")
		imgui.same_line()
		local status_color = data.path.node_to_projected.status == pathfinder.PathStatus.SUCCESS and const.COLORS.GREEN or
			const.COLORS.RED
		imgui.text_colored(data.path.node_to_projected.status_text, status_color.x, status_color.y, status_color.z, 1)

		imgui.set_next_item_width(250)
		changed, int_value = imgui.input_int("Start Node Id##node_to_projected",
			data.options.node_to_projected.start_node_id)
		if changed then
			data.options.node_to_projected.start_node_id = int_value
		end

		imgui.set_next_item_width(250)
		changed, int_value = imgui.input_int("Max Path Lenght##node_to_projected",
			data.options.node_to_projected.max_path)
		if changed then
			data.options.node_to_projected.max_path = int_value
		end

		-- =======================================
		-- PROJECTED TO PROJECTED
		-- =======================================
		imgui.spacing()
		imgui.text_colored("PROJECTED TO PROJECTED", 1, 0, 0, 1)
		imgui.separator()

		changed, checked = imgui.checkbox("Projected to Projected", data.options.projected_to_projected.is_active)
		if changed then
			data.options.projected_to_projected.is_active = checked
		end

		imgui.text("Status: ")
		imgui.same_line()
		local status_color = data.path.projected_to_projected.status == pathfinder.PathStatus.SUCCESS and
			const.COLORS.GREEN or const.COLORS.RED
		imgui.text_colored(data.path.projected_to_projected.status_text, status_color.x, status_color.y, status_color.z,
			1)

		imgui.set_next_item_width(250)
		changed, x, y, z = imgui.input_float3("Start Position", data.options.projected_to_projected.start_position.x,
			data.options.projected_to_projected.start_position.y, data.options.projected_to_projected.start_position.z)
		if changed then
			data.options.projected_to_projected.start_position.x = x
			data.options.projected_to_projected.start_position.y = 0
			data.options.projected_to_projected.start_position.z = z
		end

		imgui.set_next_item_width(250)
		changed, int_value = imgui.input_int("Max Path Lenght##projected_to_projected",
			data.options.projected_to_projected.max_path)
		if changed then
			data.options.projected_to_projected.max_path = int_value
		end
		imgui.spacing()

		imgui.end_tab_item()
	end

	-- =======================================
	-- SHOOTHING
	-- =======================================
	local smmothing_tab_open = imgui.begin_tab_item("Smmothing")
	if smmothing_tab_open then
		imgui.set_next_item_width(250)
		if imgui.begin_combo("Smooth Style##selectable", get_key_for_value(pathfinder.PathSmoothStyle, data.options.smoothing_config.style)) then
			for key, style in pairs(pathfinder.PathSmoothStyle) do
				if imgui.selectable(key, style == data.options.smoothing_config.style) then
					data.options.smoothing_config.style = style
					utils.update_smooth_config()
				end
			end

			imgui.end_combo()
		end

		imgui.set_next_item_width(250)
		changed, int_value = imgui.input_int("Sample for Segment", data.options.smoothing_config.bezier_sample_segment)
		if changed then
			data.options.smoothing_config.bezier_sample_segment = int_value
			utils.update_smooth_config()
		end

		if data.options.smoothing_config.style == pathfinder.PathSmoothStyle.BEZIER_QUADRATIC then
			imgui.set_next_item_width(250)
			changed, float_value = imgui.drag_float("Curve Radius", data.options.smoothing_config.bezier_curve_radius,
				0.01, 0.0, 1.0, 1)
			if changed then
				data.options.smoothing_config.bezier_curve_radius = float_value
				utils.update_smooth_config()
			end
		end

		if data.options.smoothing_config.style == pathfinder.PathSmoothStyle.BEZIER_CUBIC then
			imgui.set_next_item_width(250)
			changed, float_value = imgui.drag_float("Control Point Offset",
				data.options.smoothing_config.bezier_control_point_offset, 0.01, 0.0, 1.0, 1)
			if changed then
				data.options.smoothing_config.bezier_control_point_offset = float_value
				utils.update_smooth_config()
			end
		end

		if data.options.smoothing_config.style == pathfinder.PathSmoothStyle.BEZIER_ADAPTIVE then
			imgui.set_next_item_width(250)
			changed, float_value = imgui.drag_float("Tightness", data.options.smoothing_config.bezier_adaptive_tightness,
				0.01, 0.0, 1.0, 1)
			if changed then
				data.options.smoothing_config.bezier_adaptive_tightness = float_value
				utils.update_smooth_config()
			end

			imgui.set_next_item_width(250)
			changed, float_value = imgui.drag_float("Roundness", data.options.smoothing_config.bezier_adaptive_roundness,
				0.01, 0.0, 1.0, 1)
			if changed then
				data.options.smoothing_config.bezier_adaptive_roundness = float_value
				utils.update_smooth_config()
			end

			imgui.set_next_item_width(250)
			changed, float_value = imgui.drag_float("Max Corner Distance",
				data.options.smoothing_config.bezier_adaptive_max_corner_distance, 0.1, 0.0, 100.0, 0.1)
			if changed then
				data.options.smoothing_config.bezier_adaptive_max_corner_distance = float_value
				utils.update_smooth_config()
			end
		end

		if data.options.smoothing_config.style == pathfinder.PathSmoothStyle.CIRCULAR_ARC then
			imgui.set_next_item_width(250)
			changed, float_value = imgui.drag_float("Arc Radius", data.options.smoothing_config.bezier_arc_radius, 0.1,
				0.0, 100.0, 0.1)
			if changed then
				data.options.smoothing_config.bezier_arc_radius = float_value
				utils.update_smooth_config()
			end
		end
		imgui.end_tab_item()
	end

	imgui.end_tab_bar()
	imgui.end_window()
end

-- =======================================
-- MODALS
-- =======================================
local function file_select_modal()
	if imgui.begin_popup_modal("Select File", imgui.WINDOWFLAGS_ALWAYSAUTORESIZE) then
		imgui.begin_child("listbox", 150, 100, true)
		for i, file in ipairs(const.GRAPH_EDITOR.FILES) do
			local is_selected = (i == data.selected_file)
			if imgui.selectable(file, is_selected) then
				data.selected_file = i
			end
		end
		imgui.end_child()

		data.modals.open_file = false

		imgui.separator()
		if imgui.button("CANCEL") then
			imgui.close_current_popup()
		end

		imgui.same_line()

		if imgui.button("LOAD") then
			imgui.close_current_popup()

			file.load()
		end
		imgui.end_popup()
	end
end

local function file_save_modal()
	if imgui.begin_popup_modal("Save File", imgui.WINDOWFLAGS_ALWAYSAUTORESIZE) then
		local changed, text = imgui.input_text(".json", save_file_name)
		if changed then
			save_file_name = text
		end
		data.modals.open_save = false

		imgui.separator()
		if imgui.button("CANCEL") then
			imgui.close_current_popup()
		end

		imgui.same_line()

		if imgui.button("SAVE") then
			data.selected_file = file.add(save_file_name .. ".json")
			imgui.close_current_popup()
			file.save()
		end
		imgui.end_popup()
	end
end

local function file_export_modal()
	if imgui.begin_popup_modal("Export File", imgui.WINDOWFLAGS_ALWAYSAUTORESIZE) then
		local changed, text = imgui.input_text(".json", save_file_name)

		if changed then
			save_file_name = text
		end

		imgui.text(save_file_name .. "_nodes.json")
		imgui.text(save_file_name .. "_edges.json")

		data.modals.open_export = false
		imgui.separator()
		if imgui.button("CANCEL") then
			imgui.close_current_popup()
		end

		imgui.same_line()

		if imgui.button("SAVE") then
			data.selected_file = file.add(save_file_name .. ".json")
			imgui.close_current_popup()
			file.save()
			file.save_exports(data.export.nodes, data.export.edges)
		end
		imgui.end_popup()
	end
end

-- =======================================
-- Imgui Update
-- =======================================
function graph_imgui.update()
	--	print("want_mouse_input", imgui.want_mouse_input())
	data.want_mouse_input = imgui.want_mouse_input()

	main_menu_bar()
	--imgui.demo()
	tools()
	settings()
	stats()
	node()

	if data.modals.open_file then
		imgui.open_popup("Select File", imgui.WINDOWFLAGS_ALWAYSAUTORESIZE)
	end

	if data.modals.open_save then
		imgui.open_popup("Save File", imgui.WINDOWFLAGS_ALWAYSAUTORESIZE)
	end


	if data.modals.open_export then
		imgui.open_popup("Export File", imgui.WINDOWFLAGS_ALWAYSAUTORESIZE)
	end

	file_select_modal()
	file_save_modal()
	file_export_modal()
end

return graph_imgui

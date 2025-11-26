local data        = require("graph_editor.scripts.editor_data")
local const       = require("graph_editor.scripts.editor_const")
local graph       = require("graph_editor.scripts.editor_graph")
local graph_imgui = require("graph_editor.scripts.graph_imgui")
local agents      = require("graph_editor.scripts.editor_agents")
local draw        = require("graph_editor.scripts.editor_draw")

-- =======================================
-- MODULE
-- =======================================
local editor      = {}

function editor.init()
	graph_imgui.init()
	graph.init()
end

function editor.update(dt)
	graph_imgui.update()

	if data.options.draw.edges then
		draw.edges()
	end

	if data.options.node_to_node.is_active then
		draw.node_to_node()
	end

	if data.options.projected_to_node.is_active then
		draw.projected_to_node()
	end

	if data.options.node_to_projected.is_active then
		draw.node_to_projected()
	end

	if data.options.projected_to_projected.is_active then
		draw.projected_to_projected()
	end

	data.stats = pathfinder.get_stats()
	agents.update(dt)
end

function editor.input(action_id, action)
	if action.screen_x then
		data.mouse_position = camera.screen_to_world(vmath.vector3(action.screen_x, action.screen_y, data.camera_zoom), const.VIEWPORT_CAMERA)
		data.mouse_position.y = 0
		go.set_position(data.mouse_position, const.MOUSE)
	end

	graph.input(action_id, action)
end

return editor

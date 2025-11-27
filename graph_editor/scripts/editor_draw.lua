local utils = require("graph_editor.scripts.editor_utils")
local data  = require("graph_editor.scripts.editor_data")
local const = require("graph_editor.scripts.editor_const")
-- =======================================
-- MODULE
-- =======================================
local draw  = {}

-- =======================================
-- DRAW EDGES
-- =======================================
function draw.edges()
	for _, edge in pairs(data.edges) do
		local from, to = utils.get_edge_positions(edge.from_node_id, edge.to_node_id)
		msg.post("@render:", "draw_line", { start_point = from, end_point = to, color = vmath.vector4(0, 1, 0, 1) })
	end
end

function draw.node_to_node()
	local smooth_path = data.options.draw.smooth_path and data.path_smoothing_id or nil



	data.path.node_to_node.size,
	data.path.node_to_node.status,
	data.path.node_to_node.status_text,
	data.path.node_to_node.path = pathfinder.find_node_to_node(
		data.options.node_to_node.start_node_id,
		data.options.node_to_node.goal_node_id,
		data.options.node_to_node.max_path,
		smooth_path)

	if data.path.node_to_node.status == pathfinder.PathStatus.SUCCESS and data.options.draw.paths then
		for i = 1, data.path.node_to_node.size - 1, 1 do
			local from_node = data.path.node_to_node.path[i]
			local to_node = data.path.node_to_node.path[i + 1]

			local start_point = vmath.vector3(from_node.x, 0, from_node.y)
			local end_point = vmath.vector3(to_node.x, 0, to_node.y)

			msg.post("@render:", "draw_line", { start_point = start_point, end_point = end_point, color = vmath.vector4(1, 0, 0, 1) })
		end
	end
end

function draw.projected_to_node()
	local smooth_path = data.options.draw.smooth_path and data.path_smoothing_id or nil

	data.path.projected_to_node.size,
	data.path.projected_to_node.status,
	data.path.projected_to_node.status_text,
	data.path.projected_to_node.entry_point,
	data.path.projected_to_node.path =
		pathfinder.find_projected_to_node(
			data.mouse_position.x,
			data.mouse_position.z,
			data.options.projected_to_node.goal_node_id,
			data.options.projected_to_node.max_path,
			smooth_path)

	if data.path.projected_to_node.status == pathfinder.PathStatus.SUCCESS and data.options.draw.paths then
		local entry_point = vmath.vector3(data.path.projected_to_node.entry_point.x, 0, data.path.projected_to_node.entry_point.y)

		-- Draw line from mouse position to entry point
		msg.post("@render:", "draw_line", { start_point = data.mouse_position, end_point = entry_point, color = vmath.vector4(1, 0, 0, 1) })

		-- Draw line from entry point to first waypoint
		local first_node = data.path.projected_to_node.path[1]

		msg.post("@render:", "draw_line", { start_point = entry_point, end_point = vmath.vector3(first_node.x, 0, first_node.y), color = vmath.vector4(1, 0, 0, 1) })

		-- Draw lines between remaining waypoints
		for i = 1, data.path.projected_to_node.size - 1, 1 do
			local from_node = data.path.projected_to_node.path[i]
			local to_node = data.path.projected_to_node.path[i + 1]

			local start_point = vmath.vector3(from_node.x, 0, from_node.y)
			local end_point = vmath.vector3(to_node.x, 0, to_node.y)

			msg.post("@render:", "draw_line", { start_point = start_point, end_point = end_point, color = vmath.vector4(1, 0, 0, 1) })
		end
	end
end

function draw.node_to_projected()
	local smooth_path = data.options.draw.smooth_path and data.path_smoothing_id or nil

	data.path.node_to_projected.size,
	data.path.node_to_projected.status,
	data.path.node_to_projected.status_text,
	data.path.node_to_projected.exit_point,
	data.path.node_to_projected.path =
		pathfinder.find_node_to_projected(
			data.options.node_to_projected.start_node_id,
			data.mouse_position.x,
			data.mouse_position.z,
			data.options.node_to_projected.max_path,
			smooth_path)

	if data.path.node_to_projected.status == pathfinder.PathStatus.SUCCESS and data.options.draw.paths then
		local exit_point = vmath.vector3(data.path.node_to_projected.exit_point.x, 0, data.path.node_to_projected.exit_point.y)

		-- Draw lines between remaining waypoints
		for i = 1, data.path.node_to_projected.size - 1, 1 do
			local from_node = data.path.node_to_projected.path[i]
			local to_node = data.path.node_to_projected.path[i + 1]

			local start_point = vmath.vector3(from_node.x, 0, from_node.y)
			local end_point = vmath.vector3(to_node.x, 0, to_node.y)

			msg.post("@render:", "draw_line", { start_point = start_point, end_point = end_point, color = vmath.vector4(1, 0, 0, 1) })
		end

		-- Draw line from exit point to mouse position
		msg.post("@render:", "draw_line", { start_point = exit_point, end_point = data.mouse_position, color = vmath.vector4(1, 0, 0, 1) })

		-- Draw line from entry point to first waypoint
		local last_node = data.path.node_to_projected.path[data.path.node_to_projected.size]

		msg.post("@render:", "draw_line", { start_point = vmath.vector3(last_node.x, 0, last_node.y), end_point = exit_point, color = vmath.vector4(1, 0, 0, 1) })
	end
end

function draw.projected_to_projected()
	local smooth_path = data.options.draw.smooth_path and data.path_smoothing_id or nil

	data.path.projected_to_projected.size,
	data.path.projected_to_projected.status,
	data.path.projected_to_projected.status_text,
	data.path.projected_to_projected.entry_point,
	data.path.projected_to_projected.exit_point,
	data.path.projected_to_projected.path =
		pathfinder.find_projected_to_projected(
			data.options.projected_to_projected.start_position.x,
			data.options.projected_to_projected.start_position.z,
			data.mouse_position.x,
			data.mouse_position.z,
			data.options.projected_to_projected.max_path,
			smooth_path)


	if data.path.projected_to_projected.status == pathfinder.PathStatus.SUCCESS and data.options.draw.paths then
		local entry_point = vmath.vector3(data.path.projected_to_projected.entry_point.x, 0, data.path.projected_to_projected.entry_point.y)
		local exit_point = vmath.vector3(data.path.projected_to_projected.exit_point.x, 0, data.path.projected_to_projected.exit_point.y)


		-- Draw line from start point to entry point
		msg.post("@render:", "draw_line", { start_point = data.options.projected_to_projected.start_position, end_point = entry_point, color = vmath.vector4(1, 0, 0, 1) })

		-- Draw line from entry point to first waypoint
		local start_node = data.path.projected_to_projected.path[1]

		msg.post("@render:", "draw_line", { start_point = entry_point, end_point = vmath.vector3(start_node.x, 0, start_node.y), color = vmath.vector4(1, 0, 0, 1) })

		-- Draw lines between remaining waypoints
		for i = 1, data.path.projected_to_projected.size - 1, 1 do
			local from_node = data.path.projected_to_projected.path[i]
			local to_node = data.path.projected_to_projected.path[i + 1]

			local start_point = vmath.vector3(from_node.x, 0, from_node.y)
			local end_point = vmath.vector3(to_node.x, 0, to_node.y)

			msg.post("@render:", "draw_line", { start_point = start_point, end_point = end_point, color = vmath.vector4(1, 0, 0, 1) })
		end

		-- Draw line from exit point to mouse position

		msg.post("@render:", "draw_line", { start_point = exit_point, end_point = data.mouse_position, color = vmath.vector4(1, 0, 0, 1) })

		-- Draw line from entry point to first waypoint
		local last_node = data.path.projected_to_projected.path[data.path.projected_to_projected.size]

		msg.post("@render:", "draw_line", { start_point = vmath.vector3(last_node.x, 0, last_node.y), end_point = exit_point, color = vmath.vector4(1, 0, 0, 1) })
	end
end

return draw

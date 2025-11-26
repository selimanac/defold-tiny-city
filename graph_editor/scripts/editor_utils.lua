local const     = require("graph_editor.scripts.editor_const")
local data      = require("graph_editor.scripts.editor_data")
local collision = require("graph_editor.scripts.editor_collision")

-- =======================================
-- MODULE
-- =======================================
local utils     = {}

function utils.round3(v)
	return math.floor(v * 1000 + 0.5) / 1000
end

function utils.vec3_to_table(v)
	return { v.x, v.y, v.z }
end

function utils.get_node_id_from_pathfinder(pathfinder_id)
	return data.lookup.pathfinder_to_node[pathfinder_id]
end

function utils.get_node_from_pathfinder_id(pathfinder_id)
	local node_id = utils.get_node_id_from_pathfinder(pathfinder_id)
	return data.nodes[node_id]
end

function utils.get_node_id_from_aabb(aabb_id)
	return data.lookup.aabb_to_node[aabb_id]
end

function utils.get_node_from_aabb(aabb_id)
	local node_id = utils.get_node_id_from_aabb(aabb_id)
	return data.nodes[node_id]
end

function utils.remove_node_with_aabb(aabb_id)
	local node_id = utils.get_node_id_from_aabb(aabb_id)
	data.lookup.aabb_to_node[aabb_id] = nil
	data.lookup.pathfinder_to_node[data.nodes[node_id].pathfinder_node_id] = nil
	data.nodes[node_id] = nil
end

function utils.get_edge_id_from_aabb(aabb_id)
	return data.lookup.aabb_to_edge[aabb_id]
end

function utils.get_edge_from_aabb(aabb_id)
	local edge_id = utils.get_edge_id_from_aabb(aabb_id)
	return data.edges[edge_id]
end

function utils.remove_edge_with_aabb(aabb_id)
	local edge_id = utils.get_edge_id_from_aabb(aabb_id)

	data.lookup.aabb_to_edge[aabb_id] = nil
	data.edges[edge_id] = nil
end

function utils.get_edge(uuid)
	return data.edges[uuid]
end

function utils.remove_edge(edge)
	pathfinder.remove_edge(edge.from_node_id, edge.to_node_id, edge.bidirectional)
	collision.remove(edge.aabb_id)

	-- REMOVE FROM NODES
	local from_node_id = data.lookup.pathfinder_to_node[edge.from_node_id]
	local from_node = data.nodes[from_node_id]
	from_node.edges[edge.uuid] = nil

	local to_node_id = data.lookup.pathfinder_to_node[edge.to_node_id]
	local to_node = data.nodes[to_node_id]
	to_node.edges[edge.uuid] = nil

	-- REMOVE DIRECTION
	if edge.url then
		go.delete(edge.url)
	end

	data.lookup.aabb_to_edge[edge.aabb_id] = nil
	data.edges[edge.uuid] = nil
end

function utils.rect_from_points(p1, p2)
	-- Center of rectangle
	local center = vmath.vector3(
		(p1.x + p2.x) * 0.5,
		0,
		(p1.y + p2.y) * 0.5
	)

	-- Width and height (absolute difference)
	local width = math.abs(p2.x - p1.x)
	local height = math.abs(p2.y - p1.y)

	return center, width, height
end

local function update_collision_edges(node)
	for edge_uuid, edge_type in pairs(node.edges) do
		local edge = utils.get_edge(edge_uuid)
		local from_node_position = pathfinder.get_node_position(edge.from_node_id)
		local to_node_position = pathfinder.get_node_position(edge.to_node_id)

		local center, width, height = utils.rect_from_points(from_node_position, to_node_position)

		local aabb = {
			aabb_id = edge.aabb_id,
			position = center,
			size = { width = width, height = 1, depth = height }
		}

		collision.update_aabb(aabb)
	end
end

function utils.get_edge_positions(from_node_id, to_node_id)
	local from_v2 = pathfinder.get_node_position(from_node_id)
	local to_v2 = pathfinder.get_node_position(to_node_id)
	return vmath.vector3(from_v2.x, 0, from_v2.y), vmath.vector3(to_v2.x, 0, to_v2.y)
end

function utils.get_directional_transform(edge)
	local from, to = utils.get_edge_positions(edge.from_node_id, edge.to_node_id)
	local center = (from + to) * 0.5
	local dir = to - from
	local angle = math.atan2(dir.x, dir.z) - math.pi * 0.5
	center.y = 0.0

	return center, angle
end

function utils.set_directional_transform(edge)
	local center, angle = utils.get_directional_transform(edge)
	go.set_position(center, edge.url)
	go.set_rotation(vmath.quat_rotation_y(angle), edge.url)
end

function utils.add_edge_directions(edge)
	local center, angle = utils.get_directional_transform(edge)
	local direction_url = factory.create(const.FACTORIES.DIRECTION, center, vmath.quat_rotation_y(angle))
	edge.url = direction_url
end

function utils.get_node_edges(node, bidirectional)
	local node_edges = {}

	for edge_uuid, edge_type in pairs(node.edges) do
		local edge = utils.get_edge(edge_uuid)
		if bidirectional == nil or edge.bidirectional == bidirectional then
			table.insert(node_edges, edge)
		end
	end
	return node_edges
end

function utils.set_nodes_visiblity()
	local status = data.options.draw.nodes and "enable" or "disable"
	for _, node in pairs(data.nodes) do
		msg.post(node.url, status)
	end

	for _, edge in pairs(data.edges) do
		msg.post(edge.url, status)
	end
end

function utils.update_smooth_config()
	pathfinder.update_path_smoothing(data.path_smoothing_id, data.options.smoothing_config)
end

function utils.remove_node_edges(node)
	local to_remove = {}

	for edge_uuid in pairs(node.edges) do
		to_remove[#to_remove + 1] = edge_uuid
	end

	for _, edge_uuid in ipairs(to_remove) do
		local edge = utils.get_edge(edge_uuid)
		utils.remove_edge(edge)
	end
end

function utils.update_node(node_position)
	node_position.y = 0
	data.selected_node.position = node_position
	go.set_position(node_position, data.selected_node.url)
	pathfinder.move_node(data.selected_node.pathfinder_node_id, node_position.x, node_position.z)

	--local screen_position = camera.world_to_screen(node_position, const.VIEWPORT_CAMERA)
	--msg.post(data.selected_node.label_url, "update_data", { screen_position = vmath.vector3(screen_position.x, screen_position.y + 16, 0) })

	update_collision_edges(data.selected_node)
end

function utils.move_selected_node(node_position)
	local node_edges = utils.get_node_edges(data.selected_node, false)

	for _, edge in pairs(node_edges) do
		utils.set_directional_transform(edge)
	end

	utils.update_node(node_position)
end

-- Set window title
function utils.set_title(text)
	text = text and text or "Graph Pathfinder Editor"
	window.set_title(text)
end

return utils

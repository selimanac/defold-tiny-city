local const = require("tiny-city.scripts.lib.const")
local data  = require "tiny-city.scripts.lib.data"

-- =================================
-- MODULE
-- =================================
local graph = {}

local function load_graph(file_name)
	if not file_name or type(file_name) ~= "string" or not string.find(file_name, '%S') then
		local error_msg = "Invalid file_name parameter (empty or whitespace)"
		print("Load error:", error_msg)
		return nil, error_msg
	end

	local edges_path = "/data/" .. file_name .. "_edges.json"
	local nodes_path = "/data/" .. file_name .. "_nodes.json"

	-- Load edges file
	local edges_json, edges_load_error = sys.load_resource(edges_path)
	if edges_load_error then
		local error_msg = string.format("Cannot load edges file '%s': %s", edges_path, edges_load_error)
		print("Load error:", error_msg)
		return nil, error_msg
	end

	-- Load nodes file
	local nodes_json, nodes_load_error = sys.load_resource(nodes_path)
	if nodes_load_error then
		local error_msg = string.format("Cannot load nodes file '%s': %s", nodes_path, nodes_load_error)
		print("Load error:", error_msg)
		return nil, error_msg
	end

	-- Decode JSON with error handling
	local nodes_success, nodes_data = pcall(json.decode, nodes_json)
	if not nodes_success then
		local error_msg = string.format("JSON decode error for nodes: %s", nodes_data)
		print("Parse error:", error_msg)
		return nil, error_msg
	end

	local edges_success, edges_data = pcall(json.decode, edges_json)
	if not edges_success then
		local error_msg = string.format("JSON decode error for edges: %s", edges_data)
		print("Parse error:", error_msg)
		return nil, error_msg
	end

	print("Successfully loaded graph:", file_name)

	return { nodes = nodes_data, edges = edges_data }, nil
end

local function generate(loaded_nodes, loaded_edges)
	-- Step 1: Collect and sort node UUIDs by pathfinder_node_id
	-- This ensures nodes are added in a consistent order
	local ordered_nodes = {}
	for uuid, _ in pairs(loaded_nodes) do
		ordered_nodes[#ordered_nodes + 1] = uuid
	end

	table.sort(ordered_nodes, function(a, b)
		return loaded_nodes[a].pathfinder_node_id < loaded_nodes[b].pathfinder_node_id
	end)

	-- Step 2: Initialize result tables
	local nodes = {}
	local edges = loaded_edges

	-- Step 3: Add nodes to pathfinder and build lookup table
	-- Note: pathfinder.add_node() assigns new IDs, so we need to update references
	for _, uuid in ipairs(ordered_nodes) do
		local node = loaded_nodes[uuid]

		-- Add node to pathfinder (returns new pathfinder_node_id)
		node.pathfinder_node_id = pathfinder.add_node(node.position.x, node.position.y)

		-- Store node indexed by its pathfinder ID for easy lookup
		nodes[node.pathfinder_node_id] = node

		-- Update edge references to use new pathfinder node IDs
		if node.edges then
			for edge_uuid, edge_type in pairs(node.edges) do
				edges[edge_uuid][edge_type] = node.pathfinder_node_id
			end
		end
	end

	-- Step 4: Add all edges to pathfinder
	-- Convert edge table to array format required by pathfinder.add_edges()
	local temp_edges = {}
	for _, edge in pairs(edges) do
		table.insert(temp_edges, edge)
	end

	pathfinder.add_edges(temp_edges)

	-- Return nodes indexed by pathfinder_node_id and updated edges
	return nodes, edges
end

function graph.init()
	local loaded_data = load_graph("map")

	local node_count = 0
	for _ in pairs(loaded_data.nodes) do
		node_count = node_count + 1
	end

	local max_nodes             = node_count
	local max_gameobject_nodes  = nil
	local max_edges_per_node    = 16
	local heap_pool_block_size  = 32
	local max_cache_path_length = 256

	pathfinder.init(max_nodes, max_gameobject_nodes, max_edges_per_node, heap_pool_block_size, max_cache_path_length)

	data.path_smoothing_id = pathfinder.add_path_smoothing(const.SMOOTHING_CONFIG)

	data.nodes, data.edges = generate(loaded_data.nodes, loaded_data.edges)
end

return graph

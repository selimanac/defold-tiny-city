local const = require("tiny-city.scripts.lib.const")
local data  = require "tiny-city.scripts.lib.data"

-- =================================
-- MODULE
-- =================================
local graph = {}

local function load()
	local error = ""
	local edges_json = ""
	local nodes_json = ""
	edges_json, error = sys.load_resource("/data/map_edges.json")
	if error then
		print("Error loading edges:", error)
		return nil
	end

	nodes_json, error = sys.load_resource("/data/map_nodes.json")
	if error then
		print("Error loading nodes:", error)
		return nil
	end

	local nodes_data = json.decode(nodes_json)
	local edges_data = json.decode(edges_json)

	return { nodes = nodes_data, edges = edges_data }
end

function graph.init()
	local loaded_data           = load()
	local max_nodes             = #loaded_data.nodes
	local max_gameobject_nodes  = nil
	local max_edges_per_node    = 16
	local heap_pool_block_size  = 32
	local max_cache_path_length = 256

	pathfinder.init(max_nodes, max_gameobject_nodes, max_edges_per_node, heap_pool_block_size, max_cache_path_length)

	data.path_smoothing_id = pathfinder.add_path_smoothing(const.SMOOTHING_CONFIG)

	-- !!!! IMPORTANT
	-- This is not the reccomended way of loading nodes and edges. Pathfinder arrays are index based but still IDs might change.
	-- UUID based importer might be a better solution
	data.nodes = pathfinder.add_nodes(loaded_data.nodes)
	data.edges = loaded_data.edges
	pathfinder.add_edges(data.edges)

	for i, v in ipairs(data.nodes) do
		local node_position = vmath.vector3(loaded_data.nodes[i].x, 0, loaded_data.nodes[i].y)
		local temp_node = {
			position = node_position,
			pathfinder_node_id = v,
		}

		data.nodes[i] = temp_node

		table.insert(data.lookup.pathfinder_node_id_to_index, v, i)
		table.insert(data.lookup.index_to_pathfinder_node_id, i, v)
	end
end

return graph

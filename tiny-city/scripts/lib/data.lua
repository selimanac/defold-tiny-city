-- =================================
-- MODULE
-- =================================
local data = {}
-- =================================
-- VARS
-- =================================

data.nodes = {}
data.edges = {}


data.path_smoothing_id = 0
data.debug = true

data.vehicles = {}


data.lookup = {
	aabb_to_vehicle = {},
	hash_to_vehicle = {},
	pathfinder_node_id_to_index = {},
	index_to_pathfinder_node_id = {},
	vehicle_list = {}
}

-- Node reservation system
-- Maps node_id -> vehicle_id that has reserved this node
data.node_reservations = {}
return data

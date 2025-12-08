local const            = require "tiny-city.scripts.lib.const"
-- =================================
-- MODULE
-- =================================
local data             = {}

-- =================================
-- VARS
-- =================================
data.nodes             = {}
data.edges             = {}
data.node_reservations = {}
data.path_smoothing_id = 0
data.debug             = true
data.vehicles          = {}
data.lookup            = {
	aabb_to_vehicle = {},
	--hash_to_vehicle = {},
	pathfinder_node_id_to_index = {},
	index_to_pathfinder_node_id = {},
	vehicle_list = {}
}

--data.camera_zoom       = 20
data.cameras           = {}
data.current_camera    = const.CAMERA.MAIN
return data

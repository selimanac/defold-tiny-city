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
	vehicle_list = {}
}

data.cameras           = {}
data.current_camera    = const.CAMERA.MAIN
return data

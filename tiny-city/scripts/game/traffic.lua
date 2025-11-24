local traffic_lights = require "tiny-city.scripts.game.traffic_lights"
local vehicles       = require("tiny-city.scripts.game.vehicles")
-- =================================
-- MODULE
-- =================================
local traffic        = {}


function traffic.init()
	traffic_lights.init()
	vehicles.init()
end

return traffic

local graph       = require("tiny-city.scripts.lib.graph")
local collision   = require("tiny-city.scripts.lib.collision")
local traffic     = require("tiny-city.scripts.game.traffic")
local game_camera = require("tiny-city.scripts.lib.game_camera")
local birds       = require("tiny-city.scripts.game.birds")
local plane       = require("tiny-city.scripts.game.plane")
local audio       = require("tiny-city.scripts.lib.audio")

-- =================================
-- MODULE
-- =================================
local manager     = {}

function manager.init()
	game_camera.init()
	birds.init()
	plane.init()
	collision.init()
	graph.init()
	traffic.init()
	audio.init()
end

function manager.update(dt)
	traffic.update(dt)
end

function manager.fixed_update(dt)
	plane.update(dt)
end

function manager.input(action_id, action)
	game_camera.input(action_id, action)
end

return manager

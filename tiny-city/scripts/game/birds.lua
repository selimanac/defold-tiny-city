local birds     = {}

local container = msg.url()
local to        = vmath.vector3(-37.0, 3, 15)
local from      = vmath.vector3()

-- Lazy birds
function birds.stop()
	msg.post(container, "disable")
	timer.delay(5, false, function()
		go.set_position(from, container)
		birds.start()
	end)
end

function birds.start()
	msg.post(container, "enable")
	go.animate(container, "position", go.PLAYBACK_ONCE_FORWARD, to, go.EASING_LINEAR, 25, 0, function()
		birds.stop()
	end)
end

function birds.init()
	container = msg.url("/birds")
	from = go.get_position(container)
	birds.start()
end

return birds

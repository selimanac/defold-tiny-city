local const            = {}

const.EPSILON          = 0.0001 -- Minimum distance for movement calculations
const.HUGE             = math.huge
const.CAMERA           = msg.url()
const.COLORS           = {
	RED       = vmath.vector4(1, 0, 0, 1),
	GREEN     = vmath.vector4(0, 1, 0, 1),
	YELLOW    = vmath.vector4(1, 1, 0, 1),
	BLUE      = vmath.vector4(0, 0, 1, 1),
	BLACK     = vmath.vector4(0, 0, 0, 1),
	DARK_GRAY = vmath.vector4(0.3, 0.3, 0.3, 1)
}

const.SMOOTHING_CONFIG = {
	style                               = pathfinder.PathSmoothStyle.BEZIER_QUADRATIC,
	bezier_sample_segment               = 8, -- Number of segments per curve
	bezier_control_point_offset         = 0.3, -- For bezier_cubic style
	bezier_curve_radius                 = 0.8, -- For bezier_quadratic style (active)
	bezier_adaptive_tightness           = 0.1, -- For bezier_adaptive style
	bezier_adaptive_roundness           = 0.3, -- For bezier_adaptive style
	bezier_adaptive_max_corner_distance = 20.0, -- For bezier_adaptive style
	bezier_arc_radius                   = 0.3, -- For circular_arc style
}


const.VEHICLE_STATE = {
	INACTIVE       = 0, -- Not in navigation system
	ACTIVE         = 1, -- Following path
	PAUSED         = 2, -- Paused by application
	REPLANNING     = 3, -- Detected invalidation, finding new path
	ARRIVED        = 4, -- Reached goal,
	WAITTING_ORDER = 5
}

const.SPEED_LIMITS = {
	MID  = 0.7,
	HIGH = 1.5
}


const.VEHICLE_TYPE = {
	AMBULANCE = {
		SPEED             = 0.5,
		MAX_SPEED         = 2.0,
		FACTORY           = "/vehicles/factories#ambulance",
		ROTATION_SPEED    = 5.0,
		ACCELERATION_RATE = 0.3,
		BRAKE_RATE        = 7.0,
	},

	POLICE = {
		SPEED             = 0.5,
		MAX_SPEED         = 2.2,
		FACTORY           = "/vehicles/factories#police",
		ROTATION_SPEED    = 5.0,
		ACCELERATION_RATE = 0.3,
		BRAKE_RATE        = 7.0,
	},
	TAXI = {
		SPEED             = 0.1,
		MAX_SPEED         = 2.9,
		FACTORY           = "/vehicles/factories#taxi",
		ROTATION_SPEED    = 5.0,
		ACCELERATION_RATE = 0.4,
		BRAKE_RATE        = 7.0,
	},
	VAN = {
		SPEED             = 0.5,
		MAX_SPEED         = 1.2,
		FACTORY           = "/vehicles/factories#van",
		ROTATION_SPEED    = 5.0,
		ACCELERATION_RATE = 0.4,
		BRAKE_RATE        = 7.0,

	},
	FIRE = {
		SPEED             = 0.5,
		MAX_SPEED         = 3.0,
		FACTORY           = "/vehicles/factories#fire",
		ROTATION_SPEED    = 5.0,
		ACCELERATION_RATE = 0.3,
		BRAKE_RATE        = 7.0,

	},
	GARBAGE = {
		SPEED             = 0.5,
		MAX_SPEED         = 0.7,
		FACTORY           = "/vehicles/factories#garbage",
		ROTATION_SPEED    = 5.0,
		ACCELERATION_RATE = 0.4,
		BRAKE_RATE        = 7.0,

	},
	SEDAN = {
		SPEED             = 1.5,
		MAX_SPEED         = 2.8,
		FACTORY           = "/vehicles/factories#sedan",
		ROTATION_SPEED    = 5.0,
		ACCELERATION_RATE = 0.5,
		BRAKE_RATE        = 7.0,

	},
	SUV = {
		SPEED             = 0.5,
		MAX_SPEED         = 1.5,
		FACTORY           = "/vehicles/factories#suv",
		ROTATION_SPEED    = 5.0,
		ACCELERATION_RATE = 0.4,
		BRAKE_RATE        = 7.0,

	},
	SUV_CLASSIC = {
		SPEED             = 0.5,
		MAX_SPEED         = 1.4,
		FACTORY           = "/vehicles/factories#suv_classic",
		ROTATION_SPEED    = 5.0,
		ACCELERATION_RATE = 0.4,
		BRAKE_RATE        = 7.0,

	},
	TRUCK = {
		SPEED             = 0.5,
		MAX_SPEED         = 1.1,
		FACTORY           = "/vehicles/factories#truck",
		ROTATION_SPEED    = 5.0,
		ACCELERATION_RATE = 0.4,
		BRAKE_RATE        = 7.0,

	},
}



const.TRAFFIC_LIGHT_STATE = {
	RED = 0,
	YELLOW = 1,
	GREEN = 2,
}

-- Vehicle control constants for brake and throttle system
const.VEHICLE_CONTROL = {


	-- Distance-based braking zones (in units)
	-- These are base values - will be scaled based on vehicle speed
	CRITICAL_DISTANCE                  = 0.3, -- Emergency stop zone (increased from 0.5)
	NEAR_DISTANCE                      = 0.5, -- Heavy braking zone (increased from 1.0)
	MEDIUM_DISTANCE                    = 0.7, -- Moderate braking zone (increased from 2.0)
	FAR_DISTANCE                       = 1.0, -- Light braking/coasting zone (increased from 3.0)

	-- Crossing detection threshold
	CROSSING_DOT_THRESHOLD             = 0.2, -- Dot product threshold for crossing detection
	CROSSING_DISTANCE                  = 1.0, -- Max distance to consider crossing
	CROSSING_BRAKE_MULTIPLIER          = 0.5, -- Reduce effective distance when crossing

	-- Raycast offset (start raycast from front of vehicle, not center)
	RAYCAST_FORWARD_OFFSET             = 0.3, -- Units ahead of vehicle center

	OPPOSITE_DIRECTION_THRESHOLD       = -0.1,
	OPPOSITE_DIRECTION_BREAK_THRESHOLD = 0.4,

	ROTATION_SPEED_THRESHOLD           = 0.01,
	ARRIVAL_THRESHOLD                  = 0.3
}

const.TRIGGERS =
{
	KEY_1 = hash("KEY_1"),
	MOUSE_BUTTON_LEFT = hash("mouse_button_left"),
	MOUSE_WHEEL_UP = hash("mouse_wheel_up"),
	MOUSE_WHEEL_DOWN = hash("mouse_wheel_down"),
	MOUSE_BUTTON_2 = hash("MOUSE_BUTTON_2"),
	MOUSE_BUTTON_RIGHT = hash("mouse_button_right"),
}


return const

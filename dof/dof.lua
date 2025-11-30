-- ============================
-- MODULE: Depth of Field (DoF)
-- ============================
---
--- @module dof
local dof                  = {}

local dof_params           = vmath.vector4()
local focus_point          = vmath.vector4()
local gaussian_blur_params = vmath.vector4()
local box_blur_params      = vmath.vector4()
local camera_params        = vmath.vector4()

local IDENTITY             = vmath.matrix4()
local CONSTANTS            = {
	min_distance         = 1.0, -- 3D distance where blur starts
	max_distance         = 5.0, -- 3D distance where blur reaches maximum

	focus_x              = 0.5, -- Focus point X in screen space (0.0-1.0, 0.5 = center)
	focus_y              = 0.5, -- Focus point Y in screen space (0.0-1.0, 0.5 = center)

	-- Box blur
	blur_size            = 2, -- Box blur kernel size
	blur_separation      = 1.0, -- Box blur sample separation

	-- Gaussian blur
	gaussian_sigma       = 2.0, -- controls blur strength
	gaussian_kernel_size = 4, -- number of samples in each direction

	-- Camera parameters for depth linearization
	near_plane           = 0.1, -- Camera near plane distance
	far_plane            = 100.0, -- Camera far plane distance

	-- DoF mode and screen-space parameters
	dof_mode             = 0, -- 0=depth-only, 1=radial hybrid, 2=circular region
	screen_weight        = 2.0, -- screen-space influence for radial hybrid mode
	focus_radius         = 0.15 -- screen-space radius for circular region mode (0.0-1.0)
}


function dof.set_focus(focus_x, focus_y)
	focus_point.x = focus_x
	focus_point.y = focus_y
end

function dof.set_distance(min_distance, max_distance)
	dof_params.x = min_distance
	dof_params.y = max_distance
end

function dof.set_gaussian_blur(gaussian_sigma, gaussian_kernel_size)
	gaussian_blur_params.x = gaussian_sigma
	gaussian_blur_params.y = gaussian_kernel_size
end

function dof.set_box_blur(blur_size, blur_separation)
	box_blur_params.x = blur_size
	box_blur_params.y = blur_separation
end

function dof.set_camera_params(near_plane, far_plane)
	camera_params.x = near_plane
	camera_params.y = far_plane
end

function dof.set_dof_mode(mode, screen_weight, focus_radius)
	dof_params.w = mode or 0
	focus_point.z = screen_weight or CONSTANTS.screen_weight
	focus_point.w = focus_radius or CONSTANTS.focus_radius
end

function dof.init(self)
	self.predicates["dof_rt"] = render.predicate({ "dof_rt" })

	-- RENDER TARGET BUFFER PARAMETERS
	local color_params        = {
		format = graphics.TEXTURE_FORMAT_RGBA,
		width = self.state.width,
		height = self.state.height,
		min_filter = graphics.TEXTURE_FILTER_LINEAR,
		mag_filter = graphics.TEXTURE_FILTER_LINEAR,
		u_wrap = graphics.TEXTURE_WRAP_CLAMP_TO_EDGE,
		v_wrap = graphics.TEXTURE_WRAP_CLAMP_TO_EDGE
	}

	local depth_params        = {
		format     = graphics.TEXTURE_FORMAT_DEPTH,
		width      = self.state.width,
		height     = self.state.height,
		min_filter = graphics.TEXTURE_FILTER_NEAREST,
		mag_filter = graphics.TEXTURE_FILTER_NEAREST,
		u_wrap     = graphics.TEXTURE_WRAP_CLAMP_TO_EDGE,
		v_wrap     = graphics.TEXTURE_WRAP_CLAMP_TO_EDGE,
		flags      = render.TEXTURE_BIT -- Create depth buffer as a texture so we can sample it
	}

	self.dof_blur_rt          = render.render_target(
		"dof_blur",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = color_params,
		})

	-- Intermediate render target for horizontal Gaussian blur pass
	self.dof_blur_h_rt        = render.render_target(
		"dof_blur_h",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = color_params,
		})

	self.scene_rt             = render.render_target(
		"scene",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = color_params,
			[graphics.BUFFER_TYPE_DEPTH_BIT] = depth_params
		})


	-- CONSTANTS
	self.dof_constant_buffer = render.constant_buffer()

	-- Set DoF parameters (depth-based)
	dof_params = vmath.vector4(
		CONSTANTS.min_distance,
		CONSTANTS.max_distance,
		1.0,         -- enabled
		CONSTANTS.dof_mode -- mode: 0=depth-only, 1=radial hybrid, 2=circular region
	)
	self.dof_constant_buffer.dof_params = dof_params

	focus_point = vmath.vector4(
		CONSTANTS.focus_x,
		CONSTANTS.focus_y,
		CONSTANTS.screen_weight, -- screen-space weight for radial hybrid mode
		CONSTANTS.focus_radius -- focus radius for circular region mode
	)
	self.dof_constant_buffer.focus_point = focus_point

	-- Gaussian blur parameters (default)
	gaussian_blur_params = vmath.vector4(
		CONSTANTS.gaussian_sigma,
		CONSTANTS.gaussian_kernel_size,
		0, 0
	)
	self.dof_constant_buffer.blur_params = gaussian_blur_params

	-- Camera parameters for depth linearization
	camera_params = vmath.vector4(
		CONSTANTS.near_plane,
		CONSTANTS.far_plane,
		0, 0
	)
	self.dof_constant_buffer.camera_params = camera_params
end

function dof.render_update(self)
	self.dof_constant_buffer.dof_params = dof_params
	self.dof_constant_buffer.focus_point = focus_point
	self.dof_constant_buffer.blur_params = gaussian_blur_params
	self.dof_constant_buffer.camera_params = camera_params
end

function dof.render(self, state, predicates)
	-- ==================================================================
	-- DOF - Set View and Projection
	-- ==================================================================
	render.set_view(IDENTITY)
	render.set_projection(IDENTITY)
	render.set_viewport(0, 0, state.window_width, state.window_height)
	-- ==================================================================

	-- ==================================================================
	-- DOF - Gaussian blur
	-- ==================================================================
	-- Pass 1: Horizontal
	render.set_render_target(self.dof_blur_h_rt)
	render.set_render_target_size(self.dof_blur_h_rt, state.window_width, state.window_height)
	render.enable_material("dof_gaussian_blur_h")
	render.enable_texture("tex0", self.scene_rt, graphics.BUFFER_TYPE_COLOR0_BIT)
	render.draw(predicates.dof_rt, { constants = self.dof_constant_buffer })
	render.disable_texture("tex0")
	render.disable_material()

	-- Pass 2: Vertical
	render.set_render_target(self.dof_blur_rt)
	render.set_render_target_size(self.dof_blur_rt, state.window_width, state.window_height)
	render.enable_material("dof_gaussian_blur_v")
	render.enable_texture("tex0", self.dof_blur_h_rt, graphics.BUFFER_TYPE_COLOR0_BIT)
	render.draw(predicates.dof_rt, { constants = self.dof_constant_buffer })
	render.disable_texture("tex0")
	render.disable_material()
	-- ==================================================================

	-- ==================================================================
	-- DOF - Render Final Result
	-- ==================================================================
	render.set_render_target(render.RENDER_TARGET_DEFAULT)
	render.enable_material("dof")
	render.enable_texture("tex0", self.scene_rt, graphics.BUFFER_TYPE_COLOR0_BIT)
	render.enable_texture("tex_blur", self.dof_blur_rt, graphics.BUFFER_TYPE_COLOR0_BIT)
	render.enable_texture("tex_depth", self.scene_rt, graphics.BUFFER_TYPE_DEPTH_BIT)
	render.draw(predicates.dof_rt, { constants = self.dof_constant_buffer })
	render.disable_texture("tex0")
	render.disable_texture("tex_blur")
	render.disable_texture("tex_depth")
	render.disable_material()
	-- ==================================================================
end

return dof

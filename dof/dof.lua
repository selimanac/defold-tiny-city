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

--- Set the focus point for the DoF effect in screen space.
--- The focus point determines which area of the screen remains sharp while
--- other areas are blurred based on their 3D distance from this point.
---
--- @param focus_x number Focus point X coordinate in normalized screen space (0.0 = left, 1.0 = right, 0.5 = center)
--- @param focus_y number Focus point Y coordinate in normalized screen space (0.0 = bottom, 1.0 = top, 0.5 = center)
---
--- Example:
--- ```lua
--- local dof = require("dof.dof")
--- -- Set focus to screen center
--- dof.set_focus(0.5, 0.5)
--- -- Set focus to top-left corner
--- dof.set_focus(0.0, 1.0)
--- ```
function dof.set_focus(focus_x, focus_y)
	focus_point.x = focus_x
	focus_point.y = focus_y
end

--- Set the 3D distance range for the DoF blur effect.
--- Objects closer than min_distance or farther than max_distance will be blurred.
--- The blur amount transitions smoothly between these distances.
---
--- @param min_distance number 3D distance (in world/view-space units) where blur starts
--- @param max_distance number 3D distance (in world/view-space units) where blur reaches maximum strength
---
--- Example:
--- ```lua
--- local dof = require("dof.dof")
--- -- Blur objects closer than 0.8 or farther than 1.0 units from focus point
--- dof.set_distance(0.8, 1.0)
--- -- Larger range for gradual blur transition
--- dof.set_distance(5.0, 15.0)
--- ```
function dof.set_distance(min_distance, max_distance)
	dof_params.x = min_distance
	dof_params.y = max_distance
end

--- Configure Gaussian blur parameters (recommended blur method).
--- Gaussian blur uses a two-pass separable approach for high performance.
--- This is 4-6x faster than box blur with better visual quality.
---
--- @param gaussian_sigma number Standard deviation controlling blur strength (typical: 1.0-5.0, recommended: 2.0)
--- @param gaussian_kernel_size number Number of samples per direction (typical: 3-5, higher = better quality but slower)
---
--- Performance:
--- - kernel_size 3: 14 samples total (7 horizontal + 7 vertical)
--- - kernel_size 5: 22 samples total (11 horizontal + 11 vertical)
---
--- Quality vs Performance:
--- - Mobile: sigma=1.5, kernel_size=2-3
--- - Desktop: sigma=2.5, kernel_size=4-5
---
--- Example:
--- ```lua
--- local dof = require("dof.dof")
--- -- Balanced quality and performance
--- dof.set_gaussian_blur(2.0, 3)
--- -- High quality for desktop
--- dof.set_gaussian_blur(3.0, 5)
--- -- Performance mode for mobile
--- dof.set_gaussian_blur(1.5, 2)
--- ```
function dof.set_gaussian_blur(gaussian_sigma, gaussian_kernel_size)
	gaussian_blur_params.x = gaussian_sigma
	gaussian_blur_params.y = gaussian_kernel_size
end

--- Configure box blur parameters (alternative blur method).
--- Box blur is simpler but slower than Gaussian blur.
--- Use only if Gaussian blur doesn't meet your needs.
---
--- @param blur_size number Kernel radius in pixels (typical: 2-5, higher = slower)
--- @param blur_separation number Spacing between samples (typical: 1.0-2.0)
---
--- Note: To use box blur instead of Gaussian blur:
--- 1. Uncomment box blur code in dof.render() function
--- 2. Comment out Gaussian blur code in dof.render() function
---
--- Example:
--- ```lua
--- local dof = require("dof.dof")
--- -- Basic box blur
--- dof.set_box_blur(2, 1.0)
--- -- Stronger blur with wider separation
--- dof.set_box_blur(3, 2.0)
--- ```
function dof.set_box_blur(blur_size, blur_separation)
	box_blur_params.x = blur_size
	box_blur_params.y = blur_separation
end

--- Set the camera near and far plane distances for depth linearization.
--- Must match the camera projection settings in your scene.
---
--- @param near_plane number Camera near plane distance (typical: 0.1-1.0)
--- @param far_plane number Camera far plane distance (typical: 50.0-1000.0)
---
--- Example:
--- ```lua
--- local dof = require("dof.dof")
--- -- Set camera parameters matching your projection
--- dof.set_camera_params(0.1, 100.0)
--- ```
function dof.set_camera_params(near_plane, far_plane)
	camera_params.x = near_plane
	camera_params.y = far_plane
end

--- Set the DoF calculation mode and screen-space parameters.
--- Choose between depth-only DoF or hybrid modes that combine depth with screen-space distance.
---
--- @param mode number DoF mode: 0=depth-only (default), 1=radial hybrid, 2=circular region
--- @param screen_weight? number (optional) Screen-space influence weight for radial hybrid mode (default: 2.0)
--- @param focus_radius? number (optional) Screen-space radius for circular region mode (default: 0.15, range: 0.0-1.0)
---
--- Modes:
--- - 0 (Depth-only): Focuses entire depth planes. All objects at same depth are equally focused.
--- - 1 (Radial hybrid): Combines depth difference with screen-space distance from focus point.
---                      More localized focus. Use screen_weight to control influence (higher = stronger screen-space effect).
--- - 2 (Circular region): Sharp focus in a circular screen region around cursor, blurred elsewhere based on depth.
---                         Use focus_radius to control the sharp region size.
---
--- Example:
--- ```lua
--- local dof = require("dof.dof")
--- -- Depth-only mode (default)
--- dof.set_dof_mode(0)
---
--- -- Radial hybrid mode with custom weight
--- dof.set_dof_mode(1, 3.0)  -- Stronger screen-space influence
---
--- -- Circular region mode with custom radius
--- dof.set_dof_mode(2, nil, 0.2)  -- Larger sharp focus area
--- ```
function dof.set_dof_mode(mode, screen_weight, focus_radius)
	dof_params.w = mode or 0
	focus_point.z = screen_weight or CONSTANTS.screen_weight
	focus_point.w = focus_radius or CONSTANTS.focus_radius
end

--- Initialize the DoF rendering system.
--- Creates render targets, predicates, and constant buffers required for the DoF effect.
--- Must be called from your render script's init() function.
---
--- @param self table Render script instance (from render script's init function)
---
--- Creates the following render targets:
--- - scene_rt: RGBA texture for the focused scene (with depth buffer)
--- - dof_blur_h_rt: RGBA texture for horizontal Gaussian blur pass
--- - dof_blur_rt: RGBA texture for final blurred result
---
--- Example:
--- ```lua
--- -- In your render script (e.g., dof.render_script)
--- local dof = require("dof.dof")
---
--- function init(self)
---     -- Your existing initialization...
---     dof.init(self)  -- Initialize DoF system
--- end
--- ```
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

	--[[
	-- Box blur parameters (alternative - uncomment to use box blur instead)
	local blur_params = vmath.vector4(
		data.constants.dof_blur_size,
		data.constants.dof_blur_separation,
		0, 0
	)
	self.dof_constant_buffer.blur_params = blur_params
]]
end

--- Render the scene to render target with depth buffer.
---
--- Must be called from your render script's update() function before dof.render().
---
--- @param self table Render script instance
--- @param state table Render state containing window_width, window_height, and clear_buffers
--- @param predicates table Table of render predicates (must include predicates.model)
--- @param draw_options_world table Draw options for world rendering (e.g., frustum culling)
---
--- Example:
--- ```lua
--- -- In your render script's update() function
--- local dof = require("dof.dof")
---
--- function update(self)
---     -- Your existing rendering setup...
---
---     -- Render scene with depth
---     dof.render_update(self, state, predicates, draw_options_world)
---
---     -- Apply blur and composite (see dof.render)
---     dof.render(self, state, predicates)
--- end
--- ```
function dof.render_update(self, state, predicates, draw_options_world)
	self.dof_constant_buffer.dof_params = dof_params
	self.dof_constant_buffer.focus_point = focus_point
	self.dof_constant_buffer.blur_params = gaussian_blur_params
	self.dof_constant_buffer.camera_params = camera_params
	-- self.dof_constant_buffer.blur_params = blur_params  - uncomment to use box blur instead

	-- ==================================================================
	-- DOF - Draw Models to Scene Render Target with Depth
	-- ==================================================================

	render.set_render_target(self.scene_rt)
	render.set_render_target_size(self.scene_rt, state.window_width, state.window_height)
	render.clear(state.clear_buffers)
	render.enable_state(graphics.STATE_CULL_FACE)
	render.draw(predicates.model, draw_options_world)
	--render.set_depth_mask(false)
	render.disable_state(graphics.STATE_CULL_FACE)
	-- ==================================================================
	render.set_render_target(render.RENDER_TARGET_DEFAULT)
end

--- Apply blur and composite the final DoF result.
---
--- Must be called from your render script's update() function after dof.render_update() and reset_camera_world(state).
---
--- @param self table Render script instance
--- @param state table Render state containing window_width and window_height
--- @param predicates table Table of render predicates (must include predicates.dof_rt)
---
--- Note: By default uses Gaussian blur. To use box blur instead:
--- - Uncomment the box blur section in this function
--- - Comment out the Gaussian blur section
---
--- Example:
--- ```lua
--- -- In your render script's update() function
--- local dof = require("dof.dof")
---
--- function update(self)
---     -- Your existing rendering setup...
---
---     -- Render position buffer and scene (see dof.render_update)
---     dof.render_update(self, state, predicates, draw_options_world)
---
---     -- Apply blur and composite final DoF result
---     dof.render(self, state, predicates)
--- end
--- ```
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

	--[[
	-- ==================================================================
	-- DOF - Box blur
	-- Alternative to gaussian blur - uncomment to use box blur instead, and comment out Gaussian blur above)
	-- ==================================================================
	render.set_render_target(self.dof_blur_rt, { transient = { graphics.BUFFER_TYPE_DEPTH_BIT } })
	render.set_render_target_size(self.dof_blur_rt, state.window_width, state.window_height)
	render.enable_material("box_blur")
	render.enable_texture("tex0", self.scene_rt, graphics.BUFFER_TYPE_COLOR0_BIT)
	render.draw(predicates.dof_rt, { constants = self.dof_constant_buffer })
	render.disable_texture("tex0")
	render.disable_material()
	-- ==================================================================
]]

	-- ==================================================================
	-- DOF - Render Final Result
	-- ==================================================================
	render.set_render_target(render.RENDER_TARGET_DEFAULT)
	render.enable_material("dof")
	render.enable_texture("tex0", self.upscale_rt.rt, graphics.BUFFER_TYPE_COLOR0_BIT)
	render.enable_texture("tex_blur", self.dof_blur_rt, graphics.BUFFER_TYPE_COLOR0_BIT)
	render.enable_texture("tex_depth", self.scene_rt, graphics.BUFFER_TYPE_DEPTH_BIT)
	render.draw(predicates.upscale, { constants = self.dof_constant_buffer })
	render.disable_texture("tex0")
	render.disable_texture("tex_blur")
	render.disable_texture("tex_depth")
	render.disable_material()
	-- ==================================================================
end

return dof

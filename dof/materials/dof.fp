#version 140

in mediump vec2           var_texcoord0;

uniform mediump sampler2D tex0;      // focused scene
uniform mediump sampler2D tex_blur;  // blurred scene
uniform mediump sampler2D tex_depth; // depth buffer

uniform fs_uniforms
{
    mediump vec4 dof_params;    // x = min distance, y = max distance, z = enabled, w = mode
    mediump vec4 focus_point;   // x = focus_x, y = focus_y, z = screen_weight, w = focus_radius
    mediump vec4 camera_params; // x = near plane, y = far plane, z = unused, w = unused
};

out vec4 out_fragColor;

// Linearize depth value from  depth buffer
// Converts non-linear depth [0,1] to linear view-space depth
// Get depth at this pixel
// From https://learnopengl.com/Advanced-OpenGL/Depth-testing
float linearizeDepth(float depth, float near, float far)
{
    // Standard perspective projection depth linearization
    return (2.0 * near * far) / (far + near - depth * (far - near));
}

void main()
{
    vec2 texCoord = var_texcoord0;

    vec4 focusColor = texture(tex0, texCoord);

    // If DoF is disabled, just output the focused scene
    if (dof_params.z < 0.5)
    {
        out_fragColor = focusColor;
        return;
    }

    vec4 blurColor = texture(tex_blur, texCoord);

    // Get depth at this pixel
    float pixelDepth = texture(tex_depth, texCoord).r;

    // Get depth at focus point
    vec2 focusUV = vec2(focus_point.x, focus_point.y);
    focusUV = clamp(focusUV, vec2(0.0), vec2(1.0));
    float focusDepth = texture(tex_depth, focusUV).r;

    // Linearize depth values
    float near = camera_params.x;
    float far = camera_params.y;
    float linearPixelDepth = linearizeDepth(pixelDepth, near, far);
    float linearFocusDepth = linearizeDepth(focusDepth, near, far);

    // Calculate depth difference
    float depthDiff = abs(linearPixelDepth - linearFocusDepth);

    // Calculate blur based on DoF mode
    float blur = 0.0;
    int   mode = int(dof_params.w + 0.5); // Round to nearest int

    if (mode == 1)
    {
        // Mode 1: combines depth with screen-space distance
        vec2  screenDist = texCoord - focusUV;
        float screenDistance = length(screenDist);
        float screenWeight = focus_point.z;
        float combinedDist = depthDiff + screenDistance * screenWeight;
        blur = smoothstep(dof_params.x, dof_params.y, combinedDist);
    }
    else if (mode == 2)
    {
        // Mode 2: sharp focus in screen-space circle, blur elsewhere based on depth
        float screenDist = distance(texCoord, focusUV);
        float focusRadius = focus_point.w;

        if (screenDist > focusRadius)
        {
            // Outside focus circle -  depth-based blur
            blur = smoothstep(dof_params.x, dof_params.y, depthDiff);
        }
        else
        {
            // Inside focus circle - no blur
            blur = 0.0;
        }
    }
    else
    {
        // Mode 0: Depth-only - focus entire depth planes
        blur = smoothstep(dof_params.x, dof_params.y, depthDiff);
    }

    // Blend focused and blurred scenes based on calculated blur factor
    out_fragColor = mix(focusColor, blurColor, blur);
}

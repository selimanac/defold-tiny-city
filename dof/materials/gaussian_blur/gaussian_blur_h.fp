#version 140

in mediump vec2           var_texcoord0;

uniform mediump sampler2D tex0;

uniform fs_uniforms
{
    mediump vec4
    blur_params; // x = sigma (standard deviation), y = kernel_size (radius)
};

out vec4 out_fragColor;

#include "/dof/materials/gaussian_blur/gaussian_blur.glsl"

void main()
{
    vec2  texSize = textureSize(tex0, 0).xy;
    vec2  texCoord = var_texcoord0;

    float sigma = blur_params.x;
    int   kernel_size = int(blur_params.y);

    // If sigma or kernel size is too small, just pass through
    if (sigma <= 0.0 || kernel_size <= 0)
    {
        out_fragColor = texture(tex0, texCoord);
        return;
    }

    vec3  color = vec3(0.0);
    float totalWeight = 0.0;

    // Horizontal blur (X direction only)
    for (int i = -kernel_size; i <= kernel_size; ++i)
    {
        vec2 offset = vec2(float(i), 0.0);
        vec2 sampleCoord = texCoord + offset / texSize;

        // Clamp to valid texture coordinates
        sampleCoord = clamp(sampleCoord, vec2(0.0), vec2(1.0));

        float weight = gaussian(float(i), sigma);
        color += texture(tex0, sampleCoord).rgb * weight;
        totalWeight += weight;
    }

    out_fragColor.rgb = color / totalWeight;
    out_fragColor.a = 1.0;
}

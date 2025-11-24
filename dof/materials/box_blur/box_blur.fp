#version 140

in mediump vec2           var_texcoord0;

uniform mediump sampler2D tex0;

uniform fs_uniforms
{
    mediump vec4 blur_params; // x = size, y = separation
};

out vec4 out_fragColor;

void     main()
{
    vec2 texSize = textureSize(tex0, 0).xy;
    vec2 texCoord = var_texcoord0;

    out_fragColor = texture(tex0, texCoord);

    int size = int(blur_params.x);
    if (size <= 0)
    {
        return;
    }

    float separation = blur_params.y;
    separation = max(separation, 1.0);

    out_fragColor.rgb = vec3(0.0);

    float count = 0.0;

    for (int i = -size; i <= size; ++i)
    {
        for (int j = -size; j <= size; ++j)
        {
            vec2 sampleCoord = (gl_FragCoord.xy + (vec2(i, j) * separation)) / texSize;
            // Clamp to valid texture coordinates to avoid sampling outside bounds
            sampleCoord = clamp(sampleCoord, vec2(0.0), vec2(1.0));

            out_fragColor.rgb += texture(tex0, sampleCoord).rgb;
            count += 1.0;
        }
    }

    out_fragColor.rgb /= count;
}

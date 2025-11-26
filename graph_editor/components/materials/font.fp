#version 140

in mediump vec2           var_texcoord0;
in mediump vec4           var_face_color;
in mediump vec4           var_layer_mask;

out vec4                  out_fragColor;

uniform mediump sampler2D texture_sampler;

void                      main()
{
    mediump float is_single_layer = var_layer_mask.a;
    mediump vec3  t = texture(texture_sampler, var_texcoord0.xy).xyz;
    float         face_alpha = var_face_color.w * t.x;

    mediump vec4  face_color = var_layer_mask.x * vec4(var_face_color.xyz, 1.0) * face_alpha;

    out_fragColor = face_color;
}

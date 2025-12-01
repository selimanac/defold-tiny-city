embedded_components {
  id: "model"
  type: "model"
  data: "mesh: \"/tiny-city/assets/models/traffic_light.glb\"\n"
  "name: \"{{NAME}}\"\n"
  "materials {\n"
  "  name: \"default\"\n"
  "  material: \"/light_and_shadows/materials/model/model_instanced.material\"\n"
  "  textures {\n"
  "    sampler: \"tex0\"\n"
  "    texture: \"/tiny-city/assets/textures/generic/traffic_light.png\"\n"
  "  }\n"
  "}\n"
  "create_go_bones: false\n"
  ""
}
embedded_components {
  id: "green"
  type: "model"
  data: "mesh: \"/tiny-city/assets/models/traffic_light_bulb.glb\"\n"
  "name: \"{{NAME}}\"\n"
  "materials {\n"
  "  name: \"default\"\n"
  "  material: \"/tiny-city/components/materials/unlit/model_unlit_instanced_tint.material\"\n"
  "  textures {\n"
  "    sampler: \"tex0\"\n"
  "    texture: \"/tiny-city/assets/textures/generic/white.png\"\n"
  "  }\n"
  "}\n"
  "create_go_bones: false\n"
  ""
  position {
    x: 0.377961
    y: 0.547474
    z: -0.034368
  }
}
embedded_components {
  id: "red"
  type: "model"
  data: "mesh: \"/tiny-city/assets/models/traffic_light_bulb.glb\"\n"
  "name: \"{{NAME}}\"\n"
  "materials {\n"
  "  name: \"default\"\n"
  "  material: \"/tiny-city/components/materials/unlit/model_unlit_instanced_tint.material\"\n"
  "  textures {\n"
  "    sampler: \"tex0\"\n"
  "    texture: \"/tiny-city/assets/textures/generic/white.png\"\n"
  "  }\n"
  "}\n"
  "create_go_bones: false\n"
  ""
  position {
    x: 0.377961
    y: 0.643879
    z: -0.034368
  }
}
embedded_components {
  id: "yellow"
  type: "model"
  data: "mesh: \"/tiny-city/assets/models/traffic_light_bulb.glb\"\n"
  "name: \"{{NAME}}\"\n"
  "materials {\n"
  "  name: \"default\"\n"
  "  material: \"/tiny-city/components/materials/unlit/model_unlit_instanced_tint.material\"\n"
  "  textures {\n"
  "    sampler: \"tex0\"\n"
  "    texture: \"/tiny-city/assets/textures/generic/white.png\"\n"
  "  }\n"
  "}\n"
  "create_go_bones: false\n"
  ""
  position {
    x: 0.377961
    y: 0.595826
    z: -0.034368
  }
}

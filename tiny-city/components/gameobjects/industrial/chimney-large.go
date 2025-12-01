components {
  id: "smoke"
  component: "/tiny-city/components/particlefx/smoke.particlefx"
  position {
    y: 1.68607
  }
}
embedded_components {
  id: "model"
  type: "model"
  data: "mesh: \"/tiny-city/assets/models/industrial/chimney-large.glb\"\n"
  "materials {\n"
  "  name: \"colormap\"\n"
  "  material: \"/light_and_shadows/materials/model/model_instanced.material\"\n"
  "  textures {\n"
  "    sampler: \"tex0\"\n"
  "    texture: \"/tiny-city/assets/textures/kenny/kenny_industrial_colormap.png\"\n"
  "  }\n"
  "}\n"
  "create_go_bones: false\n"
  ""
}

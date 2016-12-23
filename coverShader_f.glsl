uniform vec2 resolution;

float map(float x, float y, float a) {
  float d = y - x;
  return x + a * d;
}

vec4 effect(vec4 color, Image texturei, vec2 texture_coords, vec2 gl_FragCoord) {
  vec2 q = gl_FragCoord / resolution;
  q.y = 1 - q.y;

  float v = 1 - smoothstep(0.1, 0.3, q.y);
  v += smoothstep(0.7, 0.9, q.y);
  v = map(0.0, 0.7, 1 - v);

  vec4 samplep = Texel(texturei, texture_coords);

  return vec4(samplep.rgb*color.rgb, v * samplep.a);
}

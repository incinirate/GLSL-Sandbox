uniform float time;
uniform vec2 resolution;
uniform vec2 offset;

const vec3 fill = vec3(1, 0.26, 0.07); //vec3(0.1, 0.9, 0.2);
const float r = 0.2;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 gl_FragCoord) {
  gl_FragCoord -= offset;
  vec2 q = gl_FragCoord.xy / resolution;
  float c = length(vec2(6 * (q.x - 0.5), (q.y - 0.5)*0.2));

  float p = 0.5+0.5*sin(time);
  float l = length(q - vec2(0.5, (0.4)+(0.5-r)*(-1 + mod(time * 2, 2))))*(1/r);
  l = 1 - smoothstep(0.06, 1, l);
  float las = sin(time * 3.14159268);
  float la = (las*las);
  l *= la;
  c = 1 - clamp(0, 1, c);
  c = c*smoothstep(-0.3, 1.15, q.y);
  c = c*(1 - smoothstep(.1, 1.15, q.y));
  c = c * (0.8+0.2*cos(time*5));

  float val = clamp(c+l*0.2, 0, 1);
  return vec4(fill, val * 2.0);
}

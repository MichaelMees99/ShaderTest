// Blue marble-like flow shader inspired by the provided image.
#ifdef GL_ES
precision highp float;
#endif

uniform vec2 u_resolution;
uniform float u_time;

float hash21(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.55;
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(p);
        p = mat2(1.6, 1.2, -1.2, 1.6) * p;
        amplitude *= 0.5;
    }
    return value;
}

vec2 swirl(vec2 p, float strength) {
    float r = length(p);
    float angle = strength * exp(-r * 2.0);
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c) * p;
}

vec3 palette(float t) {
    vec3 deep = vec3(0.06, 0.15, 0.38);
    vec3 mid = vec3(0.20, 0.38, 0.78);
    vec3 light = vec3(0.77, 0.87, 1.0);
    vec3 blush = vec3(0.86, 0.72, 0.88);
    vec3 base = mix(deep, mid, smoothstep(0.1, 0.7, t));
    base = mix(base, light, smoothstep(0.55, 0.95, t));
    return mix(base, blush, smoothstep(0.65, 0.9, t));
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec2 p = (uv - 0.5) * vec2(u_resolution.x / u_resolution.y, 1.0);

    float drift = u_time * 0.03;
    vec2 flow = p + vec2(drift * 0.55, drift * 0.08);
    flow = swirl(flow + vec2(0.12, -0.08), 2.6);

    vec2 warp = vec2(fbm(flow * 2.0 + vec2(0.0, drift)), fbm(flow * 2.3 - vec2(drift, 0.0)));
    flow += (warp - 0.5) * 0.25;

    float base = fbm(flow * 2.2);
    float bands = fbm(vec2(flow.x * 1.2, flow.y * 5.2) + vec2(0.0, drift * 1.6));
    float marbling = smoothstep(0.2, 0.9, base) + bands * 0.55;

    vec2 streakUv = vec2(flow.x * 1.4, flow.y * 6.2);
    float streaks = fbm(streakUv + vec2(0.0, drift * 1.8));
    marbling += smoothstep(0.15, 0.85, streaks) * 0.45;

    float whirl = fbm(flow * 3.0 + vec2(1.1, -0.2));
    float rings = smoothstep(0.6, 0.85, whirl) * smoothstep(0.2, 0.8, sin(whirl * 16.0));
    marbling += rings * 0.25;

    vec3 color = palette(marbling);
    color += vec3(0.1, 0.05, 0.15) * smoothstep(0.65, 0.95, marbling);
    color -= vec3(0.05, 0.07, 0.12) * smoothstep(0.08, 0.35, marbling);

    float vignette = smoothstep(0.9, 0.3, length(p));
    color *= vignette + 0.15;

    gl_FragColor = vec4(color, 1.0);
}

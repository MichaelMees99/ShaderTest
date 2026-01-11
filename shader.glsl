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
    float amplitude = 0.6;
    for (int i = 0; i < 6; i++) {
        value += amplitude * noise(p);
        p = mat2(1.4, 1.1, -1.1, 1.4) * p;
        amplitude *= 0.48;
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
    vec3 mid = vec3(0.18, 0.36, 0.74);
    vec3 light = vec3(0.78, 0.88, 1.0);
    vec3 blush = vec3(0.88, 0.74, 0.9);
    vec3 base = mix(deep, mid, smoothstep(0.08, 0.68, t));
    base = mix(base, light, smoothstep(0.58, 0.96, t));
    return mix(base, blush, smoothstep(0.62, 0.9, t));
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec2 p = (uv - 0.5) * vec2(u_resolution.x / u_resolution.y, 1.0);

    float drift = u_time * 0.02;
    vec2 flow = p + vec2(drift * 0.35, drift * 0.08);
    flow = swirl(flow + vec2(0.08, -0.04), 1.4);

    vec2 warp = vec2(
        fbm(flow * 1.6 + vec2(0.0, drift)),
        fbm(flow * 1.9 - vec2(drift, 0.0))
    );
    flow += (warp - 0.5) * 0.18;

    float base = fbm(flow * 1.9);
    float bands = fbm(vec2(flow.x * 1.1, flow.y * 7.2) + vec2(0.0, drift * 1.4));
    float marbling = smoothstep(0.18, 0.92, base) + bands * 0.7;

    float micro = fbm(vec2(flow.x * 3.2, flow.y * 12.0) + vec2(0.0, drift * 2.4));
    marbling += smoothstep(0.2, 0.85, micro) * 0.25;

    float whirl = fbm(flow * 2.6 + vec2(1.0, -0.1));
    float rings = smoothstep(0.6, 0.9, whirl) * smoothstep(0.1, 0.9, sin(whirl * 18.0));
    marbling += rings * 0.18;

    vec3 color = palette(marbling);
    color += vec3(0.09, 0.04, 0.12) * smoothstep(0.7, 0.98, marbling);
    color -= vec3(0.06, 0.09, 0.15) * smoothstep(0.05, 0.3, marbling);

    float vignette = smoothstep(1.0, 0.25, length(p));
    color *= vignette + 0.2;

    gl_FragColor = vec4(color, 1.0);
}

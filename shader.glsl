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
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(p);
        p = mat2(1.3, 1.0, -1.0, 1.3) * p;
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
    vec3 mid = vec3(0.20, 0.40, 0.78);
    vec3 light = vec3(0.80, 0.89, 1.0);
    vec3 blush = vec3(0.88, 0.72, 0.88);
    vec3 base = mix(deep, mid, smoothstep(0.05, 0.7, t));
    base = mix(base, light, smoothstep(0.55, 0.95, t));
    return mix(base, blush, smoothstep(0.62, 0.88, t));
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec2 p = (uv - 0.5) * vec2(u_resolution.x / u_resolution.y, 1.0);

    float drift = u_time * 0.02;
    vec2 flow = p + vec2(drift * 0.18, drift * 0.06);

    vec2 warp = vec2(
        fbm(flow * vec2(0.8, 2.2) + vec2(0.0, drift * 0.4)),
        fbm(flow * vec2(1.2, 1.4) - vec2(drift * 0.2, 0.0))
    );
    flow += (warp - 0.5) * vec2(0.18, 0.32);

    float bandBase = flow.y * 7.5 + fbm(flow * vec2(1.0, 4.0)) * 1.3;
    float bands = sin(bandBase) * 0.5 + 0.5;
    bands = smoothstep(0.2, 0.85, bands);

    float softBands = fbm(vec2(flow.x * 0.8, flow.y * 5.8) + vec2(0.0, drift));
    float marbling = mix(bands, softBands, 0.35);

    float streaks = fbm(vec2(flow.x * 2.2, flow.y * 12.0) + vec2(0.0, drift * 1.6));
    marbling += smoothstep(0.25, 0.9, streaks) * 0.3;

    float pool1 = smoothstep(0.42, 0.05, length(flow - vec2(-0.45, -0.2)));
    float pool2 = smoothstep(0.36, 0.08, length(flow - vec2(0.55, 0.18)));
    float pools = max(pool1, pool2);
    marbling = mix(marbling, 1.05, pools);

    float rings = sin((length(flow + vec2(-0.45, -0.2)) * 18.0) - drift * 3.0);
    rings = smoothstep(0.2, 0.8, rings) * pool1;
    marbling += rings * 0.35;

    vec3 color = palette(marbling);
    color += vec3(0.12, 0.08, 0.16) * smoothstep(0.7, 1.0, marbling);
    color -= vec3(0.05, 0.08, 0.14) * smoothstep(0.0, 0.35, marbling);

    float vignette = smoothstep(1.0, 0.35, length(p));
    color *= vignette + 0.18;

    gl_FragColor = vec4(color, 1.0);
}

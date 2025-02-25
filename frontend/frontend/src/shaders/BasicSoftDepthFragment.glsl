precision highp float;
varying vec2 vUv;
uniform vec2 u_resolution;  // Screen resolution
uniform vec2 u_mouse;       // Mouse position
uniform float u_time;       // Time for animations
uniform int u_mode;         // Mode to switch between different effects
uniform float u_distanceVisualisationScale;  // Scale for distance visualisation
uniform float u_offset;     // Offset for the effect
uniform float u_borderWidth;  // Width of the border

// Signed Distance Function for a line segment
float sdf_line(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

// Signed Distance Function for a box shape
float sdf_box(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// Signed Distance Function for a soft box shape
float sdf_softBox(vec2 p, vec2 b, float r) {
    vec2 d = abs(p) - b + r;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

// Signed Distance Function for a circle shape
float sdf_circle(vec2 p, float r) {
    return length(p) - r;
}

// Signed Distance Function for a soft circle shape
float sdf_softCircle(vec2 p, float r, float s) {
    return max(length(p) - r, 0.0) - s;
}

// Main function
void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / u_resolution.y;

    vec3 background = vec3(0.1, 0.1, 0.2);
    vec3 foreground = vec3(1, 0, 0.2);
    vec3 border = vec3(0.7, 0.1, 0.2);

    // Button shape definition
    //float sdf = sdf_box(uv, vec2(0.2, 0.1));
    float sdf = sdf_softCircle(uv, 0.2, 0.15);

    vec3 color = background;

    if (u_mode == 1) {
        // Raw
        color = vec3(sdf);
    } else if (u_mode == 2) {
        // Distance
        color.r = u_distanceVisualisationScale * sdf;
        color.g = u_distanceVisualisationScale * -sdf;
        color.b = 0.0;
    } else if (u_mode == 3) {
        // Gradient
        // TODO: Implement gradient visualization
        // color.rg = abs(sdf.gb);
        // color.b = 0;
    } else if (u_mode == 4) {
        // Solid
        float d = sdf + u_offset;
        if (d < 0.0)
            color = foreground;
    } else if (u_mode == 5) {
        // Border
        float d = sdf + u_offset;
        if (abs(d) < u_borderWidth)
            color = border;
    } else if (u_mode == 6) {
        // SolidWithBorder
        float d = sdf + u_offset;
        if (abs(d) < u_borderWidth) {
            color = border;
        } else if (d < 0.0) {
            color = foreground;
        }
    }

    gl_FragColor = vec4(color, 1.0);
}

precision highp float;
varying vec2 vUv;
uniform vec2 u_resolution;  // Screen resolution
uniform vec2 u_mouse;       // Mouse position
uniform float u_time;       // Time for animations
uniform int u_mode;         // Mode to switch between different effects
uniform float u_distanceVisualisationScale;  // Scale for distance visualisation
uniform float u_offset;     // Offset for the effect
uniform float u_borderWidth;  // Width of the border
uniform float u_neonPower;  // Power for the neon effect
uniform float u_neonBrightness;  // Brightness for the neon effect
uniform vec2 u_shadowDist;  // Distance for shadow
uniform float u_shadowBorderWidth;  // Width of the shadow border
uniform vec4 u_background;  // Background color
uniform vec4 u_foreground;  // Foreground color
uniform vec4 u_border;      // Border color

// Linear interpolation functions
float lerp(float a, float b, float t) {
    return a + t * (b - a);
}

vec2 lerp(vec2 a, vec2 b, float t) {
    return a + t * (b - a);
}

vec3 lerp(vec3 a, vec3 b, float t) {
    return a + t * (b - a);
}

vec4 lerp(vec4 a, vec4 b, float t) {
    return a + t * (b - a);
}

// Saturate function
float saturate(float x) {
    return clamp(x, 0.0, 1.0);
}

vec2 saturate2(vec2 x) {
    return vec2(clamp(x, 0.0, 1.0));
}

vec3 saturate3(float x) {
    return vec3(clamp(x, 0.0, 1.0));
}

// Signed Distance Function for a line segment
float sdLine(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

// Signed Distance Function for a box shape
vec4 sdBox(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return vec4(length(max(d, 0.0)) + min(max(d.x, d.y), 0.0), 0.0, 0.0, 1.0);
}

// Signed Distance Function for a soft box shape
vec4 sdSoftBox(vec2 p, vec2 b, float r) {
    vec2 d = abs(p) - b + r;
    return vec4(length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r, 0.0, 0.0, 1.0);
}

// Signed Distance Function for a circle shape
vec4 sdCircle(vec2 p, float r) {
    return vec4(length(p) - r, 0.0, 0.0, 1.0);
}

// Signed Distance Function for a soft circle shape
vec4 sdSoftCircle(vec2 p, float r, float s) {
    return vec4(max(length(p) - r, 0.0) - s, 0.0, 0.0, 1.0);
}

// Signed Distance Gradiant Function for a circle shape
vec4 sdgCircle(vec2 p, float r) {
    float d = length(p);
    return vec4( d-r, p/d, 1.0);
}

// Main function
void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / u_resolution.y;
    vec2 mouse = (u_mouse - 0.5 * u_resolution) / u_resolution.y;
    vec2 animatedCircle = 0.005 * vec2(sin(u_time),cos(u_time));

    vec2 shapePos = vec2(0.2, 0.2) + animatedCircle;
    vec2 shapeSize = vec2(0.2, 0.1);
    float radius = 0.25;

    vec2 lightDir = shapePos - mouse;

    // SDF shape definition
    vec4 sdf = sdgCircle(uv - shapePos, radius);
    vec2 shadowOffset = lightDir;
    vec4 sdf_shadow = sdgCircle(uv - shapePos - shadowOffset, radius);

    vec4 color = u_background;

    if (u_mode == 1) {
        // Raw
        color = sdf;
    } else if (u_mode == 2) {
        // Distance
        float d = sdf.r * u_distanceVisualisationScale;
        color.r = saturate(d);
        color.g = saturate(-d);
        color.b = 0.0;
    } else if (u_mode == 3) {
        // Gradient
        // TODO: Implement gradient visualization
        color.rg = vec2(abs(sdf.gb));
        color.b = abs(sdf.r * 5.0);
    } else if (u_mode == 4) {
        // Solid
        float d = sdf.r + u_offset;
        if (d < 0.0)
            color = u_foreground;
    } else if (u_mode == 5) {
        // Border
        float d = sdf.r + u_offset;
        if (abs(d) < u_borderWidth)
            color = u_border;
    } else if (u_mode == 6) {
        // SolidWithBorder
        float d = sdf.r + u_offset;
        if (abs(d) < u_borderWidth) {
            color = u_border;
        } else if (d < 0.0) {
            color = u_foreground;
        }
    } else if (u_mode == 7) {
        // Soft border
        float d = sdf.r + u_offset;
        if (d < -u_borderWidth) {
            //if inside shape by more than u_borderWidth, use pure fill
            color = u_foreground;
        } else if (d < 0.0) {
            //if inside shape but within range of border, lerp from border to fill colour
            float t = -d / u_borderWidth;
            t = t * t;
            color = lerp(u_border, u_foreground, t);
        } else if (d < u_borderWidth) {
            //if outside shape but within range of border, lerp from border to background colour
            float t = d / u_borderWidth;
            t = t * t;
            color = lerp(u_border, u_background, t);
        }
    } else if (u_mode == 8) {
        // Neon
        float d = sdf.r + u_offset;

        //only do something if within range of border
        if (d > -u_borderWidth && d < u_borderWidth) {
            //calculate a value of 't' that goes from 0->1->0
            //around the edge of the geometry
            float t = d / u_borderWidth; //[-1:0:1]
            t = 1.0 - abs(t);             //[0:1:0]

            //lerp between background and border using t
            color = lerp(u_background, u_border, t);

            //raise t to a high power and add in as white
            //to give bloom effect
            color.rgb += pow(t, u_neonPower) * u_neonBrightness;
        }
    } else if (u_mode == 10) {
        // Drop shadow        
        float d = sdf.r + u_offset;
        float d2 = sdf_shadow.r + u_offset;

        //calculate interpolators (go from 0 to 1 across border)
        float fill_t = 1.0 - saturate((d - u_borderWidth) / u_borderWidth);
        float shadow_t = 1.0 - saturate((d2 - u_shadowBorderWidth) / u_shadowBorderWidth);

        //apply the shadow colour, then over the top apply fill colour
        color = lerp(color,u_border,shadow_t);
        color = lerp(color,u_foreground,fill_t);
    }

    gl_FragColor = color;
}

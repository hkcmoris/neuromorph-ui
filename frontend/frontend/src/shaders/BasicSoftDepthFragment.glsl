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
uniform float u_shadowDist;  // Distance for shadow
uniform float u_shadowBorderWidth;  // Width of the shadow border

vec3 lerp(vec3 a, vec3 b, float t) {
    return a + t * (b - a);
}

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
    
    //take another sample, _ShadowDist texels up/right from the first
    float sdf_shadow = sdf_softCircle(uv + u_shadowDist, 0.2, 0.15);

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
    } else if (u_mode == 7) {
        // Soft border
        float d = sdf + u_offset;
        if (d < -u_borderWidth) {
            //if inside shape by more than u_borderWidth, use pure fill
            color = foreground;
        } else if (d < 0.0) {
            //if inside shape but within range of border, lerp from border to fill colour
            float t = -d / u_borderWidth;
            t = t * t;
            color = lerp(border, foreground, t);
        } else if (d < u_borderWidth) {
            //if outside shape but within range of border, lerp from border to background colour
            float t = d / u_borderWidth;
            t = t * t;
            color = lerp(border, background, t);
        }
    } else if (u_mode == 8) {
        // Neon
        float d = sdf + u_offset;

        //only do something if within range of border
        if (d > -u_borderWidth && d < u_borderWidth) {
            //calculate a value of 't' that goes from 0->1->0
            //around the edge of the geometry
            float t = d / u_borderWidth; //[-1:0:1]
            t = 1.0 - abs(t);             //[0:1:0]

            //lerp between background and border using t
            color = lerp(background, border, t);

            //raise t to a high power and add in as white
            //to give bloom effect
            color.rgb += pow(t, u_neonPower) * u_neonBrightness;
        }
    } else if (u_mode == 10) {
        // Drop shadow        
        float d = sdf + u_offset;
        float d2 = sdf_shadow + u_offset;

        //calculate interpolators (go from 0 to 1 across border)
        float fill_t = 1.0 - ((d - u_borderWidth) / u_borderWidth);
        float shadow_t = 1.0 - ((d2 - u_shadowBorderWidth) / u_shadowBorderWidth);

        //apply the shadow colour, then over the top apply fill colour
        color = lerp(color,border,shadow_t);
        color = lerp(color,foreground,fill_t);                 
    }

    gl_FragColor = vec4(color, 1.0);
}

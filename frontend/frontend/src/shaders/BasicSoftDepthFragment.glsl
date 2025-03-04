precision highp float;
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

// Combining SDF
vec4 merge(vec4 a, vec4 b) {
    return min(a, b);
}

vec4 intersect(vec4 a, vec4 b) {
    return max(a, b);
}

vec4 subtract(vec4 a, vec4 b) {
    return intersect(a, -b);
}

vec4 interpolate(vec4 a, vec4 b, float t){
    return lerp(a, b, t);
}

vec4 round_merge(vec4 a, vec4 b, float r){
    vec2 intersectionSpaceR = vec2(a.r - r, b.r - r);
    vec2 intersectionSpaceG = vec2(a.g - r, b.g - r);
    vec2 intersectionSpaceB = vec2(a.b - r, b.b - r);
    intersectionSpaceR = min(intersectionSpaceR, 0.0);
    intersectionSpaceG = min(intersectionSpaceG, 0.0);
    intersectionSpaceB = min(intersectionSpaceB, 0.0);
    float insideDistanceR = -length(intersectionSpaceR);
    float insideDistanceG = -length(intersectionSpaceG);
    float insideDistanceB = -length(intersectionSpaceB);
    vec4 simpleUnion = merge(a, b);
    float outsideDistanceR = max(simpleUnion.r, r);
    float outsideDistanceG = max(simpleUnion.g, r);
    float outsideDistanceB = max(simpleUnion.b, r);
    return vec4(insideDistanceR + outsideDistanceR, insideDistanceG + outsideDistanceG, insideDistanceB + outsideDistanceB, 1.0);
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
    return vec4(max(d.x, d.y), 0.0, 0.0, 1.0);
    // return vec4(length(max(d, 0.0)) + min(max(d.x, d.y), 0.0), 0.0, 0.0, 1.0);
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

// Signed Distance Gradient Function for a circle shape
vec4 sdgCircle(vec2 p, float r) {
    float d = length(p);
    return vec4( d - r, p / d, 1.0);
}

// Signed Distance Gradient Function for a box shape
vec4 sdgBox(vec2 p, vec2 b)
{
    vec2 w = abs(p) - b;
    vec2 s = vec2(p.x < 0.0 ? - 1 : 1, p.y < 0.0 ? -1 : 1);
    float g = max(w.x, w.y);
    vec2  q = max(w, 0.0);
    float l = length(q);
    return vec4(
        (g > 0.0) ? l : g,
        s * ((g > 0.0) ? q / l : (
            (w.x>w.y) ? vec2(1, 0) : vec2(0, 1)
        )),
        1.0
    );
}

// Signed Distance Gradient Function for a rotated box shape
vec4 sdgRotatedBox(vec2 p, vec2 b, float r) {
    float c = cos(r);
    float s = sin(r);
    vec2 p_rot = vec2(c * p.x - s * p.y, s * p.x + c * p.y);
    return sdgBox(p_rot, b);
}

// Signed Distance Gradient Function for a segment shape
vec4 sdgSegment(vec2 p, vec2 a, vec2 b, float r ) {
    vec2 ba = b - a, pa = p - a;
    float h = clamp( dot(pa, ba) / dot(ba, ba), 0.0, 1.0 );
    vec2  q = pa - h * ba;
    float d = length(q);
    return vec4(d - r,q / d, 1.0);
}

vec4 sdSphere(vec3 p, float s) {
    float d = length(p);
    return vec4(d - s, 0.0, 0.0, 1.0);
}

float cro( vec2 a, vec2 b ) { return a.x * b.y - a.y * b.x; }
// Signed Distance Gradient Function for a triangle
vec4 sdgTriangle(vec2 p, vec2 v[3]) {
    float gs = cro(v[0] - v[2], v[1] - v[0]);
    vec4 res;
    
    {
        vec2  e = v[1] - v[0], w = p - v[0];
        vec2  q = w - e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
        float d = dot(q, q), s = gs * cro(w, e);
        res = vec4(d, q, s);
    } {
        vec2  e = v[2] - v[1], w = p - v[1];
        vec2  q = w - e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
        float d = dot(q, q), s = gs * cro(w, e);
        res = vec4( (d < res.x) ? vec3(d, q) : res.xyz,
                    (s > res.w) ?      s    : res.w );
    } {
        vec2  e = v[0] - v[2], w = p - v[2];
        vec2  q = w - e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
        float d = dot(q, q), s = gs * cro(w, e);
        res = vec4(
            (d < res.x) ? vec3(d, q) : res.xyz,
            (s > res.w) ? s : res.w
        );
    }
    
    float d = sqrt(res.x)*sign(res.w);
    return vec4(d, res.yz / d, 1.0);
}

// Mouse cursor
vec4 sdgMouseCursor(
    vec2 p,
    vec2 cursorDirection,
    float cursorArrowWidth,
    float cursorArrowAnchor,
    float cursorArrowFlapAnchor,
    float cursorTailWidth
) {
    vec2 mv[3];
    vec2 mv2[3];
    vec2 mv3[3];
    vec2 anchor = cursorDirection * cursorArrowAnchor;
    vec2 anchorFlap = cursorDirection * cursorArrowFlapAnchor;
    
    // Calculate perpendicular directions
    vec2 perpDirL = vec2(-cursorDirection.y, cursorDirection.x);
    vec2 perpDirR = vec2(cursorDirection.y, -cursorDirection.x);

    // Translate anchorFlap by cursorArrowWidth in both perpendicular directions
    vec2 anchorFlapL = anchorFlap + perpDirL * cursorArrowWidth;
    vec2 anchorFlapR = anchorFlap + perpDirR * cursorArrowWidth;

    vec2 anchorTailL1 = cursorDirection + perpDirL * cursorTailWidth;
    vec2 anchorTailR1 = cursorDirection + perpDirR * cursorTailWidth;

    // Calculate intersection point anchorTailL0
    vec2 dirL1 = -cursorDirection;
    vec2 dirL2 = anchor - anchorFlapL;
    float t1 = (dirL2.x * (anchorFlapL.y - anchorTailL1.y) - dirL2.y * (anchorFlapL.x - anchorTailL1.x)) / (dirL2.x * dirL1.y - dirL2.y * dirL1.x);
    vec2 anchorTailL0 = anchorTailL1 + t1 * dirL1;
    
    // Calculate intersection point anchorTailL0
    vec2 dirR1 = -cursorDirection;
    vec2 dirR2 = anchor - anchorFlapR;
    float t2 = (dirR2.x * (anchorFlapR.y - anchorTailR1.y) - dirR2.y * (anchorFlapR.x - anchorTailR1.x)) / (dirR2.x * dirR1.y - dirR2.y * dirR1.x);
    vec2 anchorTailR0 = anchorTailR1 + t2 * dirR1;

    // mv[0] = vec2(0.0,0.0);
    // mv[1] = anchorFlapR;
    // mv[2] = anchorTailR0;
    // mv[3] = anchorTailR1;
    // mv[4] = anchorTailL1;
    // mv[5] = anchorTailL0;
    // mv[6] = anchorFlapL;

    mv[0] = vec2(0.0,0.0);
    mv[1] = anchorFlapR;
    mv[2] = anchor;

    mv2[0] = vec2(0.0,0.0);
    mv2[1] = anchor;
    mv2[2] = anchorFlapL;

    mv3[0] = vec2(0.0,0.0);
    mv3[1] = anchorFlapR / 2.0;
    mv3[2] = anchorFlapL / 2.0;

    return 
    merge(
        sdgTriangle(p, mv),
        merge(
            merge(
                sdgSegment(p, cursorDirection / 4.0, cursorDirection, cursorTailWidth),
                sdgTriangle(p, mv3)
            ),
            sdgTriangle(p, mv2)
        )
    );
    
    //return sdgPolygon(p, mv, 7);
}

// Main function
void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / u_resolution.y;
    vec2 mouse = (u_mouse - 0.5 * u_resolution) / u_resolution.y;
    float t = (sin(u_time) + 1.0) / 2.0;
    vec2 animatedCircle = 0.015 * vec2(sin(u_time),cos(u_time));

    vec2 pos_segment_a = vec2(0.2, 0.2);
    vec2 pos_segment_b = vec2(-0.3, -0.1);
    float r_segment = 0.05;
    vec2 pos_circle = vec2(-0.1, 0.0);
    float r_circle = 0.1;
    vec3 pos_sphere = vec3(0.3, 0, 0.15);

    vec2 lightDir = normalize(vec2(0.4, 0.6));

    // SDF shape definition
    vec2 cursorDirection = vec2(0.1, -0.2);
    float cursorArrowWidth = 0.35;
    float cursorArrowAnchor = 0.6;
    float cursorArrowFlapAnchor = 0.8;
    float cursorTailWidth = 0.02;
    vec4 sdMouse = sdgMouseCursor(
        uv - mouse,
        cursorDirection,
        cursorArrowWidth,
        cursorArrowAnchor,
        cursorArrowFlapAnchor,
        cursorTailWidth
    );

    // vec4 sdf = sdBox(uv - shapePos, shapeSize);
    vec4 segment = sdgSegment(uv, pos_segment_a, pos_segment_b, r_segment);
    vec4 circle = sdgCircle(uv - pos_circle, r_circle);
    // vec4 sdf = round_merge(segment, circle, t * 0.2);
    vec4 sdf = sdSphere(pos_sphere, 0.15);
    // sdf = round_merge(sdMouse, sdf, 0.1);
    vec2 shadowOffset = lightDir;
    //vec4 sdf_shadow = sdBox(uv - shapePos - shadowOffset, shapeSize);
    vec4 segment_shadow = sdgSegment(uv, pos_segment_a, pos_segment_b - shadowOffset, r_segment);
    vec4 circle_shadow = sdgCircle(uv - pos_circle - shadowOffset, r_circle);
    vec4 sdf_shadow = round_merge(segment_shadow, circle_shadow, t * 0.3);

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

        // color.rg = vec2(abs(sdf.gb));
        // color.b = abs(sdf.r * 5.0);

        // coloring
        vec3 col = (sdf.r > 0.0) ? vec3(0.9, 0.6, 0.3) : vec3(0.4, 0.7, 0.85);
        col *= 1.0 + vec3(0.5 * sdf.gb, 0.0);
        //col = vec3(0.5+0.5*g,1.0);
        col *= 1.0 - 0.5 * exp(-16.0 * abs(sdf.r));
        col *= 0.9 + 0.1 * cos(150.0 * sdf.r);
        col = mix( col, vec3(1.0), 1.0 - smoothstep(0.0, 0.01, abs(sdf.r)) );
        color = vec4(col, 1.0);
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

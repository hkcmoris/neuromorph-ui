precision highp float;

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

// Combining SDF
float merge(float a, float b) {
    return min(a, b);
}

vec3 merge(vec3 a, vec3 b) {
    return min(a, b);
}

float intersect(float a, float b) {
    return max(a, b);
}

float subtract(float a, float b) {
    return intersect(a, -b);
}

float interpolate(float a, float b, float t){
    return lerp(a, b, t);
}

float round_merge(float a, float b, float r){
    vec2 intersectionSpace = vec2(a - r, b - r);
    intersectionSpace = min(intersectionSpace, 0.0);
    float insideDistance = -length(intersectionSpace);
    float simpleUnion = merge(a, b);
    float outsideDistance = max(simpleUnion, r);
    return insideDistance + outsideDistance;
}

// 2D SDFs

// Signed Distance Function for a circle shape
float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

// Signed Distance Function for a soft circle shape
float sdSoftCircle(vec2 p, float r, float s) {
    return max(length(p) - r, 0.0) - s;
}

// Signed Distance Function for a line segment
float sdLine(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

// Signed Distance Function for an axis aligned plane
float sdPlane(vec3 p, vec3 normal, float distance) {
    return dot(p, normal) - distance;
}

// Signed Distance Function for a box shape
float sdBox(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return max(d.x, d.y);
    // return vec4(length(max(d, 0.0)) + min(max(d.x, d.y), 0.0), 0.0, 0.0, 1.0);
}

// Signed Distance Function for a soft box shape
float sdSoftBox(vec2 p, vec2 b, float r) {
    vec2 d = abs(p) - b + r;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

// 3D SDFs

// Signed Distance Function for a sphere shape
float sdSphere(vec3 p, float s) {
    return length(p) - s;
}

// Signed Distance Function for a box shape
float sdBox(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

// Signed Distance Function for a rounded box shape
float sdRoundBox( vec3 p, vec3 b, float r ) {
  vec3 q = abs(p) - b + r;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

// SDFs with gradient

// Signed Distance Gradient Function for a circle shape
// vec3 sdgCircle(vec2 p, float r) {
//     float d = length(p);
//     return vec3(d - r, p / d);
// }

// // Signed Distance Gradient Function for a segment shape
// vec3 sdgSegment(vec2 p, vec2 a, vec2 b, float r ) {
//     vec2 ba = b - a, pa = p - a;
//     float h = clamp( dot(pa, ba) / dot(ba, ba), 0.0, 1.0 );
//     vec2  q = pa - h * ba;
//     float d = length(q);
//     return vec3(d - r,q / d);
// }

// // Signed Distance Gradient Function for a box shape
// vec3 sdgBox(vec2 p, vec2 b)
// {
//     vec2 w = abs(p) - b;
//     vec2 s = vec2(p.x < 0.0 ? - 1 : 1, p.y < 0.0 ? -1 : 1);
//     float g = max(w.x, w.y);
//     vec2  q = max(w, 0.0);
//     float l = length(q);
//     return vec3(
//         (g > 0.0) ? l : g,
//         s * ((g > 0.0) ? q / l : (
//             (w.x > w.y) ? vec2(1, 0) : vec2(0, 1)
//         ))
//     );
// }
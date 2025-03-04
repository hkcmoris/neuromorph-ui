precision highp float;

#include "SDF.glsl";

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

const int MAX_MARCHING_STEPS = 256;
const float EPSILON = 0.001;
const float start = 0.0;
const float end = 100.0;

vec3 getRayDirection(vec2 uv, vec3 cameraPosition, vec3 cameraTarget, float fov) {
    vec3 forward = normalize(cameraTarget - cameraPosition);
    vec3 right = normalize(cross(forward, vec3(0.0, 1.0, 0.0)));
    vec3 up = cross(right, forward);
    float aspectRatio = u_resolution.x / u_resolution.y;
    float scale = tan(radians(fov * 0.5));
    vec3 rayDirection = normalize(forward + uv.x * scale * right + uv.y * scale / aspectRatio * up);
    return rayDirection;
}

float sceneSDF(vec3 p, out int material) {
    vec3 floorBounds = vec3(10.0, 1.0, 10.0);
    vec3 objectOffset = vec3(0.0, -0.5, 0.0);

    float sphereDist = sdSphere(p + objectOffset, 0.25);
    float boxDist = sdRoundBox(p + objectOffset, vec3(0.6, 0.1, 0.4), 0.01);
    float floorDist = sdBox(p + floorBounds.y, floorBounds);

    float objectDist = round_merge(sphereDist, boxDist, 0.4 + sin(u_time) * 0.3);
    
    if (objectDist < floorDist) {
        material = 1; // Foreground material
        return objectDist;
    } else {
        material = 2; // Floor material
        return floorDist;
    }
}

float raymarch(vec3 eye, vec3 viewRayDirection, out int material) {
    float depth = start;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        float dist = sceneSDF(eye + depth * viewRayDirection, material);
        if (dist < EPSILON) {
            return depth;
        }
        depth += dist;
        if (depth >= end) {
            material = 0; // Background material
            return end;
        }
    }
    material = 0; // Background material
    return end;
}

/**
 * Using the gradient of the SDF, estimate the normal on the surface at point p.
 */
vec3 estimateNormal(vec3 p) {
    int tempMaterial;
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z), tempMaterial) - sceneSDF(vec3(p.x - EPSILON, p.y, p.z), tempMaterial),
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z), tempMaterial) - sceneSDF(vec3(p.x, p.y - EPSILON, p.z), tempMaterial),
        sceneSDF(vec3(p.x, p.y, p.z  + EPSILON), tempMaterial) - sceneSDF(vec3(p.x, p.y, p.z - EPSILON), tempMaterial)
    ));
}

// Main function
void main() {
    // vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / u_resolution.y;
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / u_resolution;
    vec2 mouse = (u_mouse - 0.5 * u_resolution) / u_resolution.y;
    vec4 color = u_background;

    float radius = 10.0;
    float angle = u_time * 0.5; // Adjust the speed of the orbit
    vec3 cameraPosition = vec3(radius * cos(angle), 3.0, radius * sin(angle));
    vec3 cameraTarget = vec3(0.0, 0.0, 0.0);
    float fov = 45.0;

    // Define the light direction
    vec3 lightDirection = normalize(vec3(1.0, 1.0, 1.0));

    vec3 viewRayDirection = getRayDirection(uv, cameraPosition, cameraTarget, fov);
    int material;
    float depth = raymarch(cameraPosition, viewRayDirection, material);

    if (depth < end) {
        vec3 hitPoint = cameraPosition + depth * viewRayDirection;
        vec3 normal = estimateNormal(hitPoint);
        
        // Calculate the diffuse lighting
        float diffuse = max(dot(normal, lightDirection), 0.0);

        // Apply the lighting to the color based on the material
        if (material == 1) {
            color = vec4(u_foreground.rgb * diffuse, u_foreground.a);
        } else if (material == 2) {
            color = vec4(u_border.rgb * diffuse, u_border.a);
        }
    }

    gl_FragColor = color;
}
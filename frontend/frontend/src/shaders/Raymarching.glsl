precision highp float;

#include "SDF.glsl";

uniform vec2 u_resolution;  // Screen resolution
uniform vec2 u_mouse;       // Mouse position
uniform float u_time;       // Time for animations
uniform vec4 u_background;  // Background color
uniform vec4 u_foreground;  // Foreground color
uniform vec4 u_floor;       // Floor color

uniform mat4 projectionMatrix;

const int MAX_MARCHING_STEPS = 256;
const float EPSILON = 0.001;
const float start = 0.0;
const float end = 100.0;

float sceneSDF(vec3 p, out int material) {
    float floor = sdPlane(p, vec3(0.0, 1.0, 0.0), -1.0);
    vec3 objectOffset = vec3(0.0, 0.5, 0.0);
    vec3 objectPosition = p - objectOffset;
    objectPosition.x = merge(mod(objectPosition.x, 2.0), mod(-objectPosition.x, 2.0));
    objectPosition.y = merge(mod(objectPosition.y, 2.0), mod(-objectPosition.y, 2.0));
    objectPosition.z = merge(mod(objectPosition.z, 2.0), mod(-objectPosition.z, 2.0));

    float sphereDist = sdSphere(objectPosition, 0.25);
    float boxDist = sdRoundBox(p - objectOffset, vec3(0.6, 0.1, 0.4), 0.01);

    float object = round_merge(sphereDist, boxDist, 0.4 + sin(u_time) * 0.3);
    
    if (object < floor) {
        material = 1; // Foreground material
        return object;
    } else {
        material = 2; // Floor material
        return floor;
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

vec4 applyGrid(vec3 position, vec4 baseColor) {
    float gridSize = 1.0;
    float lineWidth = 0.5;
    vec2 grid = abs(fract(position.xz / gridSize - 0.5) - 0.5) / fwidth(position.xz / gridSize);
    float line = min(grid.x, grid.y);
    float gridPattern = 1.0 - smoothstep(0.0, lineWidth, line);
    return mix(baseColor, vec4(0.0, 0.0, 0.0, 1.0), gridPattern);
}

// Main function
void main() {
    // vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / u_resolution.y;
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / u_resolution;
    vec2 mouse = (u_mouse - 0.5 * u_resolution) / u_resolution.y;
    vec4 color = u_background;

    // Define the light direction
    vec3 lightDirection = normalize(vec3(1.0, 1.0, 1.0));

    // Convert screen space coordinates to normalized device coordinates (NDC)
    vec4 ndc = vec4(uv, 1.0, 1.0);

    // Transform NDC to world space
    vec4 viewRay = inverse(projectionMatrix) * ndc;
    viewRay = inverse(viewMatrix) * vec4(viewRay.xyz, 0.0);
    vec3 viewRayDirection = normalize(viewRay.xyz);

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
            color = vec4(u_floor.rgb * diffuse, u_floor.a);
            color = applyGrid(hitPoint, color);
        }
    }

    gl_FragColor = color;
}
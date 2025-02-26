import * as THREE from 'three';
import fragmentShader from './shaders/BasicSoftDepthFragment.glsl';
import vertexShader from './shaders/BasicSoftDepthVertex.glsl';
import { GUI } from 'dat.gui';

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
const renderer = new THREE.WebGLRenderer({
    antialias: true
});
renderer.setSize(window.innerWidth, window.innerHeight);
document.body.appendChild(renderer.domElement);

const uniforms = {
    u_resolution: { value: new THREE.Vector2(window.innerWidth, window.innerHeight) },
    u_mouse: { value: new THREE.Vector2(0, 0) },
    u_time: { value: 0 },
    u_mode: { value: 2 },
    u_distanceVisualisationScale: { value: 16 },
    u_offset: { value: 0.005 },
    u_borderWidth: { value: 0.01 },
    u_neonPower: { value: 0.5 },
    u_neonBrightness: { value: 0.5 },
    u_shadowDist: { value: 0.1 },
    u_shadowBorderWidth: { value: 0.01 },
};

let geometry = new THREE.PlaneGeometry(2, 2);

const material = new THREE.ShaderMaterial({
    vertexShader,
    fragmentShader,
    uniforms,
});

const mesh = new THREE.Mesh(geometry, material);
scene.add(mesh);

camera.position.z = 1;

function animate() {
    requestAnimationFrame(animate);
    material.uniforms.u_time.value += 0.01;
    material.uniformsNeedUpdate = true;
    if (renderer && renderer.getContext().isContextLost() === false) {
        renderer.render(scene, camera);
    }
}
animate();

function resizePlane() {
    const aspect = window.innerWidth / window.innerHeight;
    geometry.dispose();
    geometry = new THREE.PlaneGeometry(2 * aspect, 2);
    mesh.geometry = geometry;

    material.uniforms.u_resolution.value.set(window.innerWidth, window.innerHeight);
    material.uniformsNeedUpdate = true;
}

window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
    resizePlane();
});

document.addEventListener("mousemove", (event) => {
    material.uniforms.u_mouse.value.set(event.clientX, window.innerHeight - event.clientY);
    material.uniformsNeedUpdate = true;
});

// Initial resize to set the correct plane size
resizePlane();

// Set up dat.GUI
const gui = new GUI();
gui.add(uniforms.u_mode, 'value', { Raw: 1, Distance: 2, Gradient: 3, Solid: 4, Border: 5, SolidWithBorder: 6, SoftBorder: 7, Neon: 8, DropShadow: 10 }).name('Mode');
gui.add(uniforms.u_distanceVisualisationScale, 'value', 0, 100).name('Distance Visualization Scale');
gui.add(uniforms.u_offset, 'value', -0.1, 0.1).name('Offset');
gui.add(uniforms.u_borderWidth, 'value', 0, 0.1).name('Border Width');
gui.add(uniforms.u_neonPower, 'value', 0, 1).name('Neon Power');
gui.add(uniforms.u_neonBrightness, 'value', 0, 1).name('Neon Brightness');
gui.add(uniforms.u_shadowDist, 'value', 0, 1).name('Shadow Distance');
gui.add(uniforms.u_shadowBorderWidth, 'value', 0, 0.1).name('Shadow Border Width');

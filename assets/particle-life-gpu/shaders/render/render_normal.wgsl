struct SimOptions {
    simWidth: f32,
    simHeight: f32,
    gridWidth: u32,
    gridHeight: u32,
    cellSize: f32,
    numParticles: u32,
    numTypes: u32,
    particleSize: f32,
    particleOpacity: f32,
    isWallRepel: u32,
    isWallWrap: u32,
    forceFactor: f32,
    frictionFactor: f32,
    repel: f32,
    extendedGridWidth: u32,
    extendedGridHeight: u32,
    gridOffsetX: u32,
    gridOffsetY: u32,
    mirrorWrapCount: u32,
};
struct Particle {
    x : f32,
    y : f32,
    vx : f32,
    vy : f32,
    particleType : f32,
}
struct Camera {
    centerX: f32,
    centerY: f32,
    scaleX: f32,
    scaleY: f32,
}

struct SimMetrics {
    max_energy: i32,
    particlesEnergy: array<i32>,
}

struct DebugOptions {
    isHeatmapActive: u32,
    maxParticleCount: f32,
};

const QUAD_VERTICES = array<vec2<f32>, 4>(
    vec2<f32>(-1.0, -1.0),
    vec2<f32>( 1.0, -1.0),
    vec2<f32>(-1.0,  1.0),
    vec2<f32>( 1.0,  1.0)
);

@group(0) @binding(0) var<storage, read> particles: array<Particle>;
@group(0) @binding(1) var<storage, read> colors: array<vec4<f32>>;
@group(0) @binding(2) var<storage, read> metrics: SimMetrics;
@group(1) @binding(0) var<uniform> options: SimOptions;
@group(2) @binding(0) var<uniform> camera: Camera;
@group(3) @binding(0) var<uniform> debugOptions: DebugOptions;

struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) offset: vec2<f32>,
    @location(1) color: vec4<f32>,
}

@vertex
fn vertexMain(
    @builtin(instance_index) instanceIndex: u32,
    @builtin(vertex_index) vertexIndex: u32
) -> VertexOutput {
    if (instanceIndex >= options.numParticles) {
        return VertexOutput(vec4f(0.0), vec2f(0.0), vec4f(0.0));
    }
    let particle = particles[instanceIndex];
    let particleCenterPos = vec2f(particle.x, particle.y);

    let energy = metrics.particlesEnergy[instanceIndex];

    //TODO: Make this toggleable
    let color = select(
        colors[u32(particle.particleType)],
        massPotential_to_color(f32(energy)),
        debugOptions.isHeatmapActive == 1u
    );
    //let color = massPotential_to_color(f32(energy));

    let cameraScale = vec2f(camera.scaleX, -camera.scaleY);
    let cameraCenter = vec2f(camera.centerX, camera.centerY);
    let transformedCenterPos = fma(particleCenterPos, cameraScale, -cameraCenter * cameraScale);

    let quadOffset = QUAD_VERTICES[vertexIndex];
    let vertexOffset = quadOffset * options.particleSize * cameraScale;
    let finalPos = transformedCenterPos + vertexOffset;

    return VertexOutput(
        vec4f(finalPos, 0.0, 1.0),
        quadOffset,
        color
    );
}

fn massPotential_to_color(energy:f32) -> vec4<f32>{

    //let adj_energy = pow(energy,2); //adjust energy state so that extreme values are more visible
    //let adj_energy = energy;

	//let heat_factor = adj_energy/f32(metrics.max_energy) ; // compare all energy states to the current maximal state in the system
    //let heat_factor = adj_energy/f32(10) ;
    //let heat_factor = f32(adj_energy/debugOptions.maxParticleCount);

	//let scaled_heat_factor = 1 / (1 + exp(heat_factor)); //sigmoid transform to regularize values
    //let scaled_heat_factor = heat_factor;
    //let scaled_heat_factor = pow(heat_factor,2); //transform so that extreme values are more visible

    //Project regularized values onto a gradient
    //Gradient: #00ffff - #ff6666
    //return vec4<f32>(f32(scaled_heat_factor * 255f), f32(255f - (scaled_heat_factor * 153f)), f32(255f - (scaled_heat_factor * 153f)), 1.0);

    //TODO: Make these two bounds paramaterizable
    let bound_upper = 0.75;
    let bound_lower = 0.25;

    let heat_factor = energy/f32(metrics.max_energy) ;
    if(heat_factor >= bound_upper){
        return vec4<f32>(f32(255), f32(0), f32(0), 1.0);
    }
    else if(heat_factor <= bound_lower){
        return vec4<f32>(f32(0), f32(255), f32(255), 1.0);
    }
    else{
        return vec4<f32>(f32(128), f32(128), f32(128), 1.0);
    }
}

@fragment
fn fragmentMain(in: VertexOutput) -> @location(0) vec4f {
    let dist_sq = dot(in.offset, in.offset);
    let edge_width = fwidth(dist_sq);
    let alpha = 1.0 - smoothstep(max(0.0, 1.0 - edge_width), 1.0, dist_sq);

    return vec4f(in.color.rgb, in.color.a * options.particleOpacity * alpha);
}

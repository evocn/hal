// Mak
// Particles
// Alex Hartford
// September 2023

Particle :: struct {
    // Properties
    square : Square;
    text  : string;
    color : Color;

    // State
    time : float;
}

particles : [..] Particle;

generate_particle :: (square: Square, text: string, color: Color) {
    particle := array_add(*particles);
    particle.square = square;
    particle.text   = text; // This is allocated by the caller.
    particle.color  = color;
}

destroy :: (particle: *Particle) {
    free(particle.text.data);
}

update_particles :: (dt: float) {
    for * particles {
        it.time += dt;

        if it.time > PARTICLE_LIFESPAN {
            destroy(it);
            remove it;
        }
    }
}

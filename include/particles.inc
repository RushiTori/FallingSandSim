%ifndef PARTICLES_INC
%define PARTICLES_INC

%include "simulation.inc"

; enum ParticleType

	reset_enum_value(0)

	add_enum(PARTICLE_EMPTY)

	add_enum(PARTICLE_SOLID_WALL)

	add_enum(PARTICLE_SAND)

	add_enum(PARTICLE_WATER)

	add_enum(PARTICLE_TYPE_COUNT)

struc Particle
	; ParticleType type;
	struc_member(uint8_t, type, 1)
endstruc

; Init some particles
; void init_particles(void);
extern init_particles

; Updates all particles
; void update_particles(void);
extern update_particles

%endif ; PARTICLES_INC

%ifndef PARTICLES_INC
%define PARTICLES_INC

%include "raylib.inc"
%include "std.inc"

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

SIM_PARTICLES_WIDTH  equ 1920
SIM_PARTICLES_HEIGHT equ 1080
SIM_PARTICLES_COUNT  equ SIM_PARTICLES_WIDTH*SIM_PARTICLES_HEIGHT

; Array of all the particles in the simulation
; Particle particles[SIM_PARTICLES_COUNT]
extern particles

; Lookup table for the color of each particle type
; Color particle_colors[PARTICLE_TYPE_COUNT+1];
extern particle_colors

; Lookup table for the update function to call on each particle type
; typedef void (*ParticleUpdateCall)(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t);
; ParticleUpdateCall particle_update_calls[PARTICLE_TYPE_COUNT+1];
extern particle_update_calls

; Places a particle of type 'type' at index idx
; void place_particle(uint64_t idx, uint8_t type);
; NOTE: Affects ONLY RAX and RDX, keeps all other registers states for convenience
extern place_particle

; Returns the type of the particle at x,y or PARTICLE_TYPE_COUNT if x,y is out of width,height bounds
; uint8_t get_particle_type(uint64_t x, uint64_t y, uint64_t width, uint64_t height, uint64_t idx);
; NOTE: Does NOT modify RDI, RSI, RDX, RCX, R8 for convenience
extern get_particle_type

%endif ; PARTICLES_INC

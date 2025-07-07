%ifndef SIMULATION_INC
%define SIMULATION_INC

%include "particles.inc"

SIM_PIXELS_WIDTH  equ SIM_PARTICLES_WIDTH
SIM_PIXELS_HEIGHT equ SIM_PARTICLES_HEIGHT
SIM_PIXELS_COUNT  equ (SIM_PIXELS_WIDTH*SIM_PIXELS_HEIGHT)

; Width of the simulation (default=100)
; uint32_t simulation_width;
extern simulation_width

; Height of the simulation (default=100)
; uint32_t simulation_height;
extern simulation_height

; Pixel array of the simulation
; Color simulation_pixels[SIM_PIXELS_COUNT];
extern simulation_pixels

; Initializes some simulation's states
; bool init_simulation(void);
extern init_simulation

; Frees the states initialized by 'init_simulation'
; void free_simulation(void);
extern free_simulation

; Updates the simulation
; void update_simulation(void);
extern update_simulation

; Renders the simulation based on the pixels and width/height
; void render_simulation(void);
extern render_simulation

; Returns via RDX:RAX the particle position equivalent to x,y
; typedef struct Vec2u64 { uint64_t px, py; } Vec2u64;
; Vec2u64 get_screen_to_particle_pos(uint64_t x, uint64_t y);
extern get_screen_to_particle_pos

%endif ; SIMULATION_INC

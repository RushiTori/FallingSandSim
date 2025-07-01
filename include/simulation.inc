%ifndef SIMULATION_INC
%define SIMULATION_INC

%include "raylib.inc"
%include "std.inc"

SIM_PIXELS_WIDTH  equ 1920
SIM_PIXELS_HEIGHT equ 1080

; Width of the simulation (default=100)
; uint32_t simulation_width;
extern simulation_width

; Height of the simulation (default=100)
; uint32_t simulation_height;
extern simulation_height

; Pixel array of the simulation
; Color simulation_pixels[SIM_PIXELS_WIDTH*SIM_PIXELS_HEIGHT];
extern simulation_pixels

; Initializes some simulation's states
; bool init_simulation(void);
extern init_simulation

; Frees the states initialized by 'init_simulation'
; void free_simulation(void);
extern free_simulation

; Renders the simulation based on the pixels and width/height
; void render_simulation(void);
extern render_simulation

%endif ; SIMULATION_INC

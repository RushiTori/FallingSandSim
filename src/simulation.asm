bits    64
default rel

%include "simulation.inc"

SIM_PIXELS_WIDTH  equ 1920
SIM_PIXELS_HEIGHT equ 1080
SIM_PIXELS_LEN    equ (SIM_PIXELS_WIDTH*SIM_PIXELS_HEIGHT)

section .data

; Width of the simulation (default=100)
; uint32_t simulation_width;
var(global, uint32_t, simulation_width, 100)

; Height of the simulation (default=100)
; uint32_t simulation_height;
var(global, uint32_t, simulation_height, 100)

section .rodata

sim_pixels_img:
static  sim_pixels_img: data
	istruc Image
		at .data,    dq simulation_pixels
		at .width,   dd SIM_PIXELS_WIDTH
		at .height,  dd SIM_PIXELS_HEIGHT
		at .mipmaps, dd 1
		at .format,  dd PIXELFORMAT_UNCOMPRESSED_R8G8B8A8
	iend

section .bss

; Pixel array of the simulation
; Color simulation_pixels[SIM_PIXELS_WIDTH*SIM_PIXELS_HEIGHT];
res_array(global, color_t, simulation_pixels, SIM_PIXELS_LEN)

sim_pixels_tex:
static  sim_pixels_tex: data
	resb sizeof(Texture)

res(static,  uint32_t, screen_width)
res(static,  uint32_t, screen_height)

section      .text

; Initializes some simulation's states
; bool init_simulation(void);
func(global, init_simulation)
	sub    rsp,         8 + 32
	mov    rax,         qword [sim_pixels_img]
	movups xmm0,        [sim_pixels_img + 8]
	mov    qword [rsp], rax
	movups [rsp + 8],   xmm0
	lea    rdi,         [sim_pixels_tex]
	call   LoadTextureFromImage
	add    rsp,         8 + 32
	ret

; Frees the states initialized by 'init_simulation'
; void free_simulation(void);
func(global, free_simulation)
	sub rsp, 24

	mov    eax,         dword [sim_pixels_tex]
	movups xmm0,        [sim_pixels_tex + 4]
	mov    dword [rsp], eax
	movups [rsp + 4],   xmm0
	call   UnloadTexture

	add rsp, 24
	ret

; Renders the simulation based on the pixels and width/height
; void render_simulation(void);
func(global, render_simulation)
	sub rsp, 24

	mov    eax,         dword [sim_pixels_tex]
	movups xmm0,        [sim_pixels_tex + 4]
	mov    dword [rsp], eax
	movups [rsp + 4],   xmm0

	lea  rdi, [simulation_pixels]
	call UpdateTexture

	call GetScreenWidth
	mov  uint32_p [screen_width], eax

	call GetScreenHeight
	mov  uint32_p [screen_height], eax

	xorps    xmm0, xmm0
	cvtpi2ps xmm1, qword [simulation_width]
	xorps    xmm2, xmm2
	cvtpi2ps xmm3, qword [screen_width]
	xorps    xmm4, xmm4
	xorps    xmm5, xmm5

	mov rdi, COLOR_WHITE

	mov    eax,         dword [sim_pixels_tex]
	movups xmm0,        [sim_pixels_tex + 4]
	mov    dword [rsp], eax
	movups [rsp + 4],   xmm0

	; mov    eax,         dword [sim_pixels_tex]
	; movups xmm0,        [sim_pixels_tex + 4]
	; mov    dword [rsp], eax
	; movups [rsp + 4],   xmm0
	; xor rdi, rdi
	; xor rsi, rsi
	; mov rdx, COLOR_WHITE
	; call DrawTexture

	; Draw a part of a texture defined by a rectangle with 'pro' parameters
	; void DrawTexturePro(Texture2D texture, Rectangle source, Rectangle dest, Vector2 origin, float rotation, Color tint);

	call DrawTexturePro

	add rsp, 24
	ret

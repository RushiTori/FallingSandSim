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

; Updates the simulation
; void update_simulation(void);
func(global, update_simulation)
	push rbx ; idx
	push r12 ; x
	push r13 ; width
	push r14 ; y
	push r15 ; height

	xor r13, r13
	xor r15, r15

	mov r13d, uint32_p [simulation_width]
	mov r15d, uint32_p [simulation_height]

	mov rax, SIM_PIXELS_WIDTH
	mul r15
	sub rax, SIM_PIXELS_WIDTH
	mov rbx, rax

	mov r14, r15
	.update_loop_y:
		dec r14
		xor r12, r12
		.update_loop_x:
			mov  rdi, r12
			mov  rsi, r14
			mov  rdx, r13
			mov  rcx, r15
			mov  r8,  rbx
			call get_particle_type

			lea  r9,  [particle_update_calls]
			shl  rax, 3
			add  r9,  rax
			call pointer_p [r9]

			inc rbx
			inc r12
			cmp r12, r13
			jb  .update_loop_x
		sub rbx, r13
		sub rbx, SIM_PIXELS_WIDTH

		cmp r14, 0
		jnz .update_loop_y

	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	ret

; Renders the simulation based on the pixels and width/height
; void render_simulation(void);
func(global, render_simulation)
	sub rsp, 24
	
	lea rdi, [simulation_pixels]
	lea rsi, [particles]
	mov rcx, SIM_PARTICLES_COUNT

	lea r9, [particle_colors]
	.pixels_loop:
		xor rax,           rax
		mov al,            uint8_p [rsi + Particle.type]
		shl rax,           2
		add rax,           r9
		mov eax,           color_p [rax]
		mov color_p [rdi], eax

		add  rdi, sizeof(color_s)
		add  rsi, sizeof(Particle)
		loop .pixels_loop

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

; Returns via RDX:RAX the particle position equivalent to x,y
; typedef struct Vec2u64 { uint64_t px, py; } Vec2u64;
; Vec2u64 get_screen_to_particle_pos(uint64_t x, uint64_t y);
func(global, get_screen_to_particle_pos)
	sub  rsp, 8
	push rsi
	push rdi
	call GetScreenWidth
	mov  ecx, uint32_p [simulation_width]
	xor  rdx, rdx
	div  ecx
	mov  ecx, eax
	pop  rax
	xor  rdx, rdx
	div  ecx
	push rax

	call GetScreenHeight
	pop  rdi
	mov  ecx, uint32_p [simulation_height]
	xor  rdx, rdx
	div  ecx
	mov  ecx, eax
	pop  rax
	xor  rdx, rdx
	div  ecx
	mov  rdx, rax
	mov  rax, rdi
	add  rsp, 8
	ret

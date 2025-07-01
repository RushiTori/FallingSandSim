bits    64
default rel

%include "particles.inc"

section .bss

particles:
static  particles: data
	resb sizeof(Particle) * SIM_PIXELS_WIDTH * SIM_PIXELS_HEIGHT
particles_size  equ $ - particles
particles_count equ particles_size / sizeof(Particle)

section .rodata

particle_colors:
static  particle_colors: data
	dd COLOR_LIGHTGRAY ; PARTICLE_EMPTY
	dd COLOR_GRAY      ; PARTICLE_SOLID_WALL
	dd COLOR_YELLOW    ; PARTICLE_SAND
	dd COLOR_BLUE      ; PARTICLE_WATER
	dd COLOR_LIME      ; PARTICLE_TYPE_COUNT

particle_update_calls:
static particle_colors: data
	dq no_update   ; PARTICLE_EMPTY
	dq no_update   ; PARTICLE_SOLID_WALL
	dq update_sand ; PARTICLE_SAND
	dq no_update   ; PARTICLE_WATER
	dq no_update   ; PARTICLE_TYPE_COUNT

section      .text

; Returns the type of the particle at x,y or PARTICLE_TYPE_COUNT if x,y is out of width,height bounds
; uint8_t get_particle_type(uint64_t x, uint64_t y, uint64_t width, uint64_t height, uint64_t idx);
; NOTE: Does NOT modify RDI, RSI, RDX, RCX, R8 for convenience
func(static, get_particle_type)
	mov rax, PARTICLE_TYPE_COUNT

	; test x and width
		cmp rdi, rdx
		jae .end

	; test y and height
		cmp rsi, rcx
		jae .end

	mov   rax, r8
	mov   r9,  sizeof(Particle)
	push  rdx
	mul   r9
	pop   rdx
	lea   r9,  [particles]
	add   r9,  rax
	movzx rax, uint8_p [r9 + Particle.type]

	.end:
	ret

; Swaps 2 particles' data
; NOTE: Does NOT perform OOB checks
; void swap_particles(uint64_t idx1, uint64_t idx2)
func(static, swap_particles)
	mov rax, sizeof(Particle)
	mul rdi
	mov rdi, rax

	mov rax, sizeof(Particle)
	mul rsi
	mov rsi, rax

	lea rax, [particles]
	add rdi, rax
	add rsi, rax

	mov al,                            uint8_p [rdi + Particle.type]
	mov dl,                            uint8_p [rsi + Particle.type]
	mov uint8_p [rsi + Particle.type], al
	mov uint8_p [rdi + Particle.type], dl

	ret

; Does nothing
; void no_update(uint64_t x, uint64_t y, uint64_t width, uint64_t height, uint64_t idx);
func(static, no_update)
	ret

; Tries to go down, down left/right by swapping with empty or water
; void update_sand(uint64_t x, uint64_t y, uint64_t width, uint64_t height, uint64_t idx);
func(static, update_sand)
	cmp rsi, rcx
	jae .end

	inc  rsi
	add  r8, SIM_PIXELS_WIDTH
	call get_particle_type

	cmp rax, PARTICLE_EMPTY
	je  .go_down
	cmp rax, PARTICLE_WATER
	jne .skip_down

	.go_down:
		mov  rdi, r8
		mov  rsi, r8
		sub  rsi, SIM_PIXELS_WIDTH
		call swap_particles
	.skip_down:

	.end:
	ret

; Init some particles
; void init_particles(void);
func(global, init_particles)
	lea rdi, [particles]
	mov ecx, uint32_p [simulation_width]
	.loop_:
		rdrand eax
		jnc    .loop_
		and    al, 1
		jz     .skip_sand
			mov uint8_p [rdi + Particle.type], PARTICLE_SAND
		.skip_sand:
		add  rdi, sizeof(Particle)
		loop .loop_
	ret

; Updates all particles
; void update_particles(void);
func(global, update_particles)
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
	
	lea rdi, [simulation_pixels]
	lea rsi, [particles]
	mov rcx, particles_count

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

	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	ret

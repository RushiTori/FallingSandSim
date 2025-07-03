bits    64
default rel

%include "particles.inc"

section .bss

particles:
global  particles: data
	resb sizeof(Particle) * SIM_PARTICLES_COUNT
particles_size  equ $ - particles
particles_count equ particles_size / sizeof(Particle)

section .rodata

particle_colors:
global  particle_colors: data
	dd COLOR_LIGHTGRAY ; PARTICLE_EMPTY
	dd COLOR_GRAY      ; PARTICLE_SOLID_WALL
	dd COLOR_YELLOW    ; PARTICLE_SAND
	dd COLOR_BLUE      ; PARTICLE_WATER
	dd COLOR_BLANK     ; PARTICLE_TYPE_COUNT

particle_update_calls:
global particle_update_calls: data
	dq no_update    ; PARTICLE_EMPTY
	dq no_update    ; PARTICLE_SOLID_WALL
	dq update_sand  ; PARTICLE_SAND
	dq update_water ; PARTICLE_WATER
	dq no_update    ; PARTICLE_TYPE_COUNT

section      .text

; Places a particle of type 'type' at index idx
; void place_particle(uint64_t idx, uint8_t type);
; NOTE: Does NOT modify RDI and RSI for convenience
func(global, place_particle)
	mov rax, sizeof(Particle)
	mul rdi

	mov uint8_p [particles + rax + Particle.type], sil
	ret

; Returns the type of the particle at x,y or PARTICLE_TYPE_COUNT if x,y is out of width,height bounds
; uint8_t get_particle_type(uint64_t x, uint64_t y, uint64_t width, uint64_t height, uint64_t idx);
; NOTE: Does NOT modify RDI, RSI, RDX, RCX, R8 for convenience
func(global, get_particle_type)
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
	add  r8, SIM_PARTICLES_WIDTH
	call get_particle_type

	cmp rax, PARTICLE_EMPTY
	je  .go_down
	cmp rax, PARTICLE_WATER
	jne .skip_down

	.go_down:
		mov  rdi, r8
		mov  rsi, r8
		sub  rsi, SIM_PARTICLES_WIDTH
		call swap_particles
		jmp  .end
	.skip_down:

	cmp rdi, 0
	je  .skip_down_left

	.gen_rand:
		rdrand ax
		jnc    .gen_rand
		and    al, 1
		jz     .skip_down_left

	dec  rdi
	dec  r8
	call get_particle_type

	cmp rax, PARTICLE_EMPTY
	je  .go_down_left
	cmp rax, PARTICLE_WATER
	jne .skip_down_left

	.go_down_left:
		mov  rdi, r8
		mov  rsi, r8
		sub  rsi, SIM_PARTICLES_WIDTH
		inc  rsi
		call swap_particles
		jmp  .end
	.skip_down_left:

	cmp rdi, rdx
	jae .skip_down_right

	inc  rdi
	inc  r8
	call get_particle_type

	cmp rax, PARTICLE_EMPTY
	je  .go_down_right
	cmp rax, PARTICLE_WATER
	jne .skip_down_right

	.go_down_right:
		mov  rdi, r8
		mov  rsi, r8
		sub  rsi, SIM_PARTICLES_WIDTH
		dec  rsi
		call swap_particles
	.skip_down_right:

	.end:
	ret

; Tries to go down, if it can't, tries to go left or right
; void update_water(uint64_t x, uint64_t y, uint64_t width, uint64_t height, uint64_t idx);
func(static, update_water)
	cmp rsi, rcx
	jae .skip_down

	inc  rsi
	add  r8, SIM_PARTICLES_WIDTH
	call get_particle_type

	cmp rax, PARTICLE_EMPTY
	jne .skip_down

	.go_down:
		mov  rdi, r8
		mov  rsi, r8
		sub  rsi, SIM_PARTICLES_WIDTH
		call swap_particles
		jmp  .end
	.skip_down:


	dec rsi
	sub r8, SIM_PARTICLES_WIDTH

	cmp rdi, 0
	je  .skip_left

	.gen_rand:
		rdrand ax
		jnc    .gen_rand
		and    al, 1
		jz     .skip_left

	dec  rdi
	dec  r8
	call get_particle_type

	cmp rax, PARTICLE_EMPTY
	jne .skip_left

	.go_left:
		mov  rdi, r8
		mov  rsi, r8
		inc  rsi
		call swap_particles
		jmp  .end
	.skip_left:



	cmp rdi, rdx
	jae .skip_right

	inc  rdi
	inc  r8
	call get_particle_type

	cmp rax, PARTICLE_EMPTY
	jne .skip_right

	.go_right:
		mov  rdi, r8
		mov  rsi, r8
		dec  rsi
		call swap_particles
	.skip_right:

	.end:
	ret

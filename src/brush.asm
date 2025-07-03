bits    64
default rel

%include "brush.inc"

section .rodata

ghost_tex_img:
static  ghost_tex_img: data
	istruc Image
		at .data,    dq ghost_tex_buffer
		at .width,   dd SIM_PIXELS_WIDTH
		at .height,  dd SIM_PIXELS_HEIGHT
		at .mipmaps, dd 1
		at .format,  dd PIXELFORMAT_UNCOMPRESSED_R8G8B8A8
	iend

memset_pattern:
static memset_pattern: data
	db PARTICLE_TYPE_COUNT
	db PARTICLE_TYPE_COUNT
	db PARTICLE_TYPE_COUNT
	db PARTICLE_TYPE_COUNT

	db PARTICLE_TYPE_COUNT
	db PARTICLE_TYPE_COUNT
	db PARTICLE_TYPE_COUNT
	db PARTICLE_TYPE_COUNT

	db PARTICLE_TYPE_COUNT
	db PARTICLE_TYPE_COUNT
	db PARTICLE_TYPE_COUNT
	db PARTICLE_TYPE_COUNT

	db PARTICLE_TYPE_COUNT
	db PARTICLE_TYPE_COUNT
	db PARTICLE_TYPE_COUNT
	db PARTICLE_TYPE_COUNT

brush_call_table:
static brush_call_table: data
	dq add_shape_diamond ; BRUSH_DIAMOND
	dq add_shape_square  ; BRUSH_SQUARE
	dq add_ghost         ; BRUSH_CIRCLE
	dq add_ghost         ; BRUSH_SELECTION
	dq add_ghost         ; BRUSH_BUCKET
	dq add_ghost         ; BRUSH_TYPE_COUNT

section .bss

ghost_tex:
static  ghost_tex: data
	resb sizeof(Texture)

res_array(static, color_t, ghost_tex_buffer, SIM_PARTICLES_COUNT)

res_array(static, uint8_t, ghost_particles, SIM_PARTICLES_COUNT)

res(static,  uint64_t, ghost_start_x)
res(static,  uint64_t, ghost_start_y)

res(static,  uint64_t, ghost_end_x)
res(static,  uint64_t, ghost_end_y)

res(static,  uint32_t, brush_size)
res(static,  uint8_t,  brush_type)
res(static,  uint8_t,  brush_particle_type)

section      .text

; void add_ghost(uint64_t x, uint64_t y, uint8_t type);
; NOTE: Only modifies RAX for convenience
func(static, add_ghost)
	cmp rdi, SIM_PARTICLES_WIDTH
	jae .end
	cmp rsi, SIM_PARTICLES_HEIGHT
	jae .end

	push rdx
	mov  rax,                             SIM_PARTICLES_WIDTH
	mul  rsi
	add  rax,                             rdi
	pop  rdx
	mov  uint8_p [ghost_particles + rax], dl

	mov    rax,                      rdi
	cmp    rax,                      uint64_p [ghost_start_x]
	cmovae rax,                      uint64_p [ghost_start_x]
	mov    uint64_p [ghost_start_x], rax

	mov    rax,                    rdi
	cmp    rax,                    uint64_p [ghost_end_x]
	cmovbe rax,                    uint64_p [ghost_end_x]
	mov    uint64_p [ghost_end_x], rax

	mov    rax,                      rsi
	cmp    rax,                      uint64_p [ghost_start_y]
	cmovae rax,                      uint64_p [ghost_start_y]
	mov    uint64_p [ghost_start_y], rax

	mov    rax,                    rsi
	cmp    rax,                    uint64_p [ghost_end_y]
	cmovbe rax,                    uint64_p [ghost_end_y]
	mov    uint64_p [ghost_end_y], rax

	.end:
	ret

; void place_ghosts(void);
func(static, place_ghosts)
	mov rdi, uint64_p [ghost_start_y]
	mov rax, SIM_PARTICLES_WIDTH
	mul rdi
	add rax, uint64_p [ghost_start_x]
	mov rdi, rax

	mov r8, uint64_p [ghost_start_x]
	mov r9, uint64_p [ghost_start_y]

	mov r10, uint64_p [ghost_end_x]
	mov r11, uint64_p [ghost_end_y]

	.loop_y:
		.loop_x:
			mov sil, uint8_p [ghost_particles + rdi]
			cmp sil, PARTICLE_TYPE_COUNT
			je  .skip_place
				call place_particle
			.skip_place:

			inc rdi
			inc r8
			cmp r8, r10
			jle .loop_x
		mov r8,  uint64_p [ghost_start_x]
		add rdi, SIM_PARTICLES_WIDTH
		sub rdi, r10
		dec rdi
		add rdi, r8
		inc r9
		cmp r9,  r11
		jle .loop_y

	ret

; void add_shape_diamond(uint64_t cx, uint64_t cy, uint8_t type);
func(static, add_shape_diamond)
	call add_ghost

	mov ecx, uint32_p [brush_size]
	cmp ecx, 0
	je  .end

	sub rdi, rcx
	sub rsi, rcx

	xor r8, r8
	sub r8, rcx

	mov r9, r8

	.loop_y:
		.loop_x:
			mov r10, r8
			cmp r10, 0
			jge .skip_neg_x
				neg r10
			.skip_neg_x:

			mov r11, r9
			cmp r11, 0
			jge .skip_neg_y
				neg r11
			.skip_neg_y:
			
			add r10, r11
			cmp r10, rcx
			jg  .skip_add_ghost
				call add_ghost
			.skip_add_ghost:

			inc rdi
			inc r8
			cmp r8, rcx
			jle .loop_x
		xor r8,  r8
		sub r8,  rcx
		sub rdi, rcx
		sub rdi, rcx
		dec rdi

		inc rsi
		inc r9
		cmp r9, rcx
		jle .loop_y

	.end:
	ret

; void add_shape_square(uint64_t cx, uint64_t cy, uint8_t type);
func(static, add_shape_square)
	call add_ghost

	mov ecx, uint32_p [brush_size]
	cmp ecx, 0
	je  .end

	sub rdi, rcx
	sub rsi, rcx

	xor r8, r8
	sub r8, rcx

	mov r9, r8

	.loop_y:
		.loop_x:
			call add_ghost
			inc  rdi
			inc  r8
			cmp  r8, rcx
			jle  .loop_x
		xor r8,  r8
		sub r8,  rcx
		sub rdi, rcx
		sub rdi, rcx
		dec rdi

		inc rsi
		inc r9
		cmp r9, rcx
		jle .loop_y

	.end:
	ret

; uint32_t get_brush_size(void);
func(global, get_brush_size)
	mov eax, uint32_p [brush_size]
	ret

; void set_brush_size(uint32_t size);
func(global, set_brush_size)
	mov uint32_p [brush_size], edi
	ret

; void set_brush_type(uint8_t type);
func(global, set_brush_type)
	mov uint8_p [brush_type], dil
	ret

; void set_brush_particle_type(uint8_t type);
func(global, set_brush_particle_type)
	mov uint8_p [brush_particle_type], dil
	ret

; Initializes the brush type as DIAMOND, brush particle as SAND and brush size as 3
; void init_brush(void);
func(global, init_brush)
	mov uint32_p [brush_size],         3
	mov uint8_p [brush_type],          BRUSH_DIAMOND
	mov uint8_p [brush_particle_type], PARTICLE_SAND

	sub    rsp,         8 + 32
	mov    rax,         qword [ghost_tex_img]
	movups xmm0,        [ghost_tex_img + 8]
	mov    qword [rsp], rax
	movups [rsp + 8],   xmm0
	lea    rdi,         [ghost_tex]
	call   LoadTextureFromImage
	add    rsp,         8 + 32
	ret

; Frees the states initialized by 'init_brush'
; void free_brush(void);
func(global, free_brush)
	sub rsp, 24

	mov    eax,         dword [ghost_tex]
	movups xmm0,        [ghost_tex + 4]
	mov    dword [rsp], eax
	movups [rsp + 4],   xmm0
	call   UnloadTexture

	add rsp, 24
	ret

; void update_brush(void);
func(global, update_brush)
	mov    uint64_p [ghost_start_x], SIM_PARTICLES_WIDTH
	mov    uint64_p [ghost_start_y], SIM_PARTICLES_HEIGHT
	mov    uint64_p [ghost_end_x],   0
	mov    uint64_p [ghost_end_y],   0
	lea    rdi,                      [ghost_particles]
	movups xmm0,                     [memset_pattern]
	mov    rcx,                      SIM_PARTICLES_COUNT / 16
	.res_loop:
		movups [rdi], xmm0
		add    rdi,   16
		loop   .res_loop
	
	sub  rsp,            8
	call GetMouseX
	mov  uint64_p [rsp], rax
	call GetMouseY
	pop  rdi
	mov  rsi,            rax
	sub  rsp,            8
	call get_screen_to_particle_pos
	mov  rdi,            rax
	mov  rsi,            rdx

	xor rdx, rdx
	mov dl,  uint8_p [brush_particle_type]

	xor  rax, rax
	mov  al,  uint8_p [brush_type]
	shl  rax, 3
	mov  rax, pointer_p [brush_call_table + rax]
	call rax

	mov  rdi, MOUSE_BUTTON_LEFT
	call IsMouseButtonDown
	cmp  al,  false
	je   .skip_place
		call place_ghosts
	.skip_place:

	add rsp, 8

	ret

; void render_brush(void);
func(global, render_brush)
	sub rsp, 24
	
	lea rdi, [ghost_tex_buffer]
	lea rsi, [ghost_particles]
	mov rcx, SIM_PARTICLES_COUNT

	lea r9, [particle_colors]
	.pixels_loop:
		xor rax, rax
		mov al,  uint8_p [rsi]
		shl rax, 2
		add rax, r9
		mov eax, color_p [rax]
		
		or  eax, A_MASK
		xor eax, A_MASK
		or  eax, 0x32 << A_LSHIFT

		mov color_p [rdi], eax

		add  rdi, sizeof(color_s)
		inc  rsi
		loop .pixels_loop

	mov    eax,         dword [ghost_tex]
	movups xmm0,        [ghost_tex + 4]
	mov    dword [rsp], eax
	movups [rsp + 4],   xmm0

	lea  rdi, [ghost_tex_buffer]
	call UpdateTexture

	call GetScreenWidth
	mov  uint32_p [rsp],                    eax
	call GetScreenHeight
	mov  uint32_p [rsp + sizeof(uint32_s)], eax

	xorps    xmm0, xmm0
	cvtpi2ps xmm1, qword [simulation_width]
	xorps    xmm2, xmm2
	cvtpi2ps xmm3, qword [rsp]
	xorps    xmm4, xmm4
	xorps    xmm5, xmm5

	mov rdi, COLOR_WHITE

	mov    eax,         dword [ghost_tex]
	movups xmm0,        [ghost_tex + 4]
	mov    dword [rsp], eax
	movups [rsp + 4],   xmm0

	call DrawTexturePro

	add rsp, 24
	ret

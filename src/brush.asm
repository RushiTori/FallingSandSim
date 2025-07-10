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
	dq add_shape_circle  ; BRUSH_CIRCLE
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

res(static,  uint64_t, selectX)
res(static,  uint64_t, selectY)

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

; bool add_shape_diamond(uint64_t cx, uint64_t cy);
func(static, add_shape_diamond)
	xor  rdx, rdx
	mov  dl,  uint8_p [brush_particle_type]
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
	mov rax, true
	ret

; bool add_shape_square(uint64_t cx, uint64_t cy);
func(static, add_shape_square)
	xor  rdx, rdx
	mov  dl,  uint8_p [brush_particle_type]
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
	mov rax, true
	ret

; Bresenham's Midpoint algorithm
; Source : https://www.youtube.com/watch?v=hpiILbMkF9w
; bool add_shape_circle(uint64_t cx, uint64_t cy);
func(static, add_shape_circle)
	xor  rdx, rdx
	mov  dl,  uint8_p [brush_particle_type]
	call add_ghost

	mov ecx, uint32_p [brush_size]
	cmp ecx, 0
	je  .end

	mov r8, rdi ; cx
	mov r9, rsi ; cy
	neg rcx     ; p = -r

	xor rdi, rdi ; x = 0
	mov rsi, rcx ; y = -r
	.circle_loop:
		cmp rcx, 0
		jle .skip_inc_y

		inc rsi      ; y++
		add rcx, rsi ; p += y*2
		add rcx, rsi
		.skip_inc_y:

		add rcx, rdi ; p += x*2
		add rcx, rdi

		inc rcx ; p++

		%macro circle_line_loop_base 0
			mov r10, rdi
			neg rdi
			add rdi, r8
			add r10, r8
			%%loop_:
				call add_ghost
				inc  rdi
				cmp  rdi, r10
				jle  %%loop_
			mov rdi, r10
			sub rdi, r8
		%endmacro

		%define circle_line_loop() circle_line_loop_base

		add rsi, r9 ; y + cy
		circle_line_loop()

		sub rsi, r9 ; y
		neg rsi     ; -y
		add rsi, r9 ; cy - y
		circle_line_loop()

		sub rsi, r9 ; -y
		neg rsi     ; y

		xchg rdi, rsi ; swap x and y
		neg  rdi      ; -y because y is negative but 'x' should be positive

		add rsi, r9 ; x + cy
		circle_line_loop()

		sub rsi, r9 ; x
		neg rsi     ; -x
		add rsi, r9 ; cy - x
		circle_line_loop()

		sub rsi, r9 ; -x
		neg rsi     ; x

		neg  rdi      ; y
		xchg rdi, rsi ; swap x and y again

		neg rsi      ; -y
		cmp rdi, rsi
		jge .end     ; if x >= -y : return

		neg rsi          ; y
		inc rdi          ; x++
		jmp .circle_loop

	.end:
	mov rax, true
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

func(static, update_brush_simple)
	sub rsp, 8 + 16

	call GetMousePosition
	movq vector2_p [rsp], xmm0

	call  GetMouseDelta
	movq  xmm1, vector2_p [rsp]
	subps xmm1, xmm0

	%macro simple_limit_base 2
		xor    rax, rax
		cmp    %1,  rax
		cmovle %1,  rax
		mov    rax, %2
		cmp    %1,  rax
		cmovge %1,  rax
	%endmacro

	%define simple_limit(reg, max) simple_limit_base reg, max

	cvtss2si          rdi, xmm1
	shufps xmm1, xmm1, 1
	cvtss2si          rsi, xmm1
	simple_limit(rdi, 1920)
	simple_limit(rsi, 1080)
	call              get_screen_to_particle_pos

	movq xmm1,                              vector2_p [rsp]
	mov  uint64_p [rsp],                    rax
	mov  uint64_p [rsp + sizeof(uint64_s)], rdx

	cvtss2si          rdi, xmm1
	shufps xmm1, xmm1, 1
	cvtss2si          rsi, xmm1
	simple_limit(rdi, 1920)
	simple_limit(rsi, 1080)
	call              get_screen_to_particle_pos

	mov rdi, uint64_p [rsp]
	mov rsi, uint64_p [rsp + sizeof(uint64_s)]
	mov rcx, rdx
	mov rdx, rax

	xor r8,  r8
	mov r8b, uint8_p [brush_type]
	shl r8,  3
	mov r8,  pointer_p [brush_call_table + r8]

	call run_line_algo

	mov  rdi, MOUSE_BUTTON_LEFT
	call IsMouseButtonDown
	cmp  al,  false
	je   .skip_place
		call place_ghosts
	.skip_place:

	add rsp, 8 + 16
	ret

; if (!IsMouseButtonDown(MOUSE_BUTTON_LEFT) && !IsMouseButtonReleased(MOUSE_BUTTON_LEFT)) {
;	selectXY = get_screen_to_particle_pos(GetMouseX(), GetMouseY())
; }
;
; add_ghost_rect(GetMouseX(), GetMouseY(), selectX, selectY, brush_type);
;
; if (IsMouseButtonReleased(MOUSE_BUTTON_LEFT)) {
;   place_ghosts();
; }
func(static, update_brush_selection)
	sub rsp, 24

	call GetMouseX
	mov  uint64_p [rsp], rax
	call GetMouseY

	mov rdi, uint64_p [rsp]
	mov rsi, rax

	xor   rax, rax
	cmp   rdi, rax
	cmovl rdi, rax
	cmp   rsi, rax
	cmovl rsi, rax

	mov   rax, SIM_PIXELS_WIDTH
	cmp   rdi, rax
	cmovg rdi, rax

	mov   rax, SIM_PIXELS_HEIGHT
	cmp   rsi, rax
	cmovg rsi, rax
	

	call get_screen_to_particle_pos
	mov  uint64_p [rsp],                    rax
	mov  uint64_p [rsp + sizeof(uint64_s)], rdx

	mov  rdi, MOUSE_BUTTON_LEFT
	call IsMouseButtonDown
	cmp  al,  false
	jne  .skip_set_select

	mov  rdi, MOUSE_BUTTON_LEFT
	call IsMouseButtonReleased
	cmp  al,  false
	jne  .skip_set_select

		mov rax,                uint64_p [rsp]
		mov uint64_p [selectX], rax

		mov rax,                uint64_p [rsp + sizeof(uint64_s)]
		mov uint64_p [selectY], rax

	.skip_set_select:

	mov dl, uint8_p [brush_particle_type]

	mov   rdi, uint64_p [rsp]
	mov   r8,  uint64_p [selectX]
	mov   r10, rdi
	cmp   rdi, r8
	cmovg rdi, r8
	cmp   r8,  r10
	cmovl r8,  r10

	mov   r9,  uint64_p [selectY]
	mov   rsi, uint64_p [rsp + sizeof(uint64_s)]
	mov   r10, rsi
	cmp   rsi, r9
	cmovg rsi, r9
	cmp   r9,  r10
	cmovl r9,  r10

	mov r10, rdi

	.loop_y:
		.loop_x:
			call add_ghost
			inc  rdi
			cmp  rdi, r8
			jle  .loop_x
		mov rdi, r10
		inc rsi
		cmp rsi, r9
		jle .loop_y
	
	mov  rdi, MOUSE_BUTTON_LEFT
	call IsMouseButtonReleased
	cmp  al,  false
	je   .end

	call place_ghosts

	.end:
	add rsp, 24
	ret

func(static, update_brush_bucket)
	push rbp
	mov  rbp, rsp
	sub  rsp, 16

	call GetMouseX
	mov  uint64_p [rsp], rax
	call GetMouseY

	mov rdi, uint64_p [rsp]
	mov rsi, rax

	xor   rax, rax
	cmp   rdi, rax
	cmovl rdi, rax
	cmp   rsi, rax
	cmovl rsi, rax

	mov   rax, SIM_PIXELS_WIDTH
	cmp   rdi, rax
	cmovg rdi, rax

	mov   rax, SIM_PIXELS_HEIGHT
	cmp   rsi, rax
	cmovg rsi, rax

	call get_screen_to_particle_pos
	mov  uint64_p [rsp],                    rax
	mov  uint64_p [rsp + sizeof(uint64_s)], rdx

	mov rdi, rax
	mov rsi, rdx

	mov ecx, uint32_p [simulation_height]

	mov r11, SIM_PARTICLES_WIDTH
	mov rax, r11
	mul rsi
	add rax, rdi
	mov r8,  rax

	mov  edx,  uint32_p [simulation_width]
	call get_particle_type
	mov  r8,   rdx
	mov  r9,   rcx
	mov  r10b, al

	mov  dl, uint8_p [brush_particle_type]
	call add_ghost
	mov  cl, dl

	%macro bucket_attempt 0
		mov rax, r11
		mul rsi
		add rax, rdi

		cmp cl, uint8_p [ghost_particles + rax]
		je  %%skip

		cmp r10b, uint8_p [particles + rax * sizeof(Particle) + Particle.type]
		jne %%skip
			mov  dl, cl
			call add_ghost
			push rsi
			push rdi
		%%skip:
	%endmacro

	.bucket_loop:
		pop rdi
		pop rsi

		dec rdi
		cmp rdi, 0
		jl  .skip_left
			bucket_attempt
		.skip_left:
		inc rdi

		inc rdi
		cmp rdi, r8
		jge .skip_right
			bucket_attempt
		.skip_right:
		dec rdi

		dec rsi
		cmp rsi, 0
		jl  .skip_up
			bucket_attempt
		.skip_up:
		inc rsi

		inc rsi
		cmp rsi, r9
		jge .skip_down
			bucket_attempt
		.skip_down:
		dec rsi

		cmp rsp, rbp
		jne .bucket_loop

	mov  rdi, MOUSE_BUTTON_LEFT
	call IsMouseButtonDown
	cmp  al,  false
	je   .skip_place
		call place_ghosts
	.skip_place:

	.end:
	mov rsp, rbp
	pop rbp
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
	
	sub      rsp, 8
	call     GetMouseWheelMove
	add      rsp, 8
	cvtss2si rax, xmm0
	add      al,  uint8_p [brush_size]

	cmp rax, 0
	jge .skip_clamp_0
		mov rax, 0
	.skip_clamp_0:
	
	cmp rax, 0xFF
	jle .skip_clamp_ff
		mov rax, 0xFF
	.skip_clamp_ff:
	mov uint8_p [brush_size], al

	cmp uint8_p [brush_type], BRUSH_SELECTION
	je  update_brush_selection
	jg  update_brush_bucket
	jmp update_brush_simple

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

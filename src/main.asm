bits         64
default      rel

%include "main.inc"

section      .text

func(static, gen_walls)
	lea rdi, [particles]
	mov rcx, SIM_PARTICLES_COUNT

	.pixels_loop:
		rdrand ax
		jnc    .pixels_loop
		cmp    ax, 0x1000
		ja     .skip_wall
			mov uint8_p [rdi + Particle.type], PARTICLE_SOLID_WALL
		.skip_wall:
		add  rdi, sizeof(Particle)
		loop .pixels_loop
	ret

func(static, add_sand)
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

func(static, add_water)
	lea rdi, [particles]
	mov ecx, uint32_p [simulation_width]
	.loop_:
		rdrand eax
		jnc    .loop_
		and    al, 1
		jz     .skip_water
			mov uint8_p [rdi + Particle.type], PARTICLE_WATER
		.skip_water:
		add  rdi, sizeof(Particle)
		loop .loop_
	ret

func(static, update_game)
	sub rsp, 8

	mov  rdi, MOUSE_BUTTON_LEFT
	call IsMouseButtonPressed
	cmp  al,  false
	je   .skip_add_sand
		call add_sand
	.skip_add_sand:

	mov  rdi, MOUSE_BUTTON_RIGHT
	call IsMouseButtonPressed
	cmp  al,  false
	je   .skip_add_water
		call add_water
	.skip_add_water:

	call update_simulation

	add rsp, 8
	ret

func(static, render_game)
	sub rsp, 8

	call BeginDrawing

	mov  rdi, COLOR_RAYWHITE
	call ClearBackground

	call render_simulation

	call EndDrawing

	add rsp, 8
	ret

func(global, _start)
	mov  rdi, uint64_p [rsp]           ; argc
	lea  rsi, [rsp + sizeof(uint64_s)] ; argv
	call setup_program

	call init_simulation
	call gen_walls

	.game_loop:
		call WindowShouldClose
		cmp  al, true
		je   .end_game_loop

		call update_game
		call render_game

		jmp .game_loop
	.end_game_loop:

	call free_simulation
	call CloseWindow

	mov rax, SYSCALL_EXIT
	mov rdi, EXIT_SUCCESS
	syscall

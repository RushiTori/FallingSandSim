bits    64
default rel

%include "main.inc"

section .text

%macro add_key_pressed_action_base 3
	mov  rdi, %1
	call IsKeyPressed
	cmp  al,  false
	je   %%skip_action
		mov  rdi, %3
		call %2
	%%skip_action:
%endmacro

%define add_key_pressed_action(key, func, arg1) add_key_pressed_action_base key, func, arg1

func(static, update_game)
	sub rsp, 8

	add_key_pressed_action(KEY_KP_1, set_brush_type, BRUSH_DIAMOND)
	add_key_pressed_action(KEY_KP_2, set_brush_type, BRUSH_SQUARE)
	add_key_pressed_action(KEY_KP_3, set_brush_type, BRUSH_CIRCLE)
	add_key_pressed_action(KEY_KP_7, set_brush_type, BRUSH_SELECTION)
	add_key_pressed_action(KEY_KP_8, set_brush_type, BRUSH_BUCKET)

	add_key_pressed_action(KEY_KP_0, set_brush_particle_type, PARTICLE_EMPTY)
	add_key_pressed_action(KEY_KP_4, set_brush_particle_type, PARTICLE_SAND)
	add_key_pressed_action(KEY_KP_5, set_brush_particle_type, PARTICLE_WATER)
	add_key_pressed_action(KEY_KP_6, set_brush_particle_type, PARTICLE_SOLID_WALL)

	call update_brush
	call update_simulation

	add rsp, 8
	ret

func(static, render_game)
	sub rsp, 8

	call BeginDrawing

	mov  rdi, COLOR_RAYWHITE
	call ClearBackground

	call render_simulation
	
	call render_brush

	xor  rdi, rdi
	xor  rsi, rsi
	call DrawFPS

	call EndDrawing

	add rsp, 8
	ret

func(global, _start)
	mov  rdi, uint64_p [rsp]           ; argc
	lea  rsi, [rsp + sizeof(uint64_s)] ; argv
	call setup_program

	call init_simulation
	call init_brush

	.game_loop:
		call WindowShouldClose
		cmp  al, true
		je   .end_game_loop

		call update_game
		call render_game

		jmp .game_loop
	.end_game_loop:

	call free_simulation
	call free_brush
	call CloseWindow

	mov rax, SYSCALL_EXIT
	mov rdi, EXIT_SUCCESS
	syscall

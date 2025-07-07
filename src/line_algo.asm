bits         64
default      rel

%include "line_algo.inc"

section      .text

; Runs a line rasterizing algorithm between points 'start' and 'end', calls 'call' on every points on the line
; 'call' should return 'true' if the line should continue or 'false' if it should stop early
; Returns the last position computed (either 'end' or the first position that makes 'call' return 'false')
; typedef bool (*LineAlgoCallback)(uint64_t x, uint64_t y);
; typedef struct Vec2u64 { uint64_t px, py; } Vec2u64;
; Vec2u64 run_line_algo(Vec2u64 start, Vec2u64 end, LineAlgoCallback call);
func(global, run_line_algo)
	sub  rsp, 8
	push r12    ; curr_x
	push r13    ; curr_y
	push r14    ; delta_x
	push r15    ; delta_y
	push rbx    ; end_x or end_y
	push rbp    ; dir
	; r11 : D
	; r8 : call

	mov rbp, 1

	mov r12, rdi
	mov r13, rsi

	mov r14, rdi
	sub r14, rdx
	jg  .skip_abs_x
		neg r14
	.skip_abs_x:

	mov r15, rsi
	sub r15, rcx
	jg  .skip_abs_y
		neg r15
	.skip_abs_y:

	cmp r14, r15
	jge line_algo_horizontal
	jmp line_algo_vertical

func(static, end_line_algo)
	mov rax, r12
	mov rdx, r13

	pop rbp
	pop rbx
	pop r15
	pop r14
	pop r13
	pop r12
	add rsp, 8
	ret

func(static, line_algo_horizontal)
	cmp rsi, rcx
	jle .skip_correct_dir
		neg rbp
	.skip_correct_dir:

	shl r15, 1
	mov r11, r15
	sub r11, r14
	shl r14, 1

	mov rbx, rdx

	cmp rdi, rdx
	jge line_right_to_left

func(static, line_left_to_right)
	.algo_loop:
		push r8
		push r11

		mov  rdi, r12
		mov  rsi, r13
		call r8

		pop r11
		pop r8

		cmp al, false
		je  end_line_algo

		inc r12
		cmp r12, rbx
		jle .skip_end
			dec r12
			jmp end_line_algo
		.skip_end:

		cmp r11, 0
		jl  .skip_update_y
			add r13, rbp
			sub r11, r14
		.skip_update_y:
		add r11, r15

		jmp .algo_loop

func(static, line_right_to_left)
	.algo_loop:
		push r8
		push r11

		mov  rdi, r12
		mov  rsi, r13
		call r8

		pop r11
		pop r8

		cmp al, false
		je  end_line_algo

		dec r12
		cmp r12, rbx
		jge .skip_end
			inc r12
			jmp end_line_algo
		.skip_end:

		cmp r11, 0
		jl  .skip_update_y
			add r13, rbp
			sub r11, r14
		.skip_update_y:
		add r11, r15

		jmp .algo_loop

func(static, line_algo_vertical)
	cmp rdi, rdx
	jle .skip_correct_dir
		neg rbp
	.skip_correct_dir:

	shl r14, 1
	mov r11, r14
	sub r11, r15
	shl r15, 1

	mov rbx, rcx

	cmp rsi, rcx
	jge line_down_to_up

func(static, line_up_to_down)
	.algo_loop:
		push r8
		push r11

		mov  rdi, r12
		mov  rsi, r13
		call r8

		pop r11
		pop r8

		cmp al, false
		je  end_line_algo

		inc r13
		cmp r13, rbx
		jle .skip_end
			dec r13
			jmp end_line_algo
		.skip_end:

		cmp r11, 0
		jl  .skip_update_x
			add r12, rbp
			sub r11, r15
		.skip_update_x:
		add r11, r14

		jmp .algo_loop

func(static, line_down_to_up)
	.algo_loop:
		push r8
		push r11

		mov  rdi, r12
		mov  rsi, r13
		call r8

		pop r11
		pop r8

		cmp al, false
		je  end_line_algo

		dec r13
		cmp r13, rbx
		jge .skip_end
			inc r13
			jmp end_line_algo
		.skip_end:

		cmp r11, 0
		jl  .skip_update_x
			add r12, rbp
			sub r11, r15
		.skip_update_x:
		add r11, r14

		jmp .algo_loop

%ifndef LINE_ALGO_INC
%define LINE_ALGO_INC

%include "std.inc"

; Runs a line rasterizing algorithm between points 'start' and 'end', calls 'call' on every points on the line
; 'call' should return 'true' if the line should continue or 'false' if it should stop early
; Returns the last position computed (either 'end' or the first position that makes 'call' return 'false')
; typedef bool (*LineAlgoCallback)(uint64_t x, uint64_t y);
; typedef struct Vec2u64 { uint64_t px, py; } Vec2u64;
; Vec2u64 run_line_algo(Vec2u64 start, Vec2u64 end, LineAlgoCallback call);
extern run_line_algo

%endif ; LINE_ALGO_INC

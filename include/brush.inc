%ifndef BRUSH_INC
%define BRUSH_INC

%include "simulation.inc"

; enum BrushType

	reset_enum_value(0)

	add_enum(BRUSH_DIAMOND)

	add_enum(BRUSH_SQUARE)

	add_enum(BRUSH_CIRCLE)

	add_enum(BRUSH_SELECTION)

	add_enum(BRUSH_BUCKET)

	add_enum(BRUSH_TYPE_COUNT)

; uint32_t get_brush_size(void);
extern get_brush_size

; void set_brush_size(uint32_t size);
extern set_brush_size

; void set_brush_type(uint8_t type);
extern set_brush_type

; void set_brush_particle_type(uint8_t type);
extern set_brush_particle_type

; Initializes the brush type as DIAMOND, brush particle as SAND and brush size as 3
; void init_brush(void);
extern init_brush

; Frees the states initialized by 'init_brush'
; void free_brush(void);
extern free_brush

; void update_brush(void);
extern update_brush

; void render_brush(void);
extern render_brush

%endif ; BRUSH_INC

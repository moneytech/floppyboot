bits 16
org 0x7C00

%define BG_COLOR 0x01 ; blue
%define PIPE_SPACING 0x0A ; distance between pipes

%define JUMP_KEY 0x48 ; up arrow


%define MAX_FALL 1 ; maximum rate of fall
%define JUMP_VEL -1 ; jump speed

%define START_ROW 12
%define START_COL 3

boot:
	; set video mode to 40x25 16-color
	MOV AH, 0x00
	MOV AL, 0x01
	INT 0x10

	; set blue background
	MOV AH, 0x0B
	MOV BH, 0x00
	MOV BL, BG_COLOR
	INT 0x10

	; disable the cursor
	MOV AH, 0x01
	MOV CH, 0x3F
	INT 0x10

	CALL draw_bird

loop:
	; main game loop
.input:
	; check input keystroke
	MOV AH, 0x01
	INT 0x16
	JZ loop.process_game

	; get the key
	MOV AH, 0x00
	INT 0x16

.chkpress:
	; check whether the 'jump' key was pressed
	CMP AH, JUMP_KEY
	JNE loop.process_game

	CALL jump_bird

.process_game:
	; update game state, draw graphics

	; process bird fall
	MOV CH, [birdy]
	MOV CL, [birdx]

	ADD CH, [birdvy]
	CALL move_bird

	; add gravity
	MOV AL, [birdvy]
	CMP AL, MAX_FALL
	JE loop.checkfalldeath
	ADD AL, 1
	MOV [birdvy], AL

.checkfalldeath:
	; check fall death
	MOV AL, [birdy]
	CMP AL, 24 ; the bottom row
	JL loop.delay

	; set the bird's vertical position to the bottom row
	MOV CH, 24
	CALL move_bird
	JMP end_game

.delay:
	; delay
	MOV CX, 0x01
	MOV DX, 0x86A0
	MOV AH, 0x86
	INT 0x15

	JMP loop

end_game:
	JMP end_game

draw_bird:
	; draw the bird at birdx and birdy
	; set AL to the character to draw for the bird
	; returns nothing
	PUSHA

	; set the cursor position
	MOV AH, 0x02
	MOV BH, 0x00
	MOV DH, [birdy]
	MOV DL, [birdx]
	INT 0x10

	; draw the bird
	MOV AH, 0x09
	MOV BH, 0x00
	MOV AL, '@'
	MOV BL, 0x0E
	MOV CX, 1
	INT 0x10

	POPA
	RET 

jump_bird:
	PUSH AX

	MOV AL, JUMP_VEL
	MOV [birdvy], AL

	POP AX
	RET

move_bird:
	; move the bird to a new location
	; CH = new row
	; CL = new col

	PUSHA

	; check whether the new row is less than 0
	; if it is, set the new row to 0
	CMP CH, 0
	JGE move_bird.checkloc
	MOV CH, 0

.checkloc:
	; do nothing if the new loc is the same as the old
	MOV DH, [birdy]
	MOV DL, [birdx]
	CMP CX, DX
	JE move_bird.return

	; draw bird at new location
	MOV AH, 0x02
	MOV BH, 0x00
	MOV DH, CH
	MOV DL, CL
	INT 0x10

	PUSH CX

	MOV AH, 0x0A
	MOV AL, '@'
	MOV CX, 1
	INT 0x10

	; draw blank at current location
	MOV AH, 0x02
	MOV DH, [birdy]
	MOV DL, [birdx]
	INT 0x10

	MOV AH, 0x0A
	MOV AL, ' '
	MOV CX, 1
	INT 0x10

	POP CX

	; set the bird's game location to the new location
	MOV [birdy], CH
	MOV [birdx], CL

.return:

	POPA
	RET

; game data
; bird position
birdx: db START_COL
birdy: db START_ROW

; bird vertical velocity
birdvy: db 0

times 510 - ($-$$) db 0 ; pad with zeroes to 510 bytes
dw 0xAA55 ; bootloader magic

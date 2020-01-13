bits 16
org 0x7C00

%define BG_COLOR 0x01 ; blue

%define JUMP_KEY 0x48 ; up arrow

%define MAX_FALL 1  ; maximum rate of fall
%define JUMP_VEL -1 ; jump speed

%define START_ROW 12
%define START_COL 3


; pipe properties
; each pipe is represented as 2 bytes in memory
; the first byte is the column position of the pipe
; the second byte is the row of the first space in the pipe's "hole"
%define NUM_PIPES 0x02     ; number of pipes to use
%define PIPE_SPACING 0x14  ; distance between pipes
%define HOLE_SIZE 0x05     ; size of hole in pipe


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

	; initialize pipes
	MOV BX, pipes
	MOV DX, 0

.pipeinitloop:
	; offset the pipe to the right of the screen
	MOV AL, DL
	MOV CL, PIPE_SPACING
	MUL CL
	ADD AL, 40

	MOV [BX], AL
	ADD BX, 1

	ADD BX, 1
	ADD DX, 1

	CMP DX, NUM_PIPES
	JL boot.pipeinitloop

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

	MOV AL, JUMP_VEL
	MOV [birdvy], AL

.process_game:
	; update game state, draw graphics

	; move pipes
	MOV BX, pipes
	MOV DX, 0

.movepipe_loop:
	MOV AH, [BX]
	MOV AL, [BX+1]
	MOV CL, AH
	SUB CL, 1
	CALL move_pipe

	; check for player-pipe collision
	CMP CL, [birdx]
	JNE loop.nocollide2
	CMP [birdy], AL
	JGE loop.nocollide1
	JMP end_game

.nocollide1:
	PUSH AX
	ADD AL, HOLE_SIZE
	CMP [birdy], AL
	POP AX
	JL loop.nocollide2
	JMP end_game

.nocollide2:
	ADD DX, 1
	ADD BX, 2
	CMP DX, NUM_PIPES
	JL loop.movepipe_loop

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
	CALL draw_score
	; delay
	MOV CX, 0x01
	MOV DX, 0x86A0
	MOV AH, 0x86
	INT 0x15

	JMP loop

end_game:
	JMP end_game


;
; game functions
;

move_curs:
	; move the cursor to the specified position
	; DH -> row
	; DL -> col
	MOV AH, 0x02
	MOV BH, 0x00
	INT 0x10

	RET

draw_character:
	; AL->character to draw
	; BL->attributes
	MOV AH, 0x09
	MOV BH, 0x00
	PUSH CX
	MOV CX, 1
	INT 0x10
	POP CX

	RET

draw_score:
	MOV DH, 0x00
	MOV DL, 0x00
	CALL move_curs

	MOV AH, 0x09
	MOV CX, 1

	MOV BL, [score]
	MOV BH, 0
	AND BL, 0x0F
	ADD BX, HEXDIGITS
	MOV AL, [BX]
	MOV BH, 0x00
	MOV BL, 0x0F
	INT 0x10

	RET

draw_bird:
	; draw the bird at birdx and birdy
	; returns nothing

	; set the cursor position
	MOV DH, [birdy]
	MOV DL, [birdx]
	CALL move_curs

	; draw the bird
	MOV AL, '@'
	MOV BL, 0x0E
	CALL draw_character

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

	; draw blank at current location
	CALL move_curs

	MOV AL, ' '
	MOV BL, 11
	CALL draw_character

	; set the bird's game location to the new location
	MOV [birdy], CH
	MOV [birdx], CL

	; draw the bird at the new location
	CALL draw_bird

.return:

	POPA
	RET

move_pipe:
	; move a pipe from one location to another
	; BX - address of the pipe
	; CL - new column
	PUSHA

	MOV AH, [BX]
	MOV AL, [BX+1]

	; check whether src and dest are the same pos
	CMP AH, CL
	JE move_pipe.return

	; check whether src is outside the visible area
	CMP AH, 0
	JL move_pipe.drawnew
	CMP AH, 40
	JGE move_pipe.drawnew

	; blank the column
	MOV DL, AH
	MOV DH, 0

	PUSH BX
.blankloop:
	CALL move_curs

	; draw blank
	MOV AL, ' '
	MOV BL, 11
	CALL draw_character

	ADD DH, 1

	CMP DH, 25
	JL move_pipe.blankloop

	POP BX

.drawnew:
	; check whether the dest pos is less than 0
	; if so, offset the pipe to the right to keep the cycle going
	MOV AL, [BX+1]
	CMP CL, 0
	JGE move_pipe.dodraw

	; offset the column
	MOV CL, 40

	; "randomize" the hole position
	PUSH BX
	PUSH CX
	MOV BX, [hidx]
	ADD BX, HLIST
	MOV AL, [BX]
	SUB BX, HLIST
	ADD BX, 1
	CMP BX, 7
	JGE move_pipe.zrand
	MOV [hidx], BX
	JMP move_pipe.randomdone
.zrand:
	MOV CX, 0
	MOV [hidx], CX

.randomdone:
	; increment score
	MOV CL, [score]
	ADD CL, 1
	MOV [score], CL
	CMP CL, 0x0F
	JGE end_game

	POP CX
	POP BX
.dodraw:
	MOV AH, CL
	CALL draw_pipe

	; save the new location
	MOV [BX], AH
	MOV [BX+1], AL 

.return:
	POPA
	RET	

draw_pipe:
	; draw a pipe
	; AH = column to draw the pipe in
	; AL = row where the pipe's hole starts

	PUSHA

	; don't draw outside the visible region
	cmp AH, 0
	JL draw_pipe.return
	CMP AH, 40
	JGE draw_pipe.return

	; start of the pipe
	MOV DH, 0x00
	MOV DL, AH

	; CL = start row of hole
	; CH = first row after hole
	MOV CL, AL
	MOV CH, AL
	ADD CH, HOLE_SIZE

.pipeloop:
	; move cursor to pipe pos
	CALL move_curs

	; check whether this is a hole
	CMP DH, CL
	JL draw_pipe.drawsolid
	CMP DH, CH
	JGE draw_pipe.drawsolid

	; if we make it here, we're in a hole
	JMP draw_pipe.increment
	
.drawsolid:
	MOV AL, ' '
	MOV BL, 0xAA
	CALL draw_character

.increment:
	ADD DH, 1
	CMP DH, 25
	JL draw_pipe.pipeloop

.return:
	POPA
	RET



; game data
score: db 0x00

; bird position
birdy: db START_ROW
birdx: db START_COL

; bird vertical velocity
birdvy: db 0

; pipes - 2 bytes for each pipe
pipes: times NUM_PIPES*2 db 0

; list of pipe positions
hidx: db 0

HLIST:
db 13, 9, 3, 8, 15, 7, 13

HEXDIGITS:
db '0', '1', '2', '3', '4', '5', '6', '7'
db '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'

times 510 - ($-$$) db 0 ; pad with zeroes to 510 bytes
dw 0xAA55 ; bootloader magic

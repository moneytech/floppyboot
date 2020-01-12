bits 16
org 0x7C00

%define BG_COLOR 0x01 ; blue
%define PIPE_SPACING 0x0A ; distance between pipes

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

	; move cursor to start position
	CALL draw_bird

halt:
	CLI
	HLT

draw_bird:
	; draw the bird at birdx and birdy
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
	MOV AL, 0x40 ; @
	MOV BH, 0x00
	MOV BL, 0x0E
	MOV CX, 1
	INT 0x10

	POPA
	RET

; game data
; bird position
birdx: db 6
birdy: db 6

times 510 - ($-$$) db 0 ; pad with zeroes to 510 bytes
dw 0xAA55 ; bootloader magic

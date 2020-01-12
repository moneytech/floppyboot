bits 16
org 0x7C00

boot:
	; set video mode to 40x25 16-color
	MOV AH, 0x00
	MOV AL, 0x01
	INT 0x10

	; set blue background
	MOV AH, 0x0B
	MOV BH, 0x00
	MOV BL, 0x01
	INT 0x10

	; disable the cursor
	MOV AH, 0x01
	MOV CH, 0x3F
	INT 0x10
halt:
	CLI
	HLT

times 510 - ($-$$) db 0 ; pad with zeroes to 510 bytes
dw 0xAA55 ; bootloader magic

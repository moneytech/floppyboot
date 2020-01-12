bits 16
org 0x7C00

boot:

halt:
	cli
	hlt

times 510 - ($-$$) db 0 ; pad with zeroes to 510 bytes
dw 0xAA55 ; bootloader magic

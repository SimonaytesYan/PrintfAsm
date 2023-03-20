;-------------------------------------------
;Get string length
;-------------------------------------------
;EXPECTS:	None
;
;ENTRY:		es - segment in which string located
;           di - offset start of string
;
;OUTPUT:	rdi - length of string
;
;DESTROYS:	rsi, al, ecx
;-------------------------------------------
StrLen:
	xor al, al		;ax = 0
	mov ecx, -1		;ecx = MAX_INT
	mov rsi, rdi

	repne scasb

	sub rdi, rsi
	dec rdi			;\0 do not count

	ret
;-------------------------------------------
;Put Number in Buffer in right order
;-------------------------------------------
;EXPECTS:	r8 - current index in Buffer
;
;ENTRY:     rcx - length of number
;           rsi - pointer to number
;
;OUTPUT:	r8 - current index in Buffer
;
;DESTROYS:	rdi, rsi, rcx
;-------------------------------------------
PutNumberInBuffer:
    lea rdi, [Buffer + r8]
    cld
    rep movsb

    mov r8, rdi
    sub r8, Buffer
    ret
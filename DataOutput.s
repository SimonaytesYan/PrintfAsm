%include "UtilityFunc.s"

;-------------------------------------------
;Put string in stdout
;-------------------------------------------
;EXPECTS:	None
;
;ENTRY:		rsi - string for output
;
;OUTPUT:	None
;
;DESTROYS:	rax, rdx, rbx, rdi, rsi, ecx
;-------------------------------------------
OutputStr:
	mov rdx, rsi	;save rsi

	mov rdi, rsi	;rdi = rsi
	mov si, ds 
	mov es, si		;es->data segment

	call StrLen
	mov rsi, rdx	;recover rsi

	mov rdx, rdi	;rdx = strlen

	mov rax, 0x01	;write64 (rdi, rsi, rdx) ... r10, r8, r9
	mov rdi, 1		;stdout

	syscall			;rsi -> string | rdx -> strlen				
	ret

;-------------------------------------------
;Put number in dec form in stdout
;-------------------------------------------
;EXPECTS:	None
;
;ENTRY:		rax - number for output
;
;OUTPUT:	None
;
;DESTROYS:	rax, rbx, rcx, rdx, r11, rsi
;-------------------------------------------
OutputNum10:
	mov r11, 10
    mov rbx, MAX_SYMBOL_IN_NUMBER
	
	mov rcx, rax
	shr rcx, 63
	jz .next		;if (rax < 0)
		xor rax, -1	;rax *= -1
		inc rax		;

		mov rcx, 1	;set flag of negative true
		jmp .next

	.skip_negative:	;else
		mov rcx, 0	;set flag of negative false

	.next:
		xor rdx, rdx		;rdx = 0
		div r11				;rax = rdxrax/10 
							;rdx = rax%10

		add dl, '0'			;make symbol from num

        mov Number[rbx], dl	;
        dec rbx

		cmp rax, 0	
		jne .next				;while(ax != 0)

	test rcx, rcx
	jz .output
		mov byte Number[rbx], '-'
		dec rbx

.output:
    lea rsi, Number[rbx + 1]        ;message to output
	mov rcx, MAX_SYMBOL_IN_NUMBER   ;
    sub rcx, rbx                    ;length

	call PutNumberInBuffer
	ret

;-------------------------------------------
;Put number in bin form in stdout
;-------------------------------------------
;EXPECTS:	None
;
;ENTRY:		rax - number for output
;
;OUTPUT:	None
;
;DESTROYS:	rax, rdx, rbx, rdi, rsi
;-------------------------------------------
OutputNum2:
    mov rbx, MAX_SYMBOL_IN_NUMBER

	.next:
        mov rdx, 1
        and rdx, rax       	;rdx = rax%2

		add dl, '0'			    ;make symbol from num

        mov Number[rbx], dl     ;
        dec rbx

        shr rax, 1
		cmp rax, 0	
		jne .next				;while(ax != 0)

    mov rax, 0x01			        ;write64 (rdi, rsi, rdx) ... r10, r8, r9
	mov rdi, 1				        ;stdout
    lea rsi, Number[rbx + 1]        ;message to output
	mov rdx, MAX_SYMBOL_IN_NUMBER   ;
    sub rdx, rbx                    ;length

	syscall		

	ret

;-------------------------------------------
;Put number in bin form in stdout
;-------------------------------------------
;EXPECTS:	None
;
;ENTRY:		rax - number for output
;
;OUTPUT:	None
;
;DESTROYS:	rax, rdx, rbx, rdi, rsi
;-------------------------------------------
OutputNum8:
    mov rbx, MAX_SYMBOL_IN_NUMBER

	.next:
        mov rdx, 7
        and rdx, rax       	;rdx = rax%2

		add dl, '0'			    ;make symbol from num

        mov Number[rbx], dl     ;
        dec rbx

        shr rax, 3
		cmp rax, 0	
		jne .next				;while(ax != 0)

    mov rax, 0x01			        ;write64 (rdi, rsi, rdx) ... r10, r8, r9
	mov rdi, 1				        ;stdout
    lea rsi, Number[rbx + 1]        ;message to output
	mov rdx, MAX_SYMBOL_IN_NUMBER   ;
    sub rdx, rbx                    ;length

	syscall		

	ret

;-------------------------------------------
;Put number in hex form in stdout
;-------------------------------------------
;EXPECTS:	None
;
;ENTRY:		rax - number for output
;
;OUTPUT:	None
;
;DESTROYS:	rax, rdx, rbx, rdi, rsi
;-------------------------------------------
OutputNum16:
    mov rbx, MAX_SYMBOL_IN_NUMBER

	.next:
		mov rsi, 0fh
		and rsi, rax					;get new number

		mov dl, int_to_char_hex[rsi] 	;make char from int

        mov Number[rbx], dl     	
        dec rbx

        shr rax, 4
		cmp rax, 0

		jne .next					;while(ax != 0)

    mov rax, 0x01			        ;write64 (rdi, rsi, rdx) ... r10, r8, r9
	mov rdi, 1				        ;stdout
    lea rsi, Number[rbx + 1]        ;message to output
	mov rdx, MAX_SYMBOL_IN_NUMBER   ;
    sub rdx, rbx                    ;length

	syscall		

	ret

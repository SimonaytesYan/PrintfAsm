section .text

global _start
_start:

	lea rsi, int_to_char_hex 

	push 10
	push string1
	push string
	call Printf

	mov rax, 0x3c			;
	xor rdi, rdi			;
	syscall					; exit64 (rdi)

;-------------------------------------------
;Parsing %* construction
;-------------------------------------------
;EXPECTS:	[rdi] - symbol after %
;			r8    - current index in Buffer
;			r10   - first not processed printf argument
;           label with name "Buffer" 
;
;ENTRY:		None			
;
;OUTPUT:	rdi - pointer to symbol after %* construction
;			r8  - current offset in Buffer
;			r10 - first not processed printf argument
;
;DESTROYS: rax, rdx, rbx, rsi, r11, r9, ecx
;-------------------------------------------
ParsePercent:
	cmp byte [rdi], '%'
	je  percent
	cmp byte [rdi], 'x'
	ja  default_case
	cmp byte [rdi], 'b'	
	jl  default_case

	mov r9, rdi			;save rdi

	mov rax, 0x01		;write
	mov rdi, 1			;stdout
	mov rsi, Buffer    	;message to output
	mov rdx, r8   		;length of the message
	syscall

	xor r8, r8			;Buffer was been output, so r8 = 0
	mov rdi, r9 		;recover rdi

	xor r11, r11
	mov r11B, [rdi]		;get symbol after %
	sub r11, 'b'
	mov r11, [jmp_table + r11*8]
	
	jmp r11

case_b:
	mov rax, [r10]		;get printf argument
	add r10, 8        	;next prinitf argument

	push rdi
	call OutputNum2
	pop rdi
	jmp end_switch
case_c:
	mov rax, [r10]
	mov byte Buffer[r8], byte al	;get printf argument
	add r10, 8        				;next prinitf  argument
	inc r8

	jmp end_switch
case_d:
	mov rax, [r10]		;get printf argument
	add r10, 8        	;next prinitf  argument

	push rdi
	call OutputNum10
	pop rdi
	jmp end_switch
case_o:
	mov rax, [r10]		;get printf argument
	add r10, 8        	;next prinitf  argument

	push rdi
	call OutputNum8
	pop rdi
	jmp end_switch
case_s:
	mov rsi, [r10]		;get printf argument
	add r10, 8        	;next prinitf  argument

	push rdi
	call OutputStr
	pop rdi
	jmp end_switch

case_x:
	mov rax, [r10]		;get printf argument
	add r10, 8        	;next prinitf  argument

	push rdi
	call OutputNum16
	pop rdi
	jmp end_switch

percent:
	mov byte Buffer[r8], '%'
	inc r8
	jmp end_switch

default_case:

end_switch:
	inc rdi
	ret

;-------------------------------------------
;Printf like in C
;-------------------------------------------
;EXPECTS:	None
;
;ENTRY(cdecl calling format):		
;			char* format
;			...
;			
;
;OUTPUT:	rdi - length of string
;
;DESTROYS:	rsi, al, ecx
;-------------------------------------------
Printf:
	push rbp
	mov rbp, rsp

	mov rdi, [rbp + 16]	;[rbp + 16] - the first argument - string format
	mov r10, rbp		;the second argument
	add r10, 24

	xor r8, r8 			;index in Buffer

	.next:
		cmp byte [rdi], 0		;
		je .func_end			;if ([rdi] == '\0') return

		cmp byte [rdi], '%'			;if ([rdi] == "%") ParsePercent([rdi++])
		jne .skip_percent_parse		;
			inc rdi					;
			call ParsePercent		;
			jmp .buffer_length_check;
									;
	.skip_percent_parse:			;else
		mov rax, [rdi]			;
		mov Buffer[r8], al		;Buffer[r8] = [rdi]
		inc r8
		inc rdi

	.buffer_length_check:
		cmp r8, BUFFER_LENGTH				;if (r8 > BUFFER_LENGTH) printf(buffer);
		jl .next
			mov r9, rdi			;save rdi

			mov rax, 0x01		;write
			mov rdi, 1			;stdout
			mov rsi, Buffer    	;message to output
			mov rdx, r8   		;length of the message
			syscall

			mov rdi, r9 		;recover rdi
		jmp .next

.func_end:

	mov rax, 0x01		;write
	mov rdi, 1			;stdout
	mov rsi, Buffer    	;message to output
	mov rdx, r8   		;length of the message
	syscall

	pop rbp
	ret

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
;DESTROYS:	rax, rdx, rbx, rdi, rsi
;-------------------------------------------
OutputNum10:
	mov rdi, 10
    mov rbx, MAX_SYMBOL_IN_NUMBER

	.next:
		xor rdx, rdx		;rdx = 0
		div rdi				;rax = rdxrax/10 
							;rdx = rax%10

		add dl, '0'			;make symbol from num

        mov Number[rbx], dl  ;
        dec rbx

		cmp rax, 0	
		jne .next				;while(ax != 0)

    mov rax, 0x01			        ;write64 (rdi, rsi, rdx) ... r10, r8, r9
	mov rdi, 1				        ;stdout
    lea rsi, Number[rbx + 1]            ;message to output

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

section .rodata
jmp_table:
	dq  case_b
	dq	case_c
	dq	case_d
	dq	default_case
	dq	default_case
	dq	default_case
	dq	default_case
	dq	default_case
	dq	default_case
	dq	default_case
	dq	default_case
	dq	default_case
	dq	default_case
	dq	case_o
	dq	default_case
	dq	default_case
	dq	default_case
	dq	case_s
	dq	default_case
	dq	default_case
	dq	default_case
	dq	default_case
	dq	case_x

section .rodata
	BUFFER_LENGTH		 equ 256
    MAX_SYMBOL_IN_NUMBER equ 100

	int_to_char_hex: 	db "0123456789ABCDEF", 0
	string:				db "Hello %s %c %%", 0
	string1:			db "Yan!", 0				

section .bss
	Buffer:			 db BUFFER_LENGTH*2 dup(?)
    Number: 		 db MAX_SYMBOL_IN_NUMBER dup(?)  
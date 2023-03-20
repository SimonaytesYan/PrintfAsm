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

%include "DataOutput.s"

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
	string:				db "Hello %s %c%%", 0
	string1:			db "Yan!", 0				

section .bss
	Buffer:			 db BUFFER_LENGTH*2 dup(?)
    Number: 		 db MAX_SYMBOL_IN_NUMBER dup(?)  
%include "lib.inc"


%define DICT_CELL_SIZE 8

section .text

global find_word

find_word:					;rdi - указатель на строку, rsi - начало словаря
	push r12				;сохраняем callee-saved регистры
	push r13
	mov r12, rdi			;указатель на строку
	mov r13, rsi			;начало словаря

.loop:
	test r13, r13			;если 0, то конец словаря
	je .bad

	add r13, DICT_CELL_SIZE ;добавляем сдвиг так как в словаре ячейки по 8 байт
	mov rdi, r12
	mov rsi, r13
	call string_equals
	cmp rax, 1
	je .good				;нашли строку в словаре
	sub r13, DICT_CELL_SIZE	
	mov r13, [r13]			;так как список связный, перешли к следующему элементу
	jmp .loop

.bad:
	pop r13
	pop r12
	xor rax, rax
	ret
.good:
	mov rax, r13
	pop r13
	pop r12
	ret

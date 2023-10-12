%include "lib.inc"
%include "dict.inc"
%include "words.inc"


%define BUFFER_SIZE 256
%define DICT_CELL_SIZE 8

section .bss
buffer: resb BUFFER_SIZE					;выделяем буфер для чтения

section .rodata
too_long_error: db "Error: the key length is more than 255 characters", 0
not_found_error: db "There is no such key in the dictionary", 0


section .text

global _start

_start:
	mov rdi, buffer
	mov rsi, BUFFER_SIZE
	call read_word							;читаем слово в буфер
	test rax, rax
	je .long_string							;если длина больше 255, то выдаем сообщение об ошибке
	

	mov rdi, buffer
	mov rsi, pointer
	call find_word							;ищем прочитанное слово в словаре
	test rax, rax
	je .not_found							;если не нашли, то сообщаем об этом
	


	mov rdi, rax							
	add rdi, DICT_CELL_SIZE					
	push rdi
	call string_length						;считаем длину ключа
	pop rdi
	add rdi, rax							;переходим к значению
	inc rdi									;пропускаем разграничивающий ноль
	
	call print_string
	call print_newline

	xor rdi, rdi
	call exit

.long_string:
	mov rdi, too_long_error	
	jmp .error
.not_found:
	mov rdi, not_found_error
.error:
	call print_error
	call print_newline
	mov rdi, 1
	call exit

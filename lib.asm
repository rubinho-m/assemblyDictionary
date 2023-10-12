SYS_EXIT equ 60
SYS_STDOUT equ 1
SYS_WRITE equ 1
SYS_READ equ 0
SYS_STDIN equ 0
SYS_STDERR equ 2

section .data
newline_char: db `\n`

section .text

global exit
global parse_int
global parse_uint
global print_char
global print_error
global print_int
global print_uint
global print_newline
global print_string
global read_char
global read_word
global string_copy
global string_equals
global string_length



; Принимает код возврата и завершает текущий процесс
exit: 
    mov rax, SYS_EXIT
    syscall

; Принимает указатель на нуль-терминированную строку, возвращает её длину
string_length:
    xor rax, rax				;обнуляем счетчик
.loop:
    cmp byte[rdi + rax], 0		;проверка на 0
	je .end
	inc rax						;увеличиваем счетчик
	jmp .loop
.end:
    ret

; Принимает указатель на нуль-терминированную строку, выводит её в stdout
print_string:
	push rdi				;сохраняем указатель на строку

	call string_length		;узнаем длину строки, результат лежит в rax
	
	pop rdi					;возвращаем указатель на строку

	mov rdx, rax			;загружаем длину строки
	mov rsi, rdi			;загружаем указатель на строку

	mov rax, SYS_WRITE
	mov rdi, SYS_STDOUT

	syscall
	
    ret

print_error:
	push rdi

	call string_length

	pop rdi

	mov rdx, rax
	mov rsi, rdi

	mov rax, SYS_WRITE
	mov rdi, SYS_STDERR

	syscall

	ret


; Переводит строку (выводит символ с кодом 0xA)
print_newline:
	mov rdi, `\n`


; Принимает код символа и выводит его в stdout
print_char:
	push di
	mov rax, SYS_WRITE
	mov rdi, SYS_STDOUT
	mov rsi, rsp
	mov rdx, 1
	syscall 
	add rsp, 2
	ret

; Выводит беззнаковое 8-байтовое число в десятичном формате 
; Совет: выделите место в стеке и храните там результаты деления
; Не забудьте перевести цифры в их ASCII коды.
print_uint:
	mov r9, rsp				;сохраняем состояние стека
    mov rax, rdi			;сохраняем число
	mov r8, 10				;сохраняем делитель для перевода сс
	dec rsp
	mov byte[rsp], 0		;0 на вершину стека для нуль-терминированного print_string
.loop:
	xor rdx, rdx			;очистка rdx
	div r8
	add rdx, '0'
	dec rsp
	mov byte[rsp], dl		;на вершину стека результат деления
	test rax, rax			;если rax == 0, то выходим из цикла
	je .endloop
	jmp .loop
	
.endloop:
	xor rdx, rdx			;очистка rdx на будущее
	mov rdi, rsp			
	push r9					;сохраняем начальное состояние стека
	call print_string
	pop rsp					;возвращаем изначальное состояние стека
	ret

; Выводит знаковое 8-байтовое число в десятичном формате 
print_int:
	test rdi, rdi			;выставляем флаги по аргументу
	js .negative
.finish:
	call print_uint
	ret
.negative:
	neg rdi
	push rdi				;сохраняем аргумент
	mov rdi, '-'
	call print_char			;печатаем минус
	pop rdi					;возвращаем аргумент
	jmp .finish

; Принимает два указателя на нуль-терминированные строки, возвращает 1 если они равны, 0 иначе
string_equals:
	push rsi				;запоминаем второй аргумент
	push rdi				;запоминаем первый аргумент

	push rsi

	call string_length
	mov r10, rax			;длина первой строки
	
	pop rsi					;возвращаем указатель на второй аргумент после функции
	
	push r10				;сохраняем длину первой строки
	mov rdi, rsi
	call string_length
	mov r11, rax			;длина второй строки
	
	pop r10					;возвращаем длину первой строки
	pop rdi					;возвращаем указатель на первую строку
	pop rsi					;возвращаем указатель на вторую строку

	xor rax, rax			;обнуляем счетчик для прохода по строкам
.stringloop:
	mov cl, byte[rsi + rax]
	cmp byte[rdi + rax], cl	;сравниваем байты двух строк
	jne .false				;если байты не равны, то сразу выходим из цикла
	cmp byte[rdi + rax], 0	;проверяем, не кончилась ли строка
	je .endstringloop
	inc rax
	jmp .stringloop

.endstringloop:
	mov rax, 1				;возвращаем единицу
	ret

.false:
	xor rax, rax			;возвращаем ноль
    ret

; Читает один символ из stdin и возвращает его. Возвращает 0 если достигнут конец потока
read_char:				
	dec rsp					;выделяем место на стеке

	mov	rax, SYS_READ		
	mov rdi, SYS_STDIN
	mov rsi, rsp
	mov rdx, 1				;ввод символа
	
	syscall
	
	test rax, rax			;проверяем, достигнут ли конец потока
	je .finish

	xor rax, rax			;если нет, то загружаем нужный символ
	mov al, [rsp]
	
.finish:
	inc rsp 				
	
    ret 

; Принимает: адрес начала буфера, размер буфера
; Читает в буфер слово из stdin, пропуская пробельные символы в начале, .
; Пробельные символы это пробел 0x20, табуляция 0x9 и перевод строки 0xA.
; Останавливается и возвращает 0 если слово слишком большое для буфера
; При успехе возвращает адрес буфера в rax, длину слова в rdx.
; При неудаче возвращает 0 в rax
; Эта функция должна дописывать к слову нуль-терминатор

read_word:
	push r12				;сохраняем callee-saved регистры
	push r13
	push r14

	xor r14, r14			;обнуляем счетчик длины слова
	mov r12, rdi			;сохраняем адрес начала буфера
	mov r13, rsi			;сохраняем размер буфера


.loop:
	cmp r14, r13			;если не помещаемся в буфер, то выходим
	jge .false

	call read_char
	test rax, rax
	je .endloop				;если конец потока, то больше не читаем

	cmp rax, 0x20			;пропускаем все пробельные символы
	je .continue
	cmp rax, 0x9
	je .continue
	cmp rax, 0xA
	je .continue		
 	
	mov byte[r12+r14], al	;записываем считанный символ в буфер
	inc r14					;увеличиваем счетчик длины слова
	jmp .loop
.continue:
	test r14, r14			;если пробел в начале, то продолжаем считывать
	je .loop
	jmp .endloop			;иначе заканчиваем
.false:
	xor rax, rax			;формируем код в случае неудачи
	jmp .end
.endloop:
	mov byte[r12+r14], 0	;добавляем нуль-терминатор
	mov rax, r12
	mov rdx, r14
.end:
	pop r14					;возвращаем callee-saved регистры
	pop r13
	pop r12
	ret
 

; Принимает указатель на строку, пытается
; прочитать из её начала беззнаковое число.
; Возвращает в rax: число, rdx : его длину в символах
; rdx = 0 если число прочитать не удалось
parse_uint:
    xor rax, rax			;регистр для числа
	xor rcx, rcx			;обнуляем счетчик
	mov r8, 10
.loop:
	cmp byte[rdi + rcx], '0';если < 0 в ascii, то не цифра
	jl .false
	cmp byte[rdi + rcx], '9';если > 9 в ascii, то не цифра
	jg .false

	mul r8					;добавляем цифру в число

	add rcx, rdi
	add al, byte[rcx]
	sub al, '0'				;перевод из ascii
	sub rcx, rdi
	

	inc rcx			
	jmp .loop
.false:
	mov rdx, rcx			;вовзращаем длину числа
    ret




; Принимает указатель на строку, пытается
; прочитать из её начала знаковое число.
; Если есть знак, пробелы между ним и числом не разрешены.
; Возвращает в rax: число, rdx : его длину в символах (включая знак, если он был) 
; rdx = 0 если число прочитать не удалось
parse_int:
    xor rax, rax			;регистр для числа
	xor rcx, rcx			;сдвиг для знака
	
	cmp byte[rdi], '-'		;проверяем первый символ на знак
	je .minus
	
	cmp byte[rdi], '+'		;если первый символ это не знак, то просто парсим число 
	jne .parse
	inc rcx					;если первый символ это +, то сдвигаем указатель на один
	add rdi, rcx
.parse:
	call parse_uint			;если число положительное, вызываем parse_uint
	jmp .finish
.minus:
	inc rcx					
	add rdi, rcx			;если число отрицательное, сдвигаем указатель на один
	call parse_uint			
	test rdx, rdx			;если числа нет, то заканчиваем
	je .finish
	inc rdx					;иначе добавляем в длину числа знак
	neg rax					;и меняем знак числа
.finish:
	ret


; Принимает указатель на строку, указатель на буфер и длину буфера
; Копирует строку в буфер
; Возвращает длину строки если она умещается в буфер, иначе 0
string_copy:
	xor rax, rax			;длина строки
.loop:
	cmp rax, rdx			
	je .false				;если указатель на символ == длине буфера, то не помещается

	mov r8b, byte[rdi+rax]	
	mov byte[rsi+rax], r8b	;копируем в буфер

	inc rax

	test r8b, r8b
	je .endloop

	jmp .loop

.endloop:
	ret
.false:
	xor rax, rax
	ret














%define pointer 0

%macro colon 2			;ключ и название метки
%2: dq pointer			;создаем метку с ключом и указателем на следующий с конца элемент
db %1, 0				
%define pointer %2		;меняем указатель
%endmacro

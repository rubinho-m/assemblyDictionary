ASM_FLAGS=-f elf64

.PHONY: clean
clean:
	rm -f *.o

lib.o: lib.asm
	nasm $(ASM_FLAGS) lib.asm -o $@

dict.o: dict.asm lib.inc colon.inc
	nasm $(ASM_FLAGS) dict.asm -o $@

main.o: main.asm lib.inc dict.inc words.inc
	nasm $(ASM_FLAGS) main.asm -o $@

program: main.o lib.o dict.o
	ld -o $@ $^

test: test.py
	python3 $<

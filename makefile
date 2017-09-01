all: ass2
ass2:	 
	nasm -f elf calc.s -o calc.o
	gcc -m32 -Wall -g calc.o -o calc.bin
	
.PHONY: clean

clean:
	rm -f calc.bin *.o

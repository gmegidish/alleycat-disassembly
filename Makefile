all: cat_rebuilt.exe
	cmp cat.exe cat_rebuilt.exe && echo "IDENTICAL!" || echo "MISMATCH"

cat.asm: ghidra2nasm.py cat.exe cat.txt
	# WILL OVERWRITE EVERYTHING
	# python3 ghidra2nasm.py

SRC_FILES := $(wildcard src/*.asm)

cat_rebuilt.exe: cat.asm $(SRC_FILES)
	nasm -f bin -o cat_rebuilt.exe cat.asm

clean:
	rm -f cat_rebuilt.exe

.PHONY: all clean

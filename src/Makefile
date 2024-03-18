
all: data

MOVE2024.bin: MOVE2024.asm
	pasmo $^ $@

data: MOVE2024.bin
	./generate_data_lines.py $^


clean:
	rm MOVE2024.bin

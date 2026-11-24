PYTHON ?= python3
IVERILOG ?= iverilog
VVP ?= vvp
RTL := project/cpu.v project/alu.v project/ram.v project/rom.v project/regfile.v
.PHONY: test program clean
test: build/alu_tb build/cpu_tb
	$(VVP) build/alu_tb
	$(VVP) build/cpu_tb
build/alu_tb: project/alu.v project/alu_tb.v
	mkdir -p build
	$(IVERILOG) -g2012 -s ALU_tb -o $@ $^
build/cpu_tb: $(RTL) project/cpu_tb.v
	mkdir -p build
	$(IVERILOG) -g2012 -s MaulCPU_tb -o $@ $^
program:
	$(PYTHON) assembler/maulisa_asm.py assembler/blink.asm -o project/program.bin -x
clean:
	rm -rf build
	rm -f project/program.bin project/program.hex

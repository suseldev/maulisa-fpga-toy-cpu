# MaulISA FPGA Toy CPU

MaulISA is a custom instruction set and a 16-bit, multicycle soft-core CPU written in Verilog for educational FPGA development. The target platform is the Intel MAX 10 DE10-Lite board.

## Architecture

- Sixteen 16-bit general-purpose registers (R0–R15).
- 16-bit word addresses and 32-bit fixed-width instructions.
- Separate synchronous instruction ROM and data RAM.
- Arithmetic, logic, shifts, comparisons, conditional branches and direct/indirect memory access.
- Memory-mapped GPIO and five active-low seven-segment displays.
- Two-pass Python assembler with labels and binary/hex output.

The finite-state controller uses additional cycles for synchronous memory and division. The supplied SDC targets a 50 MHz clock and includes multicycle constraints for the divider. Timing and resource utilization must be checked again after synthesis on the target device.

## Quick start

Requirements: Python 3, Icarus Verilog and GNU Make for simulation; Quartus for FPGA synthesis.

```sh
make test
make program
```

The latter assembles the LED blink example into `project/program.hex`. To assemble a different program:

```sh
python3 assembler/maulisa_asm.py assembler/fib.asm -o project/program.bin -x
```

For hardware deployment, create a DE10-Lite Quartus project using `DE10_LITE_Golden_Top` as the top-level entity, add the RTL and `project/constraints.sdc`, include the generated ROM image, and apply the board-specific pin assignments. The repository does not include a complete Quartus project or pin assignment file.

## Instruction encoding

| Bits | Field |
| --- | --- |
| 31:24 | Opcode |
| 23:20 | Destination register |
| 19:16 | Source register |
| 15:0 | Immediate or address |

| Opcode | Instructions |
| --- | --- |
| 00 | NOP |
| 01–08 | ADD, ADDI, SUB, SUBI, MUL, MULI, DIV, DIVI |
| 10–16 | AND, ANDI, OR, ORI, XOR, XORI, NOT |
| 20–21 | SHL, SHR |
| 30–31 | CMP, CMPI |
| 40–41 | MOVI, MOV |
| 50–53 | LOAD, STORE, LOADR, STORER |
| 60–64 | JMP, JZ, JNZ, JC, JNC |
| FF | HALT |

Opcodes are hexadecimal. Arithmetic wraps to 16 bits; subtraction and comparison set carry on borrow. Comparisons update flags without writing a register. HALT holds the program counter.

## Memory-mapped I/O

| Address | Peripheral |
| --- | --- |
| 0xFF0F | GPIO input |
| 0xFFF0–0xFFF4 | HEX0–HEX4 |
| 0xFFFF | GPIO output / LEDs |

Example:

```asm
    MOVI R0, 0xAA
    STORE R0, 0xFFFF
    HALT
```

## Repository layout

- `project/`: CPU, ALU, register file, memories, board wrapper, timing constraints and self-checking RTL testbenches.
- `assembler/`: assembler and demonstration programs.
- `Makefile`: reproducible simulation and ROM generation.

The tests check ALU results and flags, arithmetic and division through the CPU, conditional branching, direct and indirect RAM access, GPIO loopback and display writes. Failures terminate simulation with a nonzero exit status.

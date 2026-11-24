#!/usr/bin/env python3
"""Quick and dirty assembler for MaulISA FPGA CPU"""
import argparse
import re
from pathlib import Path

GROUPS = {
    "NONE": {0x00: "NOP", 0xFF: "HALT"},
    "RR": {0x01: "ADD", 0x03: "SUB", 0x05: "MUL", 0x07: "DIV",
           0x10: "AND", 0x12: "OR", 0x14: "XOR", 0x30: "CMP",
           0x41: "MOV", 0x52: "LOADR", 0x53: "STORER"},
    "RI": {0x02: "ADDI", 0x04: "SUBI", 0x06: "MULI", 0x08: "DIVI",
           0x11: "ANDI", 0x13: "ORI", 0x15: "XORI", 0x31: "CMPI",
           0x40: "MOVI", 0x50: "LOAD", 0x51: "STORE"},
    "R": {0x16: "NOT", 0x20: "SHL", 0x21: "SHR"},
    "I": {0x60: "JMP", 0x61: "JZ", 0x62: "JNZ", 0x63: "JC", 0x64: "JNC"},
}
ISA = {name: (opcode, fmt) for fmt, group in GROUPS.items()
       for opcode, name in group.items()}


def register(token):
    if not re.fullmatch(r"R(?:[0-9]|1[0-5])", token):
        raise ValueError(f"Invalid register: {token}")
    return int(token[1:])


def immediate(token, labels):
    if token in labels:
        return labels[token]
    value = int(token, 10 if re.fullmatch(r"[+-]?[0-9]+", token) else 0)
    if not -32768 <= value <= 65535:
        raise ValueError(f"Immediate out of range: {token}")
    return value & 0xFFFF


def assemble(source):
    labels, instructions = {}, []
    for number, raw in enumerate(source.splitlines(), 1):
        line = raw.split(";", 1)[0].strip().upper()
        if not line:
            continue
        if ":" in line:
            label, line = (part.strip() for part in line.split(":", 1))
            if not re.fullmatch(r"[A-Z_][A-Z0-9_]*", label) or label in ISA or label in labels:
                raise ValueError(f"Line {number}: invalid or duplicate label {label}")
            labels[label] = len(instructions)
        if line:
            instructions.append((number, line.replace(",", " ").split()))
    if len(instructions) > 65536:
        raise ValueError("Program exceeds 64K instruction words")
    words = []
    for number, tokens in instructions:
        try:
            mnemonic, *args = tokens
            if mnemonic not in ISA:
                raise ValueError(f"Unknown instruction: {mnemonic}")
            opcode, fmt = ISA[mnemonic]
            expected = 0 if fmt == "NONE" else len(fmt)
            if len(args) != expected:
                raise ValueError(f"{mnemonic} expects {expected} operands")
            rd = register(args[0]) if fmt.startswith("R") else 0
            rs = register(args[1]) if fmt == "RR" else 0
            imm = immediate(args[-1], labels) if fmt.endswith("I") else 0
            words.append((opcode << 24) | (rd << 20) | (rs << 16) | imm)
        except ValueError as exc:
            raise ValueError(f"Line {number}: {exc}") from exc
    return words


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("-o", "--output", type=Path, default=Path("out.bin"))
    parser.add_argument("-x", "--generate-hex", action="store_true")
    args = parser.parse_args()
    try:
        words = assemble(args.input.read_text(encoding="utf-8"))
        hex_path = args.output.with_suffix(".hex")
        if args.input.resolve() == args.output.resolve() or (
            args.generate_hex and hex_path.resolve() in
            {args.input.resolve(), args.output.resolve()}
        ):
            raise ValueError("Input and output paths must be distinct")
        args.output.write_bytes(b"".join(word.to_bytes(4, "big") for word in words))
        if args.generate_hex:
            hex_path.write_text("".join(f"{word:08X}\n" for word in words), encoding="ascii")
    except (OSError, ValueError) as exc:
        parser.exit(1, f"Error: {exc}\n")
    print(f"Assembled {len(words)} instructions into {args.output}")


if __name__ == "__main__":
    main()

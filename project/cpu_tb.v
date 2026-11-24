`timescale 1ns/1ps
module MaulCPU_tb;
    reg clk = 0;
    reg reset = 1;
    wire [7:0] gpio_out, hex0, hex1, hex2, hex3, hex4;
    always #10 clk = ~clk;

    MaulCPU #(.PROGRAM_FILE("")) dut (
        .clk(clk), .reset(reset), .gpio_in(8'h5A), .gpio_out(gpio_out),
        .hex0_out(hex0), .hex1_out(hex1), .hex2_out(hex2),
        .hex3_out(hex3), .hex4_out(hex4)
    );

    initial begin
        // ALU, jumps and RAM
        dut.rom_inst.mem[0] = 32'h40000007; // MOVI R0, 7
        dut.rom_inst.mem[1] = 32'h02000005; // ADDI R0, 5
        dut.rom_inst.mem[2] = 32'h08000003; // DIVI R0, 3
        dut.rom_inst.mem[3] = 32'h31000004; // CMPI R0, 4
        dut.rom_inst.mem[4] = 32'h6200001A; // JNZ failure
        dut.rom_inst.mem[5] = 32'h51000010; // STORE R0, 0x10
        dut.rom_inst.mem[6] = 32'h40100010; // MOVI R1, 0x10
        dut.rom_inst.mem[7] = 32'h52210000; // LOADR R2, R1
        dut.rom_inst.mem[8] = 32'h02200001; // ADDI R2, 1
        dut.rom_inst.mem[9] = 32'h53210000; // STORER R2, R1
        dut.rom_inst.mem[10] = 32'h50300010; // LOAD R3, 0x10
        dut.rom_inst.mem[11] = 32'h31300005; // CMPI R3, 5
        dut.rom_inst.mem[12] = 32'h6200001A; // JNZ failure
        dut.rom_inst.mem[13] = 32'h5040FF0F; // LOAD R4, GPIO input
        dut.rom_inst.mem[14] = 32'h5140FFFF; // STORE R4, GPIO output
        // Write a different value to each HEX display.
        dut.rom_inst.mem[15] = 32'h405000A0;
        dut.rom_inst.mem[16] = 32'h5150FFF0;
        dut.rom_inst.mem[17] = 32'h02500001;
        dut.rom_inst.mem[18] = 32'h5150FFF1;
        dut.rom_inst.mem[19] = 32'h02500001;
        dut.rom_inst.mem[20] = 32'h5150FFF2;
        dut.rom_inst.mem[21] = 32'h02500001;
        dut.rom_inst.mem[22] = 32'h5150FFF3;
        dut.rom_inst.mem[23] = 32'h02500001;
        dut.rom_inst.mem[24] = 32'h5150FFF4;
        dut.rom_inst.mem[25] = 32'hFF000000; // HALT
        dut.rom_inst.mem[26] = 32'hFF000000; // failure
        repeat (3) @(negedge clk);
        reset = 0;
        repeat (300) @(negedge clk);
        if (dut.pc !== 16'd25 || dut.regfile_inst.regs[0] !== 16'd4 ||
            dut.regfile_inst.regs[3] !== 16'd5 || gpio_out !== 8'h5A ||
            {hex4, hex3, hex2, hex1, hex0} !== 40'hA4A3A2A1A0)
            $fatal(1, "CPU integration test failed: PC=%h GPIO=%h", dut.pc, gpio_out);
        $display("PASS: CPU arithmetic, branches, RAM and MMIO");
        $finish;
    end
endmodule

`timescale 1ns/1ps
module ALU_tb;
    reg [3:0] opcode;
    reg [15:0] a, b;
    wire [15:0] result;
    wire zero, carry, valid;
    ALU dut(opcode, a, b, result, zero, carry, valid);

    task check;
        input [3:0] op;
        input [15:0] x, y, expected;
        input expected_carry, expected_valid;
        begin
            opcode = op; a = x; b = y;
            #1;
            if (result !== expected || carry !== expected_carry ||
                valid !== expected_valid || zero !== (expected == 0))
                $fatal(1, "ALU op=%h a=%h b=%h result=%h expected=%h", op, x, y, result, expected);
        end
    endtask

    initial begin
        check(0, 123, 999, 123, 0, 1);
        check(1, 100, 50, 150, 0, 1);
        check(1, 16'hFFFF, 1, 0, 1, 1);
        check(2, 10, 20, 16'hFFF6, 1, 1);
        check(2, 25, 25, 0, 0, 1);
        check(3, 10, 20, 200, 0, 1);
        check(3, 500, 500, 16'hD090, 1, 1);
        check(4, 100, 5, 20, 0, 1);
        check(4, 100, 0, 16'hFFFF, 0, 0);
        check(5, 16'hAAAA, 16'hF0F0, 16'hA0A0, 0, 1);
        check(6, 16'hAAAA, 16'hF0F0, 16'hFAFA, 0, 1);
        check(7, 16'hAAAA, 16'hF0F0, 16'h5A5A, 0, 1);
        check(8, 16'hAAAA, 0, 16'h5555, 0, 1);
        check(9, 16'h8000, 0, 0, 1, 1);
        check(10, 1, 0, 0, 1, 1);
        check(11, 7, 7, 0, 0, 1);
        check(15, 0, 0, 0, 0, 0);
        $display("PASS: ALU");
        $finish;
    end
endmodule

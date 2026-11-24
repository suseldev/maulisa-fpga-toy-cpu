module ALU(
    input wire [3:0] opcode,
    input wire [15:0] a,
    input wire [15:0] b,
    output reg [15:0] result,
    output reg zero,
    output reg carry,
    output reg valid
);

localparam ALU_NOP  = 4'b0000;
localparam ALU_ADD  = 4'b0001;
localparam ALU_SUB  = 4'b0010;
localparam ALU_MUL  = 4'b0011;

// Division needs extra cycles in the CPU.
localparam ALU_DIV  = 4'b0100;
localparam ALU_AND  = 4'b0101;
localparam ALU_OR   = 4'b0110;
localparam ALU_XOR  = 4'b0111;
localparam ALU_NOT  = 4'b1000;
localparam ALU_SHL  = 4'b1001;
localparam ALU_SHR  = 4'b1010;
localparam ALU_CMP  = 4'b1011;

reg[16:0] temp;
reg[31:0] mul_temp;

always @(*) begin
    result = 16'b0;
    zero = 1'b0;
    carry = 1'b0;
    valid = 1'b1;
    temp = 17'b0;
    mul_temp = 32'b0;
    case(opcode)
        ALU_NOP: begin

            result = a;
        end

        ALU_ADD: begin
            temp = a + b;
            result = temp[15:0];
            carry = temp[16];
        end

        ALU_SUB: begin
            temp = a - b;
            result = temp[15:0];
            carry = temp[16];
        end

        ALU_MUL: begin
            mul_temp = a * b;
            result = mul_temp[15:0];
            carry = (mul_temp > 16'hFFFF);
        end

        ALU_DIV: begin
            if (b == 0) begin

                // Divide by zero.
                result = 16'hFFFF;
                carry  = 1'b0;
                valid  = 1'b0;
            end
            else begin
                result = a/b;
            end
        end

        ALU_AND: result = a & b;

        ALU_OR: result = a | b;

        ALU_XOR: result = a ^ b;

        ALU_NOT: result = ~a;

        ALU_SHL: begin
            carry = a[15];
            result = a << 1;
        end

        ALU_SHR: begin
            carry = a[0];
            result = a >> 1;
        end

        ALU_CMP: begin
            temp = a - b;
            result = temp;
            zero = (temp[15:0] == 0);
            carry = temp[16];
        end

        default: begin
                valid = 1'b0;
            end

        endcase

        if(result == 16'b0) zero=1'b1;
    end
endmodule

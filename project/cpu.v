module MaulCPU #(
    parameter PROGRAM_FILE = "program.hex"
)(
    input wire clk,
    input wire reset,
    output wire [7:0] hex4_out, hex3_out, hex2_out, hex1_out, hex0_out,
    output wire [7:0] gpio_out,
    input wire [7:0] gpio_in
);

    localparam ALU_NOP  = 4'b0000;
    localparam ALU_ADD  = 4'b0001;
    localparam ALU_SUB  = 4'b0010;
    localparam ALU_MUL  = 4'b0011;
    localparam ALU_DIV  = 4'b0100;
    localparam ALU_AND  = 4'b0101;
    localparam ALU_OR   = 4'b0110;
    localparam ALU_XOR  = 4'b0111;
    localparam ALU_NOT  = 4'b1000;
    localparam ALU_SHL  = 4'b1001;
    localparam ALU_SHR  = 4'b1010;
    localparam ALU_CMP  = 4'b1011;

    // Wait for synchronous ROM.
    localparam FETCH_WAIT = 4'b0000;
    localparam FETCH_INSTRUCTION = 4'b0001;

    localparam DECODE = 4'b0010;

    localparam SETUP_ALU = 4'b0011;

    localparam SETUP_RAM =4'b0100;
    localparam WAIT_RAM_ALU = 4'b0101;

     // Give the divider a few extra cycles.
    localparam WAIT_ALU_DIV = 4'b0110;
    localparam EXECUTE = 4'b0111;

    (* preserve, noprune *) reg [3:0] state;

    (* preserve, noprune *) reg [15:0] pc;
    (* preserve, noprune *) reg [31:0] ir;

    (* preserve, noprune *) reg [7:0] opcode;

    (* preserve, noprune *) reg [3:0] rd;
    (* preserve, noprune *) reg [3:0] rs;

    (* preserve, noprune *) reg [15:0] imm;
     reg use_imm;

    (* preserve, noprune *) reg write_enable;

    (* preserve, noprune *) reg [3:0] write_addr;

    reg [15:0] write_data;

    wire [15:0] rd_data;
    wire [15:0] rs_data;

    reg [3:0] alu_opcode;
     wire [15:0] alu_a;
     wire [15:0] alu_b;
     assign alu_a = rd_data;
     assign alu_b = use_imm ? imm:rs_data;

    wire [15:0] alu_result;

    wire alu_zero;
    wire alu_carry;
    wire alu_valid;

    reg zero;
    reg carry;
    reg valid;

    wire [31:0] instruction;

    reg ram_write_enable;

    reg [15:0] ram_addr;
    reg [15:0] ram_write_data;

    wire [15:0] ram_read_data;

     wire is_alu_operation =
       (opcode >= 8'h01 && opcode <= 8'h08) || // arithmetic
       (opcode >= 8'h10 && opcode <= 8'h16) || // logic
       (opcode >= 8'h20 && opcode <= 8'h21) || // shift
       (opcode >= 8'h30 && opcode <= 8'h31);   // compare

    wire is_ram_operation = (opcode >= 8'h50 && opcode <= 8'h53);

    // Instruction memory
    ROM #(.PROGRAM_FILE(PROGRAM_FILE)) rom_inst(
        .clk(clk),
        .addr(pc),
        .instruction(instruction)
    );

    REGFILE regfile_inst(
        .clk(clk),
        .reset(reset),
        .rd_addr(rd),
        .rs_addr(rs),
        .rd_data(rd_data),
        .rs_data(rs_data),
        .write_enable(write_enable),
        .write_addr(write_addr),
        .write_data(write_data)
    );

   ALU alu_inst(
        .opcode(alu_opcode),
        .a(alu_a),
        .b(alu_b),
        .result(alu_result),
        .zero(alu_zero),
        .carry(alu_carry),
        .valid(alu_valid)
    );

    RAM ram_inst(
        .clk(clk),
        .reset(reset),
        .addr(ram_addr),
        .read_data(ram_read_data),
        .write_enable(ram_write_enable),
        .write_data(ram_write_data),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .hex4_out(hex4_out),
        .hex3_out(hex3_out),
        .hex2_out(hex2_out),
        .hex1_out(hex1_out),
        .hex0_out(hex0_out)
    );

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            state <= FETCH_WAIT;
            ir <= 32'b0;
            pc <= 16'b0;
            write_enable <= 1'b0;
            ram_write_enable <= 1'b0;
            zero <= 1'b0;
            carry <= 1'b0;
            valid <= 1'b0;
            use_imm <= 1'b0;
            alu_opcode <= ALU_NOP;
            opcode <= 8'b0;
            rd <= 4'b0;
            rs <= 4'b0;
            imm <= 16'b0;
            write_addr <= 4'b0;
            write_data <= 16'b0;
            ram_addr <= 16'b0;
            ram_write_data <= 16'b0;
        end
        else begin
            case(state)
                FETCH_WAIT: begin
                    state <= FETCH_INSTRUCTION;
                end

                FETCH_INSTRUCTION: begin
                    ir <= instruction;

                    write_enable <= 1'b0;
                    ram_write_enable <= 1'b0;
                    state <= DECODE;
                end
                DECODE: begin
                    opcode <= ir[31:24];
                    rd <= ir[23:20];
                    rs <= ir[19:16];
                    imm <= ir[15:0];
                    state <= SETUP_ALU;
                end
                SETUP_ALU: begin
                    state <= EXECUTE;

                     if (opcode == 8'h08 || opcode == 8'h07 || is_ram_operation) begin
                        state <= SETUP_RAM;
                     end
                     alu_opcode <= ALU_NOP;
                     use_imm <= 1'b0;
                    case(opcode)

                        8'h01: begin
                            alu_opcode <= ALU_ADD;
                            use_imm <= 1'b0;
                        end

                        8'h02: begin
                            alu_opcode <= ALU_ADD;
                            use_imm <= 1'b1;
                        end

                        8'h03: begin
                            alu_opcode <= ALU_SUB;
                            use_imm <= 1'b0;
                        end

                        8'h04: begin
                            alu_opcode <= ALU_SUB;
                            use_imm <= 1'b1;
                        end

                        8'h05: begin
                            alu_opcode <= ALU_MUL;
                            use_imm <= 1'b0;
                        end

                        8'h06: begin
                            alu_opcode <= ALU_MUL;
                            use_imm <= 1'b1;
                        end

                        8'h07: begin
                            alu_opcode <= ALU_DIV;
                            use_imm <= 1'b0;
                        end

                        8'h08: begin
                            alu_opcode <= ALU_DIV;
                            use_imm <= 1'b1;
                        end

                        8'h10: begin
                            alu_opcode <= ALU_AND;
                            use_imm <= 1'b0;
                        end

                        8'h11: begin
                            alu_opcode <= ALU_AND;
                            use_imm <= 1'b1;
                        end

                        8'h12: begin
                            alu_opcode <= ALU_OR;
                            use_imm <= 1'b0;
                        end

                        8'h13: begin
                            alu_opcode <= ALU_OR;
                            use_imm <= 1'b1;
                        end

                        8'h14: begin
                            alu_opcode <= ALU_XOR;
                            use_imm <= 1'b0;
                        end

                        8'h15: begin
                            alu_opcode <= ALU_XOR;
                            use_imm <= 1'b1;
                        end

                        8'h16: begin
                            alu_opcode <= ALU_NOT;
                            use_imm <= 1'b0;
                        end

                        8'h20: begin
                            alu_opcode <= ALU_SHL;
                            use_imm <= 1'b0;
                        end

                        8'h21: begin
                            alu_opcode <= ALU_SHR;
                            use_imm <= 1'b0;
                        end

                        8'h30: begin
                            alu_opcode <= ALU_CMP;
                            use_imm <= 1'b0;
                        end

                        8'h31: begin
                            alu_opcode <= ALU_CMP;
                            use_imm <= 1'b1;
                        end

                    endcase

                end
                SETUP_RAM: begin

                    case(opcode)

                        8'h50: begin

                            ram_write_enable <= 0;
                            ram_addr <= imm;
                        end

                        8'h51: begin
                            ram_addr <= imm;
                            ram_write_data <= rd_data;
                        end

                        8'h52: begin

                            ram_write_enable <= 0;
                            ram_addr <= rs_data;
                        end

                        8'h53: begin
                            ram_addr <= rs_data;

                            ram_write_data <= rd_data;
                        end
                    endcase
                    state <= WAIT_RAM_ALU;
                end

                WAIT_RAM_ALU: begin

                    state <= EXECUTE;

                    if(

                           (opcode == 8'h07) || // DIV
                           (opcode == 8'h08) // DIVI

                    )
                    begin

                        state <= WAIT_ALU_DIV;
                    end

                end
                    WAIT_ALU_DIV: begin

                        state <= EXECUTE;
                    end
                EXECUTE: begin

                    write_enable <= 1'b0;
                    ram_write_enable <= 1'b0;
                    pc <= pc + 1;
                    case(opcode)

                        8'h00: begin
                        end

                        8'h01, // ADD
                        8'h02, // ADDI
                        8'h03, // SUB
                        8'h04, // SUBI
                        8'h05, // MUL
                        8'h06, // MULI
                        8'h07, // DIV
                        8'h08: begin // DIVI

                            write_enable <= 1'b1;
                            write_addr <= rd;
                            write_data <= alu_result;

                                zero <= alu_zero;
                                carry <= alu_carry;
                                valid <= alu_valid;

                        end

                        8'h10, // AND
                        8'h11, // ANDI
                        8'h12, // OR
                        8'h13, // ORI
                        8'h14, // XOR
                        8'h15, // XORI
                        8'h16: begin // NOT

                            write_enable <= 1'b1;
                            write_addr <= rd;
                            write_data <= alu_result;

                            zero <= alu_zero;
                            carry <= alu_carry;
                            valid <= alu_valid;
                        end

                        8'h20, // SHL
                        8'h21: begin // SHR

                            write_enable <= 1'b1;
                            write_addr <= rd;
                            write_data <= alu_result;

                            zero <= alu_zero;
                            carry <= alu_carry;
                            valid <= alu_valid;
                        end

                        8'h30, // CMP
                        8'h31: begin // CMPI

                            zero <= alu_zero;
                            carry <= alu_carry;
                            valid <= alu_valid;
                        end

                        8'h40: begin
                            write_enable <= 1'b1;
                            write_addr <= rd;
                            write_data <= imm;
                        end

                        8'h41: begin
                            write_enable <= 1'b1;
                            write_addr <= rd;
                            write_data <= rs_data;
                        end

                        8'h50,
                        8'h52: begin
                            write_enable <= 1'b1;
                            write_addr <= rd;
                            write_data <= ram_read_data;

                        end
                        8'h51,
                        8'h53: begin

                            ram_write_enable <= 1'b1;
                        end

                        8'h60: begin
                            pc <= imm;
                        end

                        8'h61: begin
                            if(zero) pc <= imm;
                        end

                        8'h62: begin
                            if(!zero) pc <= imm;
                        end

                        8'h63: begin
                            if(carry) pc <= imm;
                        end

                        8'h64: begin
                            if(!carry) pc <= imm;
                        end

                        8'hFF: begin
                            pc <= pc;
                        end
                    endcase
                    state <= FETCH_WAIT;
                end
            endcase
        end
    end

endmodule

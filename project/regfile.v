
module REGFILE(
    input wire clk,
    input wire reset,

    input wire [3:0] rd_addr,
    input wire [3:0] rs_addr,

    output wire [15:0] rd_data,
    output wire [15:0] rs_data,

    input wire write_enable,
    input wire [3:0] write_addr,
    input wire [15:0] write_data
);

    reg [15:0] regs [0:15];

    integer i;

    // Async read, sync write.
    assign rd_data = regs[rd_addr];
    assign rs_data = regs[rs_addr];

    always @(posedge clk or posedge reset) begin

        if(reset) begin

            for(i=0; i<16; i=i+1)
                regs[i] <= 16'b0;

        end
        else begin

            if(write_enable)
                regs[write_addr] <= write_data;
        end

    end

endmodule

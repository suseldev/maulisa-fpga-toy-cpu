module ROM #(
    parameter PROGRAM_FILE = "program.hex"
)(
    input wire clk,
    input wire [15:0] addr,
    output reg [31:0] instruction
);
    reg [31:0] mem [0:65535];
    initial begin
        if (PROGRAM_FILE != "")
            $readmemh(PROGRAM_FILE, mem);
    end
    // Synchronous read
    always @(posedge clk)
        instruction <= mem[addr];
endmodule

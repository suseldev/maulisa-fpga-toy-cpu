
module DE10_LITE_Golden_Top (
    input wire MAX10_CLK1_50,
    input wire [1:0] KEY,
    input wire [9:0] SW,

    output wire [9:0] LEDR,

    output wire [7:0] HEX0,
    output wire [7:0] HEX1,
    output wire [7:0] HEX2,
    output wire [7:0] HEX3,
    output wire [7:0] HEX4,
    output wire [7:0] HEX5,

    input  wire [35:0] GPIO
);

    wire [7:0] gpio_out_wire;
     reg reset;
     reg [7:0] reset_counter = 8'b0;
    MaulCPU uut (
        .clk(MAX10_CLK1_50),
        .reset(reset),
        .hex4_out(HEX4),
        .hex3_out(HEX3),
        .hex2_out(HEX2),
        .hex1_out(HEX1),
        .hex0_out(HEX0),

        .gpio_out (gpio_out_wire),

        .gpio_in(GPIO[7:0])
    );

    // Only eight LEDs are mapped.
    assign LEDR[7:0] = gpio_out_wire;
    assign LEDR[9:8] = 2'b00;
    assign HEX5 = 8'hFF;

    always @(posedge MAX10_CLK1_50) begin

        reset <= ~KEY[0];
        // Hold reset at startup.
        if(reset_counter < 100) begin
            reset <= 1;
            reset_counter <= reset_counter + 1;
        end
    end

endmodule

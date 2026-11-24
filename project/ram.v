module RAM(
    input wire clk,
    input wire reset,
    input wire [15:0] addr,
    output reg [15:0] read_data,
    input wire write_enable,
    input wire [15:0] write_data,

    output reg [7:0] hex4_out, hex3_out, hex2_out, hex1_out, hex0_out,
    input wire [7:0] gpio_in,
    output reg [7:0] gpio_out
);

    // Keep the RAM separate from MMIO for BRAM inference.
    reg [15:0] mem [0:65535];

    reg [15:0] mem_read_data;

    wire is_mmio;

    assign is_mmio = (addr == 16'hFF0F) || (addr >= 16'hFFF0);

    always @(posedge clk) begin

        mem_read_data <= mem[addr];
        if(write_enable && !is_mmio) begin
            mem[addr] <= write_data;
        end
    end

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            hex0_out <= 8'b0;
            hex1_out <= 8'b0;
            hex2_out <= 8'b0;
            hex3_out <= 8'b0;
            hex4_out <= 8'b0;
            gpio_out <= 8'b0;
        end else begin
            case(addr)

                16'hFFF4: begin
                    if(write_enable) begin
                        hex4_out <= write_data[7:0];
                    end
                end

                16'hFFF3: begin
                    if(write_enable) begin
                        hex3_out <= write_data[7:0];
                    end
                end

                16'hFFF2: begin
                    if(write_enable) begin
                        hex2_out <= write_data[7:0];
                    end
                end

                16'hFFF1: begin
                    if(write_enable) begin
                        hex1_out <= write_data[7:0];

                    end
                end

                16'hFFF0: begin
                    if(write_enable) begin
                        hex0_out <= write_data[7:0];
                    end
                end

                16'hFFFF: begin
                    if(write_enable) begin
                        gpio_out <= write_data[7:0];
                    end
                end
            endcase
        end
    end

    always @(*) begin
        case(addr)

            16'hFF0F:
                read_data = {8'b0, gpio_in};

            16'hFFF0,
            16'hFFF1,
            16'hFFF2,
            16'hFFF3,
            16'hFFF4,
            16'hFFFF:
                read_data = 16'b0;

            default:
                read_data = mem_read_data;
        endcase
    end
endmodule

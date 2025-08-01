module led_peripheral(
    input  wire clk,
    input  wire rst_n,
    input  wire rd_en_i,
    input  wire wr_en_i,
    input  wire [31:0] addr_i,
    input  wire [31:0] data_i,
    output wire [31:0] data_o,
    output wire [7:0] leds_o
);

    reg [7:0] led_reg;
    wire [3:0] effective_address = addr_i[3:0];
    assign leds_o = led_reg;

    assign data_o = (rd_en_i && addr_i[3:0] == 4'h4) ? {24'b0, led_reg} : 32'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            led_reg <= 8'b0;
        else if (wr_en_i && effective_address == 4'h0)
            led_reg <= data_i[7:0];
    end
endmodule

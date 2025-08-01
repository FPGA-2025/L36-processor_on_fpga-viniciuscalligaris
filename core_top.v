module core_top #(
    parameter MEMORY_FILE = "",
    parameter MEMORY_SIZE = 4096
)(
    input wire clk,
    input wire rst_n,
    output wire [7:0] leds
);

    wire rd_en;
    wire wr_en;
    wire [31:0] addr;
    wire [31:0] data_out;   
    wire [31:0] data_in;    

    wire mem_rd_en;
    wire mem_wr_en;
    wire [31:0] mem_addr;
    wire [31:0] mem_data_in;
    wire [31:0] mem_data_out;

    wire periph_rd_en;
    wire periph_wr_en;
    wire [31:0] periph_addr;
    wire [31:0] periph_data_in;
    wire [31:0] periph_data_out;

    Core #(
        .BOOT_ADDRESS(32'h00000000)
    ) core (
        .clk(clk),
        .rst_n(rst_n),
        .rd_en_o(rd_en),
        .wr_en_i(wr_en),
        .addr_o(addr),
        .data_o(data_out),
        .data_i(data_in)
    );

    bus_interconnect interconnect (
        .proc_rd_en_i(rd_en),
        .proc_wr_en_i(wr_en),
        .proc_addr_i(addr),
        .proc_data_i(data_out),
        .proc_data_o(data_in),

        .mem_rd_en_o(mem_rd_en),
        .mem_wr_en_o(mem_wr_en),
        .mem_addr_o(mem_addr),
        .mem_data_o(mem_data_out),
        .mem_data_i(mem_data_in),

        .periph_rd_en_o(periph_rd_en),
        .periph_wr_en_o(periph_wr_en),
        .periph_addr_o(periph_addr),
        .periph_data_o(periph_data_out),
        .periph_data_i(periph_data_in)
    );

    Memory #(
        .MEMORY_FILE(MEMORY_FILE),
        .MEMORY_SIZE(MEMORY_SIZE)
    ) mem (
        .clk(clk),
        .rd_en_i(mem_rd_en),
        .wr_en_i(mem_wr_en),
        .addr_i(mem_addr),
        .data_i(mem_data_out),
        .data_o(mem_data_in),
        .ack_o()
    );

    led_peripheral led (
        .clk(clk),
        .rst_n(rst_n),
        .rd_en_i(periph_rd_en),
        .wr_en_i(periph_wr_en),
        .addr_i(periph_addr),
        .data_i(periph_data_out),
        .data_o(periph_data_in),
        .leds_o(leds)
    );

endmodule

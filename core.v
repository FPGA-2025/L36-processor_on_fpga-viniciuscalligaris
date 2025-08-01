module Core #(
    parameter BOOT_ADDRESS = 32'h00000000
)(
    input wire clk,
    input wire rst_n,
    output reg rd_en_o,
    output reg wr_en_i,
    input wire [31:0] data_i,
    output reg [31:0] addr_o,
    output reg [31:0] data_o
);

    reg [31:0] regfile [0:31];
    reg [31:0] pc;
    reg [3:0]  state;

    reg [31:0] instr;
    reg [31:0] sw_target;
    reg [31:0] sw_data;

    localparam FETCH = 0, DECODE = 1, EXEC = 2, WRITE_SW = 3, WAIT_SW = 4, LOAD_WAIT = 5, DONE = 6;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= BOOT_ADDRESS;
            state <= FETCH;
            wr_en_i <= 0;
            rd_en_o <= 0;
            addr_o <= 0;
            data_o <= 0;

            regfile[0] <= 0;
            regfile[5] <= 0;
        end else begin
            regfile[0] <= 0;

            case (state)
                FETCH: begin
                    addr_o <= pc;
                    rd_en_o <= 1;
                    state <= DECODE;
                end

                DECODE: begin
                    rd_en_o <= 0;
                    instr <= data_i;
                    pc <= pc + 4;
                    state <= EXEC;
                end

                EXEC: begin
                    case (instr[6:0])
                        7'b0010011: begin // ADDI, SRLI
                            if (instr[14:12] == 3'b000) begin // ADDI
                                regfile[instr[11:7]] <= {{20{instr[31]}}, instr[31:20]};
                            end else if (instr[14:12] == 3'b101) begin // SRLI
                                regfile[instr[11:7]] <= regfile[instr[19:15]] >> instr[24:20];
                            end
                            state <= FETCH;
                        end

                        7'b0110011: begin // ADD, XOR
                            case (instr[14:12])
                                3'b000: regfile[instr[11:7]] <= regfile[instr[19:15]] + regfile[instr[24:20]];
                                3'b100: regfile[instr[11:7]] <= regfile[instr[19:15]] ^ regfile[instr[24:20]];
                            endcase
                            state <= FETCH;
                        end

                        7'b0100011: begin // SW
                            sw_target <= regfile[instr[19:15]] + {{20{instr[31]}}, instr[31:25], instr[11:7]};
                            sw_data <= regfile[instr[24:20]];
                            state <= WRITE_SW;
                        end

                        7'b0000011: begin // LW
                            addr_o <= regfile[instr[19:15]] + {{20{instr[31]}}, instr[31:20]};
                            rd_en_o <= 1;
                            state <= LOAD_WAIT;
                        end

                        7'b0110111: begin // LUI
                            regfile[instr[11:7]] <= {instr[31:12], 12'b0};
                            state <= FETCH;
                        end

                        7'b0010111: begin // AUIPC
                            regfile[instr[11:7]] <= pc - 4 + {instr[31:12], 12'b0};
                            state <= FETCH;
                        end

                        7'b1101111: begin // JAL
                            regfile[instr[11:7]] <= pc;
                            pc <= pc - 4 + {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
                            state <= FETCH;
                        end

                        7'b1100111: begin // JALR
                            regfile[instr[11:7]] <= pc;
                            pc <= (regfile[instr[19:15]] + {{20{instr[31]}}, instr[31:20]}) & ~1;
                            state <= FETCH;
                        end

                        7'b1100011: begin // BEQ
                            if (regfile[instr[19:15]] == regfile[instr[24:20]]) begin
                                pc <= pc - 4 + {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
                            end
                            state <= FETCH;
                        end

                        default: begin
                            state <= FETCH;
                        end
                    endcase
                end

                WRITE_SW: begin
                    addr_o <= sw_target;
                    data_o <= sw_data;
                    wr_en_i <= 1;
                    state <= WAIT_SW;
                end

                WAIT_SW: begin
                    wr_en_i <= 0;
                    state <= FETCH;
                end

                LOAD_WAIT: begin
                    rd_en_o <= 0;
                    regfile[instr[11:7]] <= data_i;
                    state <= FETCH;
                end

                DONE: begin
                end
            endcase
        end
    end

endmodule
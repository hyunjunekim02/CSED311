`include "opcodes.v"

module HazardDetectionUnit (input [4:0] rs1,
                            input [4:0] rs2,
                            input [4:0] id_ex_rd,
                            input [6:0] id_ex_opcode,
                            input id_ex_mem_read,
                            input [4:0] ex_mem_rd,
                            input ex_mem_mem_read,
                            input is_ecall,
                            output reg is_hazard);

    wire rs_match_rd = (rs1 == id_ex_rd) | (rs2 == id_ex_rd);
    wire id_ex_rd17 = is_ecall & (id_ex_rd == 17);
    wire opcode_match = (id_ex_opcode == `ARITHMETIC) | (id_ex_opcode == `ARITHMETIC_IMM) | (id_ex_opcode == `LOAD) | (id_ex_opcode == `JAL) | (id_ex_opcode == `JALR);
    wire ex_mem_rd17 = is_ecall & (ex_mem_rd == 17);

    always @(*) begin
        if ((rs_match_rd & id_ex_mem_read) | (id_ex_rd17 & opcode_match) | (is_ecall & ex_mem_mem_read & ex_mem_rd17)) begin
            is_hazard = 1;
        end
        else begin
            is_hazard = 0;
        end
    end

endmodule

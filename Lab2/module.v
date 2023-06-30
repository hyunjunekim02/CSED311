`include "opcodes.v"

module PC (input reset,
          input clk,
          input [31:0] next_pc,
          output reg [31:0] current_pc);

  always @(posedge clk) begin
    if(reset) begin
      current_pc <= 0;
    end
    else begin
      current_pc <= next_pc;
    end
  end

endmodule

module ControlUnit (input [6:0] part_of_inst,
                    output is_jal,
                    output is_jalr,
                    output branch,
                    output mem_read,
                    output mem_to_reg,
                    output mem_write,
                    output alu_src,
                    output write_enable,
                    output pc_to_reg,
                    output is_ecall);
  
  assign is_jalr = (part_of_inst == `JALR) ? 1 : 0;
  assign is_jal = (part_of_inst == `JAL) ? 1 : 0;
  assign branch = (part_of_inst == `BRANCH) ? 1 : 0;
  assign mem_read = (part_of_inst == `LOAD) ? 1 : 0;
  assign mem_to_reg = (part_of_inst == `LOAD) ? 1 : 0;
  assign mem_write = (part_of_inst == `STORE) ? 1 : 0;
  assign alu_src = (part_of_inst != `ARITHMETIC && part_of_inst != `BRANCH) ? 1 : 0;
  assign write_enable = ((part_of_inst != `STORE) && (part_of_inst != `BRANCH)) ? 1 : 0; 
  assign pc_to_reg = (part_of_inst == `JAL || part_of_inst == `JALR) ? 1: 0;
  assign is_ecall = (part_of_inst == `ECALL) ? 1 : 0;

endmodule


module ImmediateGenerator(input [31:0] part_of_inst,
                          output reg [31:0] imm_gen_out);

  always @(*) begin
    case (part_of_inst[6:0])
      `ARITHMETIC_IMM, `LOAD, `JALR: begin // I-type
        imm_gen_out = {{21{part_of_inst[31]}}, part_of_inst[30:20]};
      end
      `STORE: begin // S-type
        imm_gen_out = {{21{part_of_inst[31]}}, part_of_inst[30:25], part_of_inst[11:7]};
      end
      `BRANCH: begin // B-type
        imm_gen_out = {{20{part_of_inst[31]}}, part_of_inst[7], part_of_inst[30:25], part_of_inst[11:8], 1'b0};
      end
      `JAL: begin // J-type
        imm_gen_out = {{12{part_of_inst[31]}}, part_of_inst[19:12], part_of_inst[20], part_of_inst[30:25], part_of_inst[24:21], 1'b0};
      end
      default: begin
        imm_gen_out = 32'b0;
      end
    endcase
  end

endmodule

module ALUControlUnit (input [31:0] part_of_inst,
                      output reg [2:0] alu_op);

  wire [6:0] opcode;
  wire [2:0] funct3;
  wire [6:0] funct7;

  assign opcode = part_of_inst[6:0];
  assign funct3 = part_of_inst[14:12];
  assign funct7 = part_of_inst[31:25];

  always @(*) begin
    case(opcode)
      `ARITHMETIC : begin
        case(funct7)
          `FUNCT7_SUB : begin
            alu_op = `FUNCT_SUB;
          end
          default : begin
            alu_op = funct3;
          end
        endcase
      end
      `ARITHMETIC_IMM : begin
        alu_op = funct3;
      end
      `LOAD : alu_op = `FUNCT3_ADD;
      `STORE : alu_op = `FUNCT3_ADD;
      `JALR : alu_op = `FUNCT3_ADD;
      `BRANCH : alu_op = `FUNCT_SUB;
      default : alu_op = 3'b000;
    endcase
  end

endmodule


module ALU (input [2:0] alu_op,
            input [31:0] alu_in_1,
            input [31:0] alu_in_2,
            input [2:0] funct3,
            output [31:0] alu_result,
            output alu_bcond);

  reg [31:0] result;
  reg bcond;

  assign alu_result = result;
  assign alu_bcond = bcond;

  always @(*) begin
    case(alu_op)
      `FUNCT3_ADD: begin
        result = alu_in_1 + alu_in_2;
      end
      `FUNCT_SUB: begin
        result = alu_in_1-alu_in_2;
        case(funct3)
          `FUNCT3_BEQ: begin
            bcond = (result == 32'b0);
          end
          `FUNCT3_BNE: begin
            bcond = (result != 32'b0);
          end
          `FUNCT3_BLT: begin
            bcond = (result[31] == 1'b1);
          end
          `FUNCT3_BGE: begin
            bcond = (result[31] != 1'b1);
          end
          default:
            bcond = 1'b0;
        endcase
      end
      `FUNCT3_SLL: begin
        result = alu_in_1 << alu_in_2;
      end
      `FUNCT3_XOR: begin
        result = alu_in_1 ^ alu_in_2;
      end
      `FUNCT3_OR: begin
        result = alu_in_1 | alu_in_2;
      end
      `FUNCT3_AND: begin
        result = alu_in_1 & alu_in_2;
      end
      `FUNCT3_SRL: begin
        result = alu_in_1 >> alu_in_2;
      end
      default: begin
        result = 0;
      end
    endcase

    if(alu_op!=`FUNCT_SUB) begin
      bcond = 1'b0;
    end

  end

endmodule
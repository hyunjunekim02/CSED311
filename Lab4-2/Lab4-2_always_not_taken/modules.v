`include "opcodes.v"

//Program Counter Module
module PC (input reset,
           input clk,
           input pc_write,
           input [31:0] next_pc,
           output reg [31:0] current_pc);
  
  always @(posedge clk) begin
    if (reset) begin
      current_pc <= 32'b0;
    end
    else begin
      current_pc <= pc_write ? next_pc : current_pc;
    end
  end
  
endmodule

//Immediate Generator Module
module ImmediateGenerator (input [31:0] part_of_inst,
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

//ALU Control Module
module ALUControlUnit (input [31:0] part_of_inst,
                       input [1:0] ALUOp,
                       output reg [2:0] alu_op);
  wire [6:0] opcode;
  wire [2:0] funct3;
  wire [6:0] funct7;

  assign opcode = part_of_inst[6:0];
  assign funct3 = part_of_inst[14:12];
  assign funct7 = part_of_inst[31:25];

  always @(*) begin
    case(ALUOp)
      2'b00: alu_op = `FUNCT3_ADD;
      2'b01: alu_op = `FUNCT_SUB;
      2'b10: begin
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
          `ARITHMETIC_IMM : alu_op = funct3;
          `LOAD : alu_op = `FUNCT3_ADD;
          `STORE : alu_op = `FUNCT3_ADD;
          `JALR : alu_op = `FUNCT3_ADD;
          `BRANCH : alu_op = `FUNCT_SUB;
          default : alu_op = 3'b000;
        endcase
      end
      default: alu_op = 3'b000;
    endcase
  end
endmodule

//ALU Module
module ALU (input [2:0] alu_op,
            input [31:0] alu_in_1,
            input [31:0] alu_in_2,
            input [2:0] funct3,
            output reg [31:0] alu_result,
            output reg alu_bcond);

  always @(*) begin
    case(alu_op)
      `FUNCT3_ADD: begin
        alu_result = alu_in_1 + alu_in_2;
      end
      `FUNCT_SUB: begin
        alu_result = alu_in_1 - alu_in_2;
        case(funct3)
          `FUNCT3_BEQ: begin
            alu_bcond = (alu_result == 32'b0);
          end
          `FUNCT3_BNE: begin
            alu_bcond = (alu_result != 32'b0);
          end
          `FUNCT3_BLT: begin
            alu_bcond = (alu_result[31] == 1'b1);
          end
          `FUNCT3_BGE: begin
            alu_bcond = (alu_result[31] != 1'b1);
          end
          default:
            alu_bcond = 1'b0;
        endcase
      end
      `FUNCT3_SLL: begin
        alu_result = alu_in_1 << alu_in_2;
      end
      `FUNCT3_XOR: begin
        alu_result = alu_in_1 ^ alu_in_2;
      end
      `FUNCT3_OR: begin
        alu_result = alu_in_1 | alu_in_2;
      end
      `FUNCT3_AND: begin
        alu_result = alu_in_1 & alu_in_2;
      end
      `FUNCT3_SRL: begin
        alu_result = alu_in_1 >> alu_in_2;
      end
      default: begin
        alu_result = 0;
      end
    endcase
  end
endmodule

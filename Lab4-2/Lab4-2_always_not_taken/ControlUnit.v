`include "opcodes.v"

module ControlUnit( input [6:0] part_of_inst,
                    output reg mem_read,
                    output reg mem_to_reg,
                    output reg mem_write,
                    output reg alu_src,
                    output reg reg_write,
                    output reg [1:0] alu_op,
                    output reg is_jal,
                    output reg is_jalr,
                    output reg branch,
                    output reg pc_to_reg,
                    output is_ecall);

  assign is_ecall = (part_of_inst == `ECALL) ? 1 : 0;

  always @(*) begin
    if (part_of_inst == `LOAD) begin
      mem_read = 1;
      mem_to_reg = 1;
      mem_write = 0;
      alu_src = 1;
      reg_write = 1;
      alu_op = 2'b00;
      is_jal = 0;
      is_jalr = 0;
      branch = 0;
      pc_to_reg = 0;
      end
    else if (part_of_inst == `STORE) begin
      mem_read = 0;
      mem_to_reg = 0;
      mem_write = 1;
      alu_src = 1;
      reg_write = 0;
      alu_op = 2'b00;
      is_jal = 0;
      is_jalr = 0;
      branch = 0;
      pc_to_reg = 0;
    end
    else if (part_of_inst == `ARITHMETIC) begin
      mem_read = 0;
      mem_to_reg = 0;
      mem_write = 0;
      alu_src = 0;
      reg_write = 1;
      alu_op = 2'b10;
      is_jal = 0;
      is_jalr = 0;
      branch = 0;
      pc_to_reg = 0;
    end
    else if (part_of_inst == `ARITHMETIC_IMM) begin
      mem_read = 0;
      mem_to_reg = 0;
      mem_write = 0;
      alu_src = 1;
      reg_write = 1;
      alu_op = 2'b10;
      is_jal = 0;
      is_jalr = 0;
      branch = 0;
      pc_to_reg = 0;
    end
	  else if (part_of_inst == `ECALL) begin
      mem_read = 0;
      mem_to_reg = 0;
      mem_write = 0;
      alu_src = 0;
      reg_write = 1;
      is_jal = 0;
      is_jalr = 0;
      branch = 0;
      pc_to_reg = 0;
    end
    else if (part_of_inst == `JALR) begin
      mem_read = 0;
      mem_to_reg = 0;
      mem_write = 0;
      alu_src = 1;
      reg_write = 1;
      alu_op = 2'b00;
      is_jal = 0;
      is_jalr = 1;
      branch = 0;
      pc_to_reg = 1;
    end
    else if (part_of_inst == `JAL) begin
      mem_read = 0;
      mem_to_reg = 0;
      mem_write = 0;
      alu_src = 0;
      reg_write = 1;
      alu_op = 2'b00;
      is_jal = 1;
      is_jalr = 0;
      branch = 0;
      pc_to_reg = 1;
    end
    else if (part_of_inst == `BRANCH) begin
      mem_read = 0;
      mem_to_reg = 0;
      mem_write = 0;
      alu_src = 0;
      reg_write = 0;
      alu_op = 2'b01;
      is_jal = 0;
      is_jalr = 0;
      branch = 1;
      pc_to_reg = 0;
    end
  end
endmodule
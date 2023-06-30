`include "opcodes.v"

module ControlUnit( input [6:0] part_of_inst,
                    output reg mem_read,
                    output reg mem_to_reg,
                    output reg mem_write,
                    output reg alu_src,
                    output reg reg_write,
                    output reg [1:0] alu_op,
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
      end
    else if (part_of_inst == `STORE) begin
      mem_read = 0;
      mem_to_reg = 0;
      mem_write = 1;
      alu_src = 1;
      reg_write = 0;
      alu_op = 2'b00;
    end
    else if (part_of_inst == `ARITHMETIC) begin
      mem_read = 0;
      mem_to_reg = 0;
      mem_write = 0;
      alu_src = 0;
      reg_write = 1;
      alu_op = 2'b10;
    end
    else if (part_of_inst == `ARITHMETIC_IMM) begin
      mem_read = 0;
      mem_to_reg = 0;
      mem_write = 0;
      alu_src = 1;
      reg_write = 1;
      alu_op = 2'b10;
    end
	  else if (part_of_inst == `ECALL) begin
      mem_read = 0;
      mem_to_reg = 0;
      mem_write = 0;
      alu_src = 0;
      reg_write = 1;
    end
    else if (part_of_inst == `JALR) begin
      mem_read = 0;
      mem_to_reg = 0;
      mem_write = 0;
      alu_src = 1;
      reg_write = 1;
      alu_op = 2'b00;
    end
    else if (part_of_inst == `JAL) begin
      mem_read = 0;
      mem_to_reg = 0;
      mem_write = 0;
      alu_src = 0;
      reg_write = 1;
      alu_op = 2'b00;
    end
    else if (part_of_inst == `BRANCH) begin
      mem_read = 0;
      mem_to_reg = 0;
      mem_write = 0;
      alu_src = 0;
      reg_write = 0;
      alu_op = 2'b01;
    end
  end
endmodule
`include "opcodes.v"

module ControlUnit( input [6:0] part_of_inst,
                    output mem_read,
                    output mem_to_reg,
                    output mem_write,
                    output alu_src,
                    output reg_write,
                    output reg [1:0] alu_op,
                    output is_jal,
                    output is_jalr,
                    output branch,
                    output pc_to_reg,
                    output is_ecall);

  assign branch = (part_of_inst == `BRANCH);
  assign mem_read = (part_of_inst == `LOAD);
  assign mem_to_reg = (part_of_inst == `LOAD);
  assign mem_write = (part_of_inst == `STORE);
  assign alu_src = ((part_of_inst == `ARITHMETIC_IMM) || (part_of_inst == `LOAD) || (part_of_inst == `JALR) || (part_of_inst == `STORE));
  assign reg_write = ((part_of_inst != `STORE) && (part_of_inst != `BRANCH));

  always @(*) begin
      if((part_of_inst == `LOAD) || (part_of_inst == `STORE) || (part_of_inst == `JAL) || (part_of_inst == `JALR)) begin
          alu_op = 2'b00;
      end
      else if(part_of_inst == `BRANCH) begin
          alu_op = 2'b01;
      end
      else if((part_of_inst == `ARITHMETIC) || (part_of_inst == `ARITHMETIC_IMM)) begin
          alu_op = 2'b10;
      end
  end

  assign is_jal = (part_of_inst == `JAL);
  assign is_jalr = (part_of_inst == `JALR);
  assign pc_to_reg = ((part_of_inst == `JAL) || (part_of_inst == `JALR));
  assign is_ecall = (part_of_inst == `ECALL);

endmodule
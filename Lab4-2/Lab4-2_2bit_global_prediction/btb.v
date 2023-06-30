module BTB(input [31:0] pc,
           input reset,
           input clk,
           input [31:0] IF_ID_pc,
           input alu_bcond,
           input [31:0] write_pc,
           input [31:0] pc_plus_imm,
           input [31:0] reg_plus_imm,
           input is_jal,
           input is_jalr,
           input branch,
           output reg [31:0] nPC
           );
  
  //wire
  wire [31:0] tag;
  wire [4:0] index;
  wire [4:0] write_idx;
  wire [31:0] write_tag;
  wire taken;

  //reg
  reg [5:0] idx;
  reg [31:0] tag_table[0:31];
  reg [31:0] btb[0:31];
  reg [1:0] bht;

  // assignment
  assign tag=pc[31:7];
  assign index=pc[6:2];
  assign write_tag = writePC[31:7];
  assign write_idx = writePC[6:2];
  assign taken = (branch & alu_bcond) | is_jal | is_jalr;
  
  always @(*) begin
    if((tag_table[index] == tag) & (bht >= 2'b10)) begin
      nPC = btb[index];
    end
    else begin
      nPC = pc + 4;
    end
  end

  always @(*) begin
    if (is_jal | branch) begin
      if ((tag_table[write_idx] != write_tag) | (btb[write_idx] != pc_plus_imm)) begin
        tag_table[write_idx] = write_tag;
        btb[write_idx] = pc_plus_imm;
      end
    end
    else if (is_jalr) begin
      if ((tag_table[write_idx] != write_tag) | (btb[write_idx] != reg_plus_imm)) begin
        tag_table[write_idx] = write_tag;
        btb[write_idx] = reg_plus_imm;
      end
    end
  end
   
  // 2-bit prediction
  always @(*) begin
    if (branch | is_jal | is_jalr) begin 
      if(taken) begin
        case(bht)
          2'b00: begin
            bht=2'b01;
          end
          2'b01: begin
            bht=2'b10;
          end
          2'b10: begin
            bht=2'b11;
          end
          2'b11: begin
            bht=2'b11;
          end
        endcase
      end
      else begin
        case(bht)
          2'b00: begin
            bht=2'b00;
            end
          2'b01: begin
            bht=2'b00;
          end
          2'b10: begin
            bht=2'b01;
          end
          2'b11: begin
            bht=2'b10;
          end
        endcase
      end
    end
  end

  always @(posedge clk) begin
    if (reset) begin
      for(idx = 0; idx < 32; idx = idx + 1) begin
        btb[idx] = 0;
        tag_table[idx] = -1;
      end
      bht[idx] = 2'b00;
    end
  end

endmodule

//Predicting Misses
module MissPredDetector(input [31:0] IF_ID_pc,
                        input ID_EX_is_jal,
                        input ID_EX_is_jalr,
                        input ID_EX_branch,
                        input ID_EX_bcond,
                        input [31:0] ID_EX_pc,
                        input [31:0] pc_plus_imm,
                        input [31:0] reg_plus_imm,
                        output reg is_miss_pred);

  wire is_jal_or_taken = (ID_EX_is_jal | (ID_EX_branch & ID_EX_bcond)) & (IF_ID_pc != pc_plus_imm);
  wire is_jalr_or_taken  = (ID_EX_is_jalr) & (IF_ID_pc != reg_plus_imm);
  wire is_branch  = (IF_ID_pc != ID_EX_pc+4) & (ID_EX_branch & !ID_EX_bcond);

  always @(*) begin
    if(is_jal_or_taken | is_jalr_or_taken | is_branch) begin
      is_miss_pred=1;
    end
    else begin
      is_miss_pred=0;
    end 
  end

endmodule
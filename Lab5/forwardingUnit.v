module ForwardingUnit (input [4:0] rs1,
                        input [4:0] rs2,
                        input [4:0] EX_MEM_rd,
                        input EX_MEM_reg_write,
                        input [4:0] MEM_WB_rd,
                        input MEM_WB_reg_write,
                        output reg [1:0] ForwardA,
                        output reg [1:0] ForwardB);

    always @(*) begin
        if((rs1 == EX_MEM_rd) && (rs1 != 0) && EX_MEM_reg_write) begin
            ForwardA = 2'b01;
        end
        else if((rs1 == MEM_WB_rd) && (rs1 != 0) && MEM_WB_reg_write) begin
            ForwardA = 2'b10;
        end
        else begin
            ForwardA = 2'd00;
        end

        if((rs2 == EX_MEM_rd) && (rs2 != 0) && EX_MEM_reg_write) begin
            ForwardB = 2'b01;
        end
        else if((rs2 == MEM_WB_rd) && (rs2 != 0) && MEM_WB_reg_write) begin
            ForwardB = 2'b10;
        end
        else begin
            ForwardB = 2'b00;
        end
    end
endmodule


module ForwardingEcall( input [4:0] rs1,
                        input [4:0] rs2,
                        input [4:0] rd,
                        input [4:0] EX_MEM_rd,
                        input is_ecall,
                        input [31:0] rd_din,
                        input [31:0] rs1_dout,
                        input [31:0] rs2_dout,
                        input [31:0] EX_MEM_alu_out,
                        input EX_MEM_reg_write,
                        input MEM_WB_reg_write,
                        output reg [31:0] f_rs1_dout,
                        output reg [31:0] f_rs2_dout);

    always @(*) begin
        if((rs1 == rd) && (rd != 0) && MEM_WB_reg_write) begin
            f_rs1_dout = rd_din;
        end
        else if((EX_MEM_rd == 5'd17) && is_ecall && EX_MEM_reg_write) begin
            f_rs1_dout = EX_MEM_alu_out;
        end
        else begin
            f_rs1_dout = rs1_dout;
        end

        if((rs2 == rd) && (rd != 0) && MEM_WB_reg_write) begin
            f_rs2_dout = rd_din;
        end
        else begin
            f_rs2_dout = rs2_dout;
        end
    end
endmodule

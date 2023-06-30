`include "opcodes.v"
`include "FiniteState.v"

module ControlUnit(
    input [6:0] part_of_inst,
    input clk,
    input reset,
    input alu_bcond,
    output reg pcWrite_cond,
    output reg pcWrite,
    output reg IorD,
    output reg mem_read,
    output reg mem_write,
    output reg mem_to_reg,
    output reg IRWrite,
    output reg PCSource,
    output reg [1:0] ALUOp,
    output reg [1:0] ALUSrcB,
    output reg ALUSrcA,
    output reg reg_write,
    output is_ecall);

    reg [3:0] current_state = `IF;
    wire [3:0] next_state;

    assign is_ecall = (part_of_inst == `ECALL);

    always @(*) begin
        pcWrite_cond = 0;
        pcWrite = 0;
        IorD = 0;
        mem_read = 0;
        mem_write = 0;
        mem_to_reg = 0;
        IRWrite = 0;
        PCSource = 0;
        ALUOp = 0;
        ALUSrcB = 0;
        ALUSrcA = 0;
        reg_write = 0;

        case (current_state)
            `IF: begin
                IorD = 0;
                mem_read = 1;
                IRWrite = 1;
            end
            `ID: begin
                ALUOp = 2'b00;
                ALUSrcB = 2'b01;
                ALUSrcA = 0;
            end
            `EX_R: begin
                ALUOp = 2'b10;
                ALUSrcB = 2'b00;
                ALUSrcA = 1;
            end
            `EX_LDSD: begin
                ALUOp = 2'b00;
                ALUSrcB = 2'b10;
                ALUSrcA = 1;
            end
            `EX_B: begin
                pcWrite = !alu_bcond;
                PCSource = 1;
                ALUOp = 2'b01;
                ALUSrcB = 2'b00;
                ALUSrcA = 1;
            end
            `EX_JAL: begin
                pcWrite = 1;
                mem_to_reg = 0;
                PCSource = 0;
                ALUOp = 2'b00;
                ALUSrcB = 2'b10;
                ALUSrcA = 0;
                reg_write = 1;
            end
            `EX_JALR: begin
                pcWrite = 1;
                mem_to_reg = 0;
                PCSource = 0;
                ALUOp = 2'b00;
                ALUSrcB = 2'b10;
                ALUSrcA = 1;
                reg_write = 1;             
            end
            `MEM_R: begin
                pcWrite = 1;
                mem_to_reg = 0;
                PCSource = 0;
                ALUOp = 2'b00;
                ALUSrcB = 2'b01;
                ALUSrcA = 0;
                reg_write = 1; 
            end
            `MEM_LD: begin
                IorD = 1;
                mem_read = 1;
            end
            `MEM_SD: begin
                pcWrite = 1;
                IorD = 1;
                mem_write = 1;
                PCSource = 0; 
                ALUOp = 2'b00;
                ALUSrcB = 2'b01;
                ALUSrcA = 0;
            end
            `MEM_B: begin
                pcWrite = 1;
                PCSource = 0;
                ALUOp = 2'b00;
                ALUSrcB = 2'b10;
                ALUSrcA = 0;
            end
            `WB_LD: begin
                pcWrite = 1;
                mem_to_reg = 1;
                PCSource = 0;
                ALUOp = 2'b00;
                ALUSrcB = 2'b01;
                ALUSrcA = 0;
                reg_write = 1;             
            end
            `AM: begin
                ALUOp = 2'b10;
                ALUSrcB = 2'b10;
                ALUSrcA = 1;
            end
            `EC: begin
                pcWrite = 1;
                PCSource = 0;
                ALUOp = 2'b00;
                ALUSrcB = 2'b01;
                ALUSrcA = 0;
            end
        endcase
    end

    MicrocodeController MC(
        .part_of_inst(part_of_inst),
        .alu_bcond(alu_bcond),
        .current_state(current_state),
        .next_state(next_state));

    always @(posedge clk) begin
        if (reset) begin
            current_state <= `IF;
        end
        else begin
            current_state <= next_state;
        end
    end

endmodule

module MicrocodeController (
    input [6:0] part_of_inst,
    input alu_bcond,
    input [3:0] current_state,
    output reg [3:0] next_state);

    always @(*) begin
        case(current_state)
            `IF: next_state = `ID;
            `ID: begin
                case(part_of_inst)
                    `ARITHMETIC: next_state = `EX_R;
                    `ARITHMETIC_IMM: next_state = `AM;
                    `LOAD: next_state = `EX_LDSD;
                    `STORE: next_state = `EX_LDSD;
                    `BRANCH: next_state = `EX_B;
                    `JAL: next_state = `EX_JAL;
                    `JALR: next_state = `EX_JALR;
                    `ECALL: next_state = `EC;
                endcase
            end
            `EX_R: next_state = `MEM_R;
            `EX_LDSD: next_state = (part_of_inst == `LOAD) ? `MEM_LD : `MEM_SD;
            `EX_B: next_state = alu_bcond ? `MEM_B : `IF;
            `EX_JAL: next_state = `IF;
            `EX_JALR: next_state = `IF;
            `MEM_R: next_state = `IF;
            `MEM_LD: next_state = `WB_LD;
            `MEM_SD: next_state = `IF;
            `MEM_B: next_state = `IF;
            `WB_LD: next_state = `IF;
            `AM: next_state = `MEM_R;
            `EC: next_state = `IF;
        endcase
    end

endmodule

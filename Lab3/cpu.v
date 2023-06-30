// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module CPU(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted); // Whehther to finish simulation
  /***** Wire declarations *****/

  // ---------- Wire of PC ----------
  wire [31:0] next_pc;
  wire [31:0] current_pc;
  wire pc_control;  
  // ---------- Wire of Registers ----------
  wire [4:0] rs1;
  wire [4:0] rs2;
  wire [4:0] rd;
  wire [31:0] rd_din;
  wire write_enable;
  wire [31:0] rs1_dout;
  wire [31:0] rs2_dout;
  //---------- Wire of ControlUnit ----------
  wire [6:0] opcode;
  wire IorD;
  wire mem_read;
  wire mem_write;
  wire ALUSrcA;
  wire [1:0] ALUSrcB;
  wire pcWrite;
  wire pcWrite_cond;
  wire [1:0] ALUOp;
  wire PCSource;
  wire mem_to_reg;
  wire is_ecall;
  wire IRWrite;

  //---------- Wire of ImmediateGenerator ----------
  wire [31:0] imm_gen_out;
  //---------- Wire of ALUControlUnit ----------
  wire [2:0] alu_op;
  //---------- Wire of ALU ----------
  wire [31:0] alu_in_1;
  wire [31:0] alu_in_2;
  wire [2:0] funct3;
  wire [31:0] alu_result;
  wire alu_bcond;
  //---------- Wire of Memory ----------
  wire [31:0] mem_addr;
  wire [31:0] dout;

  /***** Register declarations *****/
  reg [31:0] IR; // instruction register
  reg [31:0] MDR; // memory data register
  reg [31:0] A; // Read 1 data register
  reg [31:0] B; // Read 2 data register
  reg [31:0] ALUOut; // ALU output register
  // Do not modify and use registers declared above.

  assign opcode = IR[6:0];
  assign is_halted = (is_ecall && (rs1_dout == 10));
  assign rs1 = is_ecall ? 17 : IR[19:15];
  assign rs2 = IR[24:20];
  assign rd = IR[11:7];
  assign funct3 = IR[14:12];
  assign pc_control = (pcWrite | (pcWrite_cond & !alu_bcond));

  //MUX->assign rd_din = mem_to_reg ? MDR : ALUOut;
  onebitMUX MUX_MemtoReg(
    .inA(MDR),
    .inB(ALUOut),
    .select(mem_to_reg),
    .out(rd_din)
  );
  
  //MUX->assign next_pc = PCSource ? ALUOut : alu_result;
  onebitMUX MUX_PCSource(
    .inA(ALUOut),
    .inB(alu_result),
    .select(PCSource),
    .out(next_pc)
  );

  //MUX->assign mem_addr = IorD ? ALUOut : current_pc;
  onebitMUX MUX_IorD(
    .inA(ALUOut),
    .inB(current_pc),
    .select(IorD),
    .out(mem_addr)
  );
  
  //MUX->assign alu_in_1 = ALUSrcA ? A : current_pc;
  onebitMUX MUX_ALUSrcA(
    .inA(A),
    .inB(current_pc),
    .select(ALUSrcA),
    .out(alu_in_1)
  );

  //MUX->assign alu_in_2 = (ALUSrcB == 0) ? B : ((ALUSrcB == 1) ? 4 : imm_gen_out);
  twobitMUX MUX_ALUSrcB(
    .inA(B),
    .inB(4),
    .inC(imm_gen_out),
    .inD(0),
    .select(ALUSrcB),
    .out(alu_in_2)
  );
  
  //Register Updating
  always @(posedge clk) begin
    if(reset) begin
      IR <= 0;
      MDR <= 0;
      A <= 0;
      B <= 0;
      ALUOut <= 0;
    end
    else begin
      if(IRWrite && (IR!=dout)) begin
        IR <= dout;
      end
      if(MDR!=dout) begin
        MDR <= dout;
      end
      if(A!=rs1_dout) begin
        A<=rs1_dout;
      end
      if(B!=rs2_dout) begin
        B<=rs2_dout;
      end
      if(ALUOut!=alu_result) begin
        ALUOut <= alu_result;
      end
    end
  end

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .pc_control(pc_control),
    .next_pc(next_pc),     // input
    .current_pc(current_pc)   // output
  );

  // ---------- Register File ----------
  RegisterFile reg_file(
    .reset(reset),        // input
    .clk(clk),          // input
    .rs1(rs1),          // input
    .rs2(rs2),          // input
    .rd(rd),           // input
    .rd_din(rd_din),       // input
    .write_enable(write_enable),    // input
    .rs1_dout(rs1_dout),     // output
    .rs2_dout(rs2_dout)      // output
  );

  // ---------- Memory ----------
  Memory memory(
    .reset(reset),        // input
    .clk(clk),          // input
    .addr(mem_addr),         // input
    .din(B),          // input
    .mem_read(mem_read),     // input
    .mem_write(mem_write),    // input
    .dout(dout)          // output
  );

  // ---------- Control Unit ----------
  ControlUnit ctrl_unit(
    .part_of_inst(opcode),  // input
    .clk(clk),
    .reset(reset),
    .alu_bcond(alu_bcond),
    .pcWrite_cond(pcWrite_cond),
    .pcWrite(pcWrite),
    .IorD(IorD),
    .mem_read(mem_read),  // output   
    .mem_write(mem_write),     // output
    .mem_to_reg(mem_to_reg),    // output
    .IRWrite(IRWrite),
    .PCSource(PCSource),
    .ALUOp(ALUOp),
    .ALUSrcB(ALUSrcB),
    .ALUSrcA(ALUSrcA),
    .reg_write(write_enable),
    .is_ecall(is_ecall)       // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .part_of_inst(IR),  // input
    .imm_gen_out(imm_gen_out)    // output
  );

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit(
    .part_of_inst(IR),  // input
    .ALUOp(ALUOp),
    .alu_op(alu_op)         // output
  );

  // ---------- ALU ----------
  ALU alu(
    .alu_op(alu_op),      // input
    .alu_in_1(alu_in_1),    // input  
    .alu_in_2(alu_in_2),    // input
    .funct3(funct3),
    .alu_result(alu_result),  // output
    .alu_bcond(alu_bcond)     // output
  );

endmodule

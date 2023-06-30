// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify modules (except InstMemory, DataMemory, and RegisterFile)
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module CPU(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted); // Whehther to finish simulation
  /***** Wire declarations *****/
  // ---------- Wire of PC ----------
  reg [31:0] next_pc;
  wire [31:0] current_pc;
  // ---------- Wire of InstMemory ----------
  wire [31:0] inst_dout;
  // ---------- Wire of Registers ----------
  wire [4:0] rs1;
  wire [4:0] rs2;
  wire [4:0] rd;
  wire [31:0] rd_din;
  wire [31:0] rs1_dout;
  wire [31:0] rs2_dout;
  wire [4:0] rs1_from_inst;
  //---------- Wire of ControlUnit ----------
  wire MemtoReg;
  wire MemRead;
  wire MemWrite;
  wire ALUSrc;
  wire [1:0] ALUOp;
  wire RegWrite;
  wire is_ecall;
  wire is_jal;
  wire is_jalr;
  wire branch;
  wire pc_to_reg;
  //---------- Wire of ImmediateGenerator ----------
  wire [31:0] imm_gen_out;
  //---------- Wire of ALUControlUnit ----------
  wire [2:0] alu_op;
  //---------- Wire of ALU ----------
  wire [31:0] alu_in_1;
  wire [31:0] alu_in_2;
  wire [31:0] alu_result;
  wire alu_bcond;
  //---------- Wire of DataMemory ----------
  wire [31:0] data_dout;
  //---------- Wire of Data hazard and forward ----------
  wire _is_halted;
  wire is_x17_10;
  wire is_hazard;
  //---------- Wire of Forwarding used in ALU ----------
  wire [1:0] ForwardA;
  wire [1:0] ForwardB;
  wire [31:0] ForwardB_out;
  //---------- Wire of Forwarding used in Register File ----------
  wire [1:0]mux_rs1_dout;
  wire mux_rs2_dout;
  wire [31:0] f_rs1_dout;
  wire [31:0] f_rs2_dout;
  //---------- Wire of Control Flow ----------
  wire is_flush;
  wire [31:0] pc_plus_4;
  wire [31:0] write_data;
  wire [31:0] pc_plus_imm;
  
  /***** Register declarations *****/
  // You need to modify the width of registers
  // In addition, 
  // 1. You might need other pipeline registers that are not described below
  // 2. You might not need registers described below
  /***** IF/ID pipeline registers *****/
  reg [31:0] IF_ID_inst;           // will be used in ID stage
  reg [31:0] IF_ID_pc_plus_4;
  reg [31:0] IF_ID_pc;
  reg IF_ID_is_flush;

  /***** ID/EX pipeline registers *****/
  // From the control unit
  reg [1:0] ID_EX_alu_op;         // will be used in EX stage
  reg ID_EX_alu_src;        // will be used in EX stage
  reg ID_EX_mem_write;      // will be used in MEM stage
  reg ID_EX_mem_read;       // will be used in MEM stage
  reg ID_EX_mem_to_reg;     // will be used in WB stage
  reg ID_EX_reg_write;      // will be used in WB stage
  reg ID_EX_pc_to_reg;      // in WB stage
  // From others
  reg [31:0] ID_EX_rs1_data;
  reg [31:0] ID_EX_rs2_data;
  reg [31:0] ID_EX_imm;
  reg [31:0] ID_EX_inst;
  reg [4:0] ID_EX_rd;
  reg ID_EX_is_halted;
  // For Forwarding
  reg [4:0] ID_EX_rs1;
  reg [4:0] ID_EX_rs2;
  // For control
  reg [31:0] ID_EX_pc_plus_4;
  reg ID_EX_is_jal;
  reg ID_EX_is_jalr;
  reg ID_EX_branch;
  reg [31:0] ID_EX_pc;
  reg [1:0] pc_src;

  /***** EX/MEM pipeline registers *****/
  // From the control unit
  reg EX_MEM_mem_write;     // will be used in MEM stage
  reg EX_MEM_mem_read;      // will be used in MEM stage
  reg EX_MEM_mem_to_reg;    // will be used in WB stage
  reg EX_MEM_reg_write;     // will be used in WB stage
  reg EX_MEM_pc_to_reg;      // in WB stage
  // From others
  reg [31:0] EX_MEM_alu_out;
  reg [31:0] EX_MEM_dmem_data;
  reg [4:0] EX_MEM_rd;
  reg EX_MEM_is_halted;
  // For control
  reg [31:0] EX_MEM_pc_plus_4;

  /***** MEM/WB pipeline registers *****/
  // From the control unit
  reg MEM_WB_mem_to_reg;    // will be used in WB stage
  reg MEM_WB_reg_write;     // will be used in WB stage
  reg MEM_WB_pc_to_reg;      // in WB stage
  // From others
  reg [31:0] MEM_WB_mem_to_reg_src_1;
  reg [31:0] MEM_WB_mem_to_reg_src_2;
  reg [4:0] MEM_WB_rd;
  reg MEM_WB_is_halted;
  // For control
  reg [31:0] MEM_WB_pc_plus_4;

  // assign
  assign pc_plus_4 = current_pc + 4;
  assign rs1_from_inst = IF_ID_inst[19:15];
  assign rs2 = IF_ID_inst[24:20];
  assign rd = MEM_WB_rd;
  assign is_x17_10 = (f_rs1_dout==10)&(rs1==17);
  assign _is_halted = is_ecall & is_x17_10;
  assign is_halted = MEM_WB_is_halted;
  assign is_flush = (pc_src == 2'b01) | (pc_src == 2'b10);

  // ---------- Update program counter ----------
    //mux for pc choosing pc+4 or pc+imm
  // threeSigMUX M4PC(
  //   .inA(pc_plus_4),
  //   .inB(pc_plus_imm),
  //   .inC(alu_result),
  //   .select(pc_src),
  //   .out(next_pc)
  // );

  //always not taken
  always @(*) begin
    if((ID_EX_branch & alu_bcond) | ID_EX_is_jal) begin
      next_pc = ID_EX_imm + ID_EX_pc_plus_4 - 4;
      pc_src = 2'b01;
    end
    else if(ID_EX_is_jalr) begin
      next_pc = alu_result;
      pc_src = 2'b10;
    end
    else begin
      next_pc = pc_plus_4;
      pc_src = 2'b00;
    end
  end

  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .pc_write(!is_hazard),
    .next_pc(next_pc),     // input
    .current_pc(current_pc)   // output
  );

  //PC+immediate
  // Adder pcplusImmAdder(
  //   .inA(ID_EX_pc_plus_4 - 4),
  //   .inB(ID_EX_imm),
  //   .out(pc_plus_imm)
  // );
  
  // ---------- Instruction Memory ----------
  InstMemory imem(
    .reset(reset),   // input
    .clk(clk),     // input
    .addr(current_pc),    // input
    .dout(inst_dout)     // output
  );

  // Update IF/ID pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      IF_ID_inst <= 0;
      IF_ID_pc_plus_4 <= 0;
      IF_ID_is_flush <= 0;
    end
    else if(!is_hazard) begin
      IF_ID_inst <= inst_dout;
      IF_ID_pc_plus_4 <= pc_plus_4;
      IF_ID_is_flush <= is_flush;
    end
  end

  //hazard detection part
  HazardDetectionUnit hDetect(
    .rs1(rs1),
    .rs2(rs2),
    .id_ex_rd(ID_EX_rd),
    .id_ex_opcode(ID_EX_inst[6:0]),
    .id_ex_mem_read(ID_EX_mem_read),
    .ex_mem_rd(EX_MEM_rd),
    .ex_mem_mem_read(EX_MEM_mem_read),
    .is_ecall(is_ecall),
    .is_hazard(is_hazard)
  );

  //ecall mux
  onebitMUX M4_is_ecall(
    .inA(rs1_from_inst),
    .inB(5'd17),
    .select(is_ecall),
    .out(rs1)
  );

  //write data mux
  onebitMUX M4_write_data(
    .inA(rd_din),
    .inB(MEM_WB_pc_plus_4),
    .select(MEM_WB_pc_to_reg),
    .out(write_data)
  );

  // ---------- Register File ----------
  RegisterFile reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (rs1),          // input
    .rs2 (rs2),          // input
    .rd (rd),           // input
    .rd_din (write_data),       // input
    .write_enable (MEM_WB_reg_write),    // input
    .rs1_dout (rs1_dout),     // output
    .rs2_dout (rs2_dout)      // output
  );


  // ---------- Control Unit ----------
  ControlUnit ctrl_unit (
    .part_of_inst(IF_ID_inst[6:0]),  // input
    .mem_read(MemRead),      // output
    .mem_to_reg(MemtoReg),    // output
    .mem_write(MemWrite),     // output
    .alu_src(ALUSrc),       // output
    .reg_write(RegWrite),     // output
    .alu_op(ALUOp),        // output
    .is_jal(is_jal),
    .is_jalr(is_jalr),
    .branch(branch),
    .pc_to_reg(pc_to_reg),
    .is_ecall(is_ecall)       // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .part_of_inst(IF_ID_inst),  // input
    .imm_gen_out(imm_gen_out)    // output
  );

  // Update ID/EX pipeline registers here
  always @(posedge clk) begin
    if (reset | is_hazard | is_flush | IF_ID_is_flush) begin
      ID_EX_alu_op <= 0;         // will be used in EX stage
      ID_EX_alu_src <= 0;        // will be used in EX stage
      ID_EX_mem_write <= 0;      // will be used in MEM stage
      ID_EX_mem_read <= 0;       // will be used in MEM stage
      ID_EX_mem_to_reg <= 0;     // will be used in WB stage
      ID_EX_reg_write <= 0;      // will be used in WB stage
      ID_EX_rs1_data <= 0;
      ID_EX_rs2_data <= 0;
      ID_EX_imm <= 0;
      ID_EX_inst <= 0;
      ID_EX_rd <= 0;
      ID_EX_is_halted <= 0;
      ID_EX_rs1 <= 0;
      ID_EX_rs2 <= 0;
      ID_EX_is_jal <= 0;
      ID_EX_is_jalr <= 0;
      ID_EX_branch <= 0;
      ID_EX_pc_plus_4 <= 0;
      ID_EX_pc_to_reg <= 0;
    end
    else begin
      ID_EX_alu_op <= ALUOp;         // will be used in EX stage
      ID_EX_alu_src <= ALUSrc;        // will be used in EX stage
      ID_EX_mem_write <= MemWrite;      // will be used in MEM stage
      ID_EX_mem_read <= MemRead;       // will be used in MEM stage
      ID_EX_mem_to_reg <= MemtoReg;     // will be used in WB stage
      ID_EX_reg_write <= RegWrite;      // will be used in WB stage
      ID_EX_rs1_data <= f_rs1_dout;
      ID_EX_rs2_data <= f_rs2_dout;
      ID_EX_imm <= imm_gen_out;
      ID_EX_inst <= IF_ID_inst;
      ID_EX_rd <= IF_ID_inst[11:7];
      ID_EX_is_halted <= _is_halted;
      ID_EX_rs1 <= rs1;
      ID_EX_rs2 <= rs2;
      ID_EX_is_jal <= is_jal;
      ID_EX_is_jalr <= is_jalr;
      ID_EX_branch <= branch;
      ID_EX_pc_plus_4 <= IF_ID_pc_plus_4;
      ID_EX_pc_to_reg <= pc_to_reg;
    end
  end

  //Forwarding module
  ForwardingUnit fUnit(
    .rs1(ID_EX_rs1),
    .rs2(ID_EX_rs2),
    .EX_MEM_rd(EX_MEM_rd),
    .EX_MEM_reg_write(EX_MEM_reg_write),
    .MEM_WB_rd(MEM_WB_rd),
    .MEM_WB_reg_write(MEM_WB_reg_write),
    .ForwardA(ForwardA),
    .ForwardB(ForwardB)
  );

  //Mux for mem_to_reg
  onebitMUX M4mem_to_reg(
    .inA(MEM_WB_mem_to_reg_src_2),
    .inB(MEM_WB_mem_to_reg_src_1),
    .select(MEM_WB_mem_to_reg),
    .out(rd_din)
  );

  //Mux for ForwardA
  threeSigMUX muxFA(
    .inA(ID_EX_rs1_data),
    .inB(EX_MEM_pc_to_reg?EX_MEM_pc_plus_4:EX_MEM_alu_out),
    .inC(MEM_WB_pc_to_reg ? MEM_WB_pc_plus_4 : rd_din),
    .select(ForwardA),
    .out(alu_in_1)
  );

  //Mux for ForwardB
  threeSigMUX muxFB(
    .inA(ID_EX_rs2_data),
    .inB(EX_MEM_pc_to_reg?EX_MEM_pc_plus_4:EX_MEM_alu_out),
    .inC(MEM_WB_pc_to_reg ? MEM_WB_pc_plus_4 : rd_din),
    .select(ForwardB),
    .out(ForwardB_out)
  );
  
  //Forwarding for ecall
  ForwardingEcall ForwardEcall(
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .EX_MEM_rd(EX_MEM_rd),
    .is_ecall(is_ecall),
    .rd_din(MEM_WB_pc_to_reg ? MEM_WB_pc_plus_4 : rd_din),
    .rs1_dout(rs1_dout),
    .rs2_dout(rs2_dout),
    .EX_MEM_alu_out(EX_MEM_pc_to_reg?EX_MEM_pc_plus_4:EX_MEM_alu_out),
    .f_rs1_dout(f_rs1_dout),
    .f_rs2_dout(f_rs2_dout)
  );

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit (
    .part_of_inst(ID_EX_inst),  // input
    .ALUOp(ID_EX_alu_op),
    .alu_op(alu_op)         // output
  );

  // ---------- ALU ----------
  ALU alu (
    .alu_op(alu_op),      // input
    .alu_in_1(alu_in_1),    // input  
    .alu_in_2(alu_in_2),    // input
    .funct3(ID_EX_inst[14:12]),
    .alu_result(alu_result),  // output
    .alu_bcond(alu_bcond)
  );

  //mux for alu
  onebitMUX M4alu(
    .inA(ForwardB_out),
    .inB(ID_EX_imm),
    .select(ID_EX_alu_src),
    .out(alu_in_2)
  );

  // Update EX/MEM pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      EX_MEM_mem_write <= 0;
      EX_MEM_mem_read <= 0;
      EX_MEM_mem_to_reg <= 0;
      EX_MEM_reg_write <= 0;
      EX_MEM_alu_out <= 0;
      EX_MEM_dmem_data <= 0;
      EX_MEM_rd <= 0;
      EX_MEM_is_halted <= 0;
      EX_MEM_pc_plus_4 <= 0;
      EX_MEM_pc_to_reg <= 0;
    end
    else begin
      EX_MEM_mem_write <= ID_EX_mem_write;
      EX_MEM_mem_read <= ID_EX_mem_read;
      EX_MEM_mem_to_reg <= ID_EX_mem_to_reg;
      EX_MEM_reg_write <= ID_EX_reg_write;
      EX_MEM_alu_out <= alu_result;
      EX_MEM_dmem_data <= ForwardB_out;
      EX_MEM_rd <= ID_EX_rd;
      EX_MEM_is_halted <= ID_EX_is_halted;
      EX_MEM_pc_plus_4 <= ID_EX_pc_plus_4;
      EX_MEM_pc_to_reg <= ID_EX_pc_to_reg;
    end
  end

  // ---------- Data Memory ----------
  DataMemory dmem(
    .reset (reset),      // input
    .clk (clk),        // input
    .addr (EX_MEM_alu_out),       // input
    .din (EX_MEM_dmem_data),        // input
    .mem_read (EX_MEM_mem_read),   // input
    .mem_write (EX_MEM_mem_write),  // input
    .dout (data_dout)        // output
  );

  // Update MEM/WB pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      MEM_WB_mem_to_reg <= 0;
      MEM_WB_reg_write <= 0;
      MEM_WB_mem_to_reg_src_1 <= 0;
      MEM_WB_mem_to_reg_src_2 <= 0;
      MEM_WB_is_halted <= 0;
      MEM_WB_rd <= 0;
      MEM_WB_pc_plus_4 <= 0;
      MEM_WB_pc_to_reg <= 0;
    end
    else begin
      MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;
      MEM_WB_reg_write <= EX_MEM_reg_write;
      MEM_WB_mem_to_reg_src_1 <= data_dout;
      MEM_WB_mem_to_reg_src_2 <= EX_MEM_alu_out;
      MEM_WB_is_halted <= EX_MEM_is_halted;
      MEM_WB_rd <= EX_MEM_rd;
      MEM_WB_pc_plus_4 <= EX_MEM_pc_plus_4;
      MEM_WB_pc_to_reg <= EX_MEM_pc_to_reg;
    end
  end

endmodule
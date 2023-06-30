`include "CLOG2.v"

`define Idle            2'b00
`define CompareTag      2'b01
`define Allocate        2'b10
`define WriteBack       2'b11

//Cache module
module Cache #(parameter LINE_SIZE = 16,
               parameter NUM_SETS = 16,
               parameter NUM_WAYS = 1) (
    input reset,
    input clk,

    input is_input_valid,
    input [31:0] addr,
    input mem_read,
    input mem_write,
    input [31:0] din,

    output is_ready,
    output is_output_valid,
    output reg [31:0] dout,
    output reg is_hit);
  
  // Wire declarations
  wire is_data_mem_ready;   // is data memory ready to accept request?
  wire [31:0] clog2;        // log2 of LINE_SIZE
  wire [127:0] data_dout;   // data memory output
  wire memory_output_valid; // is output from the data memory valid?

  // Reg declarations
  reg [1:0] bo;   // block offset
  reg [3:0] idx;  // index
  reg [23:0] tag; // tag

  reg [1:0] current_state;
  reg [1:0] next_state;

  reg [127:0] write_to_data;
  reg [23:0] write_to_tag;
  reg write_to_valid;
  reg write_to_dirty;

  reg save_data;
  reg save_tag;

  reg [31:0] memory_addr;
  reg [127:0] memory_din;
  reg memory_input_valid;
  reg memory_read;
  reg memory_write;

  // Reg for Data Bank, Tag Bank
  reg [9:0] i;
  reg [127:0] data_bank [0:15];
  reg [23:0] tag_bank [0:15];
  reg valid_table [0:15];
  reg dirty_table [0:15];

  // Counter for hit and miss
  reg [31:0] count_request;
  reg [31:0] count_miss;
  
  assign clog2 = `CLOG2(LINE_SIZE);   //Do not solve bug that why I have to assign this value
  // assign of output
  assign is_ready = is_data_mem_ready;
  assign is_output_valid = (next_state == `Idle);

  // Logic for Cache
  always @(*) begin
    bo = addr[3:2];
    idx = addr[7:4];
    tag = addr[31:8];
  end

  // Logic for Data Bank, Tag Bank
  always @(posedge clk) begin
    if(reset) begin
      for(i = 0; i < 16; i = i + 1) begin
        data_bank[i] = 0;
        tag_bank[i] = 0;
        valid_table[i] = 0;
        dirty_table[i] = 0;
      end
    end
    else begin
      if(save_data) begin
        data_bank[idx] <= write_to_data;
      end
      if(save_tag) begin
        tag_bank[idx] <= write_to_tag;
        valid_table[idx] <= write_to_valid;
        dirty_table[idx] <= write_to_dirty;
      end
    end
  end

  always @(*) begin
    dout = 0;
    write_to_data = data_bank[idx];
    write_to_tag = 0;
    write_to_valid = 0;
    write_to_dirty = 0;

    save_data = 0;
    save_tag = 0;
    memory_input_valid = 0;

    case (bo)    // block offset 확인 (block offset은 2'b00이면 0~31, 2'b01이면 32~63, 2'b10이면 64~95, 2'b11이면 96~127)
      `Idle: begin
        write_to_data[31:0] = din;
        dout = data_bank[idx][31:0];
      end
      `CompareTag: begin
        write_to_data[63:32] = din;
        dout = data_bank[idx][63:32];
      end
      `Allocate: begin
        write_to_data[95:64] = din;
        dout = data_bank[idx][95:64];
      end
      `WriteBack: begin
        write_to_data[127:96] = din;
        dout = data_bank[idx][127:96];
      end
    endcase

    // state transition logic 부분 (next_state 결정)
    case (current_state)
      `Idle: begin
        if (is_input_valid) begin
          next_state = `CompareTag;
        end
        else begin
          next_state = `Idle;
        end
      end
      `CompareTag: begin
        if ((tag == tag_bank[idx]) && (valid_table[idx] == 1)) begin
          is_hit = 1;
          count_request = count_request + 1;
          if (mem_write) begin
            save_data = 1;
            save_tag = 1;
            write_to_tag = tag_bank[idx];
            write_to_valid = 1;
            write_to_dirty = 1;
          end
          next_state = `Idle;
        end
        else begin
          save_tag = 1;
          write_to_tag = tag;
          write_to_valid = 1;
          write_to_dirty = mem_write;

          memory_input_valid = 1;
          count_miss = count_miss + 1;

          if (!valid_table[idx] || !dirty_table[idx]) begin
            memory_addr = addr;
            memory_read = 1;
            memory_write = 0;
            next_state = `Allocate;
          end
          else begin
            memory_addr = {tag_bank[idx], idx, 4'b0000};
            memory_din = data_bank[idx];
            memory_read = 0;
            memory_write = 1;
            next_state = `WriteBack;
          end
        end
      end
      `Allocate: begin
        if (memory_output_valid) begin
          write_to_data = data_dout;
          save_data = 1;
          memory_input_valid = 0;
          next_state = `CompareTag;
        end
      end
      `WriteBack: begin
        if (is_data_mem_ready) begin
          memory_addr = addr;
          memory_read = 1;
          memory_write = 0;
          memory_input_valid = 1;
          next_state = `Allocate;
        end
      end
    endcase
  end

  always @(posedge clk) begin
    if(reset) begin
      current_state <= `Idle;
      count_request <= 0;
      count_miss <= 0;
    end
    else begin
      current_state <= next_state;
      $monitor("request = %d, miss = %d", count_request, count_miss);
    end
  end

  // Instantiate data memory
  DataMemory #(.BLOCK_SIZE(LINE_SIZE)) data_mem(
    .reset(reset),
    .clk(clk),

    .is_input_valid(memory_input_valid),
    .addr(memory_addr >> clog2),        // NOTE: address must be shifted by CLOG2(LINE_SIZE)
    .mem_read(memory_read),
    .mem_write(memory_write),
    .din(memory_din),

    // is output from the data memory valid?
    .is_output_valid(memory_output_valid),
    .dout(data_dout),
    // is data memory ready to accept request?
    .mem_ready(is_data_mem_ready)
  );

endmodule


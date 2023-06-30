//Adder module for PC+4
module Adder(input [31:0] inA,
             input [31:0] inB,
             output[31:0] out);
  assign out = inA + inB;
endmodule

//Mux Module(1 bit)
module onebitMUX(input [31:0] inA,
                 input [31:0] inB,
                 input select,
                 output [31:0] out);
  assign out = select ? inB : inA;
endmodule

//Mux Module(3 signals)
module threeSigMUX(input [31:0] inA,
                  input [31:0] inB,
                  input [31:0] inC,
                  input [1:0] select,
                  output reg [31:0] out);
  always @(*) begin
    case(select)
      2'b00: begin
        out = inA;
      end
      2'b01: begin
        out = inB;
      end
      2'b10: begin
        out = inC;
      end
    endcase
  end
endmodule

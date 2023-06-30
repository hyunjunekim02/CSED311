module ALU #(parameter data_width = 16) (
	input [data_width - 1 : 0] A, 
	input [data_width - 1 : 0] B, 
	input [3 : 0] FuncCode,
       	output reg [data_width - 1: 0] C,
       	output reg OverflowFlag);
// Do not use delay in your implementation.

// You can declare any variables as needed.
/*
	YOUR VARIABLE DECLARATION...
*/

initial begin
	C = 0;
	OverflowFlag = 0;
end   	

// TODO: You should implement the functionality of ALU!
// (HINT: Use 'always @(...) begin ... end')
/*
	YOUR ALU FUNCTIONALITY IMPLEMENTATION...
*/

always @* begin
	case (FuncCode)
		`FUNC_ADD: begin // Addition
			C = A + B;
			OverflowFlag = (C[data_width-1] != A[data_width-1] && C[data_width-1] != B[data_width-1]);
		end
		`FUNC_SUB: begin // Subtraction
			C = A - B;
			OverflowFlag = (C[data_width-1] != A[data_width-1] && C[data_width-1] == B[data_width-1]);
		end
		`FUNC_ID: begin // Identity (No operation)
			C = A;
			OverflowFlag = 0;
		end
		`FUNC_NOT: begin // Bitwise NOT
			C = ~A;
			OverflowFlag = 0;
		end
		`FUNC_AND: begin // Bitwise AND
			C = A & B;
			OverflowFlag = 0;
		end
		`FUNC_OR: begin // Bitwise OR
			C = A | B;
			OverflowFlag = 0;
		end
		`FUNC_NAND: begin // Bitwise NAND
			C = ~(A & B);
			OverflowFlag = 0;
		end
		`FUNC_NOR: begin // Bitwise NOR
			C = ~(A | B);
			OverflowFlag = 0;
		end
		`FUNC_XOR: begin // Bitwise XOR
			C = A ^ B;
			OverflowFlag = 0;
		end
		`FUNC_XNOR: begin // Bitwise XNOR
			C = ~(A ^ B);
			OverflowFlag = 0;
		end
		`FUNC_LLS: begin // Logical left shift
			C = A << 1;
			OverflowFlag = 0;
		end
		`FUNC_LRS: begin // Logical right shift
			C = A >> 1;
			OverflowFlag = 0;
		end
		`FUNC_ALS: begin // Arithmetic left shift
			C = A << 1;
			OverflowFlag = 0;
		end
		`FUNC_ARS: begin // Arithmetic right shift
			C = A >> 1;
			C[data_width - 1] = A[data_width - 1];
			OverflowFlag = 0;
		end
		`FUNC_TCP: begin // Two's complement
			C = ~A + 1;
			OverflowFlag = 0;
		end
		`FUNC_ZERO: begin // Zero
			C = 0;
			OverflowFlag = 0;
		end
		default: begin // Else case
			C = 0;
			OverflowFlag = 0;
		end
	endcase
end


endmodule

// vending_mackine_def.v
`define kTotalBits 31
  
`define kItemBits 8
`define kNumItems 4

`define kCoinBits 8
`define kNumCoins 3

`define kWaitTime 100


// vending_machine.v
`include "vending_machine_def.v"


module vending_machine (
	clk,							// Clock signal
	reset_n,						// Reset signal (active-low)

	i_input_coin,				// coin is inserted.
	i_select_item,				// item is selected.
	i_trigger_return,			// change-return is triggered 

	o_available_item,			// Sign of the item availability
	o_output_item,			// Sign of the item withdrawal
	o_return_coin				// Sign of the coin return
);

	// Ports Declaration
	// Do not modify the module interface
	input clk;
	input reset_n;
	
	input [`kNumCoins-1:0] i_input_coin;
	input [`kNumItems-1:0] i_select_item;
	input i_trigger_return;
		
	output [`kNumItems-1:0] o_available_item;
	output [`kNumItems-1:0] o_output_item;
	output [`kNumCoins-1:0] o_return_coin;


	

	// Do not modify the values.
	wire [31:0] item_price [`kNumItems-1:0];	// Price of each item
	wire [31:0] coin_value [`kNumCoins-1:0];	// Value of each coin
	assign item_price[0] = 400;
	assign item_price[1] = 500;
	assign item_price[2] = 1000;
	assign item_price[3] = 2000;
	assign coin_value[0] = 100;
	assign coin_value[1] = 500;
	assign coin_value[2] = 1000;

	// Internal states. You may add your own net variables.
	wire [`kTotalBits-1:0] current_total;
	
	// Next internal states. You may add your own net variables.
	wire [`kTotalBits-1:0] current_total_nxt;

	
	// Variables. You may add more your own net variables.
	wire [`kTotalBits-1:0] input_total, output_total, return_total;
	wire [31:0] wait_time;


	// This module interface, structure, and given a number of modules are not mandatory but recommended.
	// However, Implementations that use modules are mandatory.
		
  	check_time_and_coin check_time_and_coin_module(.i_input_coin(i_input_coin),
  									.i_select_item(i_select_item),
									.i_trigger_return(i_trigger_return),
									.clk(clk),
									.reset_n(reset_n),
									.current_total(current_total),
									.item_price(item_price),
									.coin_value(coin_value),
									.wait_time(wait_time),
									.o_return_coin(o_return_coin));

	calculate_current_state calculate_current_state_module(.i_input_coin(i_input_coin),
										.i_select_item(i_select_item),
										.item_price(item_price),
										.coin_value(coin_value),
										.current_total(current_total),
										.input_total(input_total),
										.output_total(output_total),
										.return_total(return_total),
										.current_total_nxt(current_total_nxt),
										.wait_time(wait_time),
										.o_return_coin(o_return_coin),
										.o_available_item(o_available_item),
										.o_output_item(o_output_item));
	
  	change_state change_state_module(
						.clk(clk),
						.reset_n(reset_n),
						.current_total_nxt(current_total_nxt),
						.current_total(current_total));


endmodule


	
// check_time_and_coin.v
module check_time_and_coin(i_input_coin,i_select_item,i_trigger_return,clk,reset_n,current_total,item_price,coin_value,wait_time,o_return_coin);
	input clk;
	input reset_n;
	input i_trigger_return;
	input [`kNumCoins-1:0] i_input_coin;
	input [`kNumItems-1:0] i_select_item;
	input [`kTotalBits-1:0] current_total;
	input [31:0] item_price [`kNumItems-1:0];
	input [31:0] coin_value [`kNumCoins-1:0];
	output reg [`kNumCoins-1:0] o_return_coin;
	output reg [31:0] wait_time;

	// initiate values
	initial begin
		// TODO: initiate values
	end


	// update coin return time
	always @(i_input_coin, i_select_item) begin
		// TODO: update coin return time
		
	end

	always @(*) begin
		// TODO: o_return_coin
	end

	always @(posedge clk ) begin
		if (!reset_n) begin
		// TODO: reset all states.
		end
		else begin
		// TODO: update all states.
		end
	end
endmodule 


// calculate_current_state.v

`include "vending_machine_def.v"
	

module calculate_current_state(i_input_coin,i_select_item,item_price,coin_value,current_total,
input_total, output_total, return_total,current_total_nxt,wait_time,o_return_coin,o_available_item,o_output_item);


	input [`kNumCoins-1:0] i_input_coin,o_return_coin;
	input [`kNumItems-1:0]	i_select_item;			
	input [31:0] item_price [`kNumItems-1:0];
	input [31:0] coin_value [`kNumCoins-1:0];	
	input [`kTotalBits-1:0] current_total;
	input [31:0] wait_time;
	output reg [`kNumItems-1:0] o_available_item,o_output_item;
	output reg  [`kTotalBits-1:0] input_total, output_total, return_total,current_total_nxt;
	integer i;	


	
	// Combinational logic for the next states
	always @(*) begin
		// TODO: current_total_nxt
		// You don't have to worry about concurrent activations in each input vector (or array).
		// Calculate the next current_total state.
		input_total = 0;
		output_total = 0;
		return_total = 0;
		current_total_nxt = 0;

		for(i=0; i<`kNumCoins; i=i+1) begin
			if (i_input_coin[i]) begin
				input_total = input_total + coin_value[i];
			end
			if (o_return_coin[i]) begin
				return_total = return_total + coin_value[i];
			end
		end

		for(i=0; i<`kNumItems; i=i+1) begin
			if (i_select_item[i] && item_price[i] <= current_total) begin
				output_total = output_total + item_price[i];
			end
		end
		
		current_total_nxt = current_total + input_total - output_total - return_total;
	end

	
	
	// Combinational logic for the outputs
	always @(*) begin
		// TODO: o_available_item
		// TODO: o_output_item
		o_available_item = 0;
		o_output_item = 0;

		for(i=0; i<`kNumItems; i=i+1) begin
			if (item_price[i] <= current_total) begin
				o_available_item[i] = 1;
			end
			if (o_available_item[i] & i_select_item[i]) begin
				o_output_item[i] = 1;
			end
		end
	end
endmodule


// change_state.v
`include "vending_machine_def.v"

module change_state(clk,reset_n,current_total_nxt,current_total);

	input clk;
	input reset_n;
	input [`kTotalBits-1:0] current_total_nxt;
	output reg [`kTotalBits-1:0] current_total;
	
	// Sequential circuit to reset or update the states
	always @(posedge clk ) begin
		if (!reset_n) begin
			// TODO: reset all states.
			current_total <= 0;
		end
		else begin
			// TODO: update all states.
			current_total <= current_total_nxt;
		end
	end
endmodule 
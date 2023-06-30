`include "vending_machine_def.v"

	

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
		wait_time = 0;
	end


	// update coin return time
	always @(i_input_coin, i_select_item) begin
		// TODO: update coin return time
		if (i_input_coin || i_select_item) begin
			wait_time = `kWaitTime;
		end
	end

	always @(*) begin
		// TODO: o_return_coin
		o_return_coin <= 0;
		if(i_trigger_return || wait_time == 0) begin
			if(current_total/1000 > 0) begin
				o_return_coin[2] <= 1;
			end
			else if((current_total%1000)/500 > 0) begin
				o_return_coin[1] <= 1;
			end
			else if((current_total%500)/100 > 0) begin
				o_return_coin[0] <= 1;
			end
		end
	end

	always @(posedge clk ) begin
		if (!reset_n) begin
		// TODO: reset all states.
			o_return_coin <= 0;
			wait_time <= 0;
		end
		else begin
		// TODO: update all states.
			if (wait_time > 0) begin
				wait_time <= wait_time - 1;
			end
		end
	end
endmodule 

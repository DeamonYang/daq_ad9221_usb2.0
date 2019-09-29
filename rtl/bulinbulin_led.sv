`timescale 1ns/1ps
module bulinbulin_led(
	input	logic		rst_n_i,
	input	logic		clk_i,
	input	logic		ft_clk_i,
	output	logic[1:0]	led
);
	
	reg[23:0]	cnt[1:0];
	
	assign led = {cnt[0][23],cnt[1][23]};

	always_ff@(posedge clk_i or negedge rst_n_i)
	if(!rst_n_i)
		cnt[0] <= 'd0;
	else
		cnt[0] <= cnt[0] + 1'b1;
		
	always_ff@(posedge ft_clk_i or negedge rst_n_i)
	if(!rst_n_i)
		cnt[1] <= 'd0;
	else
		cnt[1] <= cnt[1] + 1'b1;
		
endmodule

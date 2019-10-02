`timescale 1ns/1ps

module ad9221(
	input	logic		rst_n_i,
	input	logic		clk_i,
	input	logic[11:0]	ad_bus_i,

	output	logic		clk_o,
	output	logic[11:0]	ad_data_o
);
	assign clk_o = clk_i;
	
	always_ff@(posedge clk_i or negedge rst_n_i)
	if(!rst_n_i)
		ad_data_o <= 12'd0;
	else
		ad_data_o <= {	ad_bus_i[0],
						ad_bus_i[1],
						ad_bus_i[2],
						ad_bus_i[3],
						ad_bus_i[4],
						ad_bus_i[5],
						ad_bus_i[6],
						ad_bus_i[7],
						ad_bus_i[8],
						ad_bus_i[9],
						ad_bus_i[10],
						ad_bus_i[11]};

endmodule

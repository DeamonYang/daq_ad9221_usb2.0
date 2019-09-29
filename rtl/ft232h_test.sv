`timescale 1ns/1ps

module ft232h_test(
	input	logic			rst_n_i,
	input	logic 			clk_i,
			
	input	logic			ft_clk_i,//60MHz
	input	logic			ft_rxf_i,//When high, do not read data from the FIFO
	input	logic			ft_txe_i,//When high, do not write data into the FIFO
	
	output	logic[7:0]		ft_adbus_o,
	output	logic			ft_rd_o,
	output	logic			ft_wr_o,
	output	logic			ft_usrst,
	output	logic			ft_pwrsav,
	
	/*Output enable when low to drive data onto D0-7. 
	This should be driven low at least 1 clock period before 
	driving RD# low to allow for data buffer turn-around. */
	output	logic			ft_oe_o,
	// Tie this pin to VCCIO if not used. 
	output	logic			ft_siwu_o,
	
	output	logic[2:0]		led
);

	logic			ft_shift_clk;
	logic			adc_clk;
	logic	[11:0]	ad_data;
	logic			fifo_full;
	logic 			fifo_empty;
	
	logic	[11:0]	fifo_test_data;
	logic 			cnt_en;
	logic			send_en;
	logic	[11:0]	tim_cnt;
	
	

	assign ft_siwu_o = 1'b1;
	assign led[2] = ft_txe_i;
	assign ft_usrst = 1'b1;
	assign ft_pwrsav = 1'b1;
	
	assign cnt_en = (~ft_txe_i) & (~ft_wr_o);

	always_ff@(posedge ft_shift_clk or negedge rst_n_i)
	if(!rst_n_i)
		ft_adbus_o <= 8'd0;
	else if(cnt_en  )
		ft_adbus_o <= ft_adbus_o + 1'b1;
	
	always_ff@(posedge ft_shift_clk or negedge rst_n_i)
	if(!rst_n_i)
		ft_wr_o <= 1'b1;
	else if((!ft_txe_i)&send_en )
		ft_wr_o <= 1'b0;
	else
		ft_wr_o <= 1'b1;

	always_ff@(posedge ft_shift_clk or negedge rst_n_i)
	if(!rst_n_i)
		send_en <= 1'b0;
	else if(tim_cnt == 8'h5a)
		send_en <= ~send_en;
	
	always_ff@(posedge ft_shift_clk or negedge rst_n_i)
	if(!rst_n_i)
		tim_cnt <= 8'd0;
	else
		tim_cnt <= tim_cnt + 1'b1;
	
	
	usb_data_pll pll_u0(
		.inclk0	(ft_clk_i),
		.c0		(ft_shift_clk));
	
	pll_adc pll_adc_u0(
		.inclk0	(clk_i),
		.c0		(adc_clk));
	
	
	bulinbulin_led bulinbulin_led_u0(
		.rst_n_i	(rst_n_i),
		.clk_i		(clk_i),
		.ft_clk_i	(ft_clk_i),
		.led		(led[1:0]));	

endmodule

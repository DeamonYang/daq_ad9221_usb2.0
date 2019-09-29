`timescale 1ns/1ps

module daq_sys(
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
	
	output	logic[2:0]		led,
	
	/*adc data bus*/
	input	logic[11:0]		ad_db_i,
	input	logic			ad_otr_i,
	output	logic			ad_clk_o
	
);

	logic			ft_shift_clk;
	logic			adc_clk;
	logic	[11:0]	ad_data;
	logic			fifo_full;
	logic 			fifo_empty;
	
	logic	[11:0]	fifo_test_data;
	
	

	assign ft_siwu_o = 1'b1;
	//assign led[2] = ft_txe_i;
	assign ft_usrst = 1'b1;
	assign ft_pwrsav = 1'b1;
	
	
	always_ff@(posedge adc_clk or negedge rst_n_i)
	if(!rst_n_i)
		led[2] <= 1'b0;
	else if(fifo_full)
		led[2] <= ~led[2];
		
	
	
	always_ff@(posedge ft_shift_clk or negedge rst_n_i)
	if(!rst_n_i)
		ft_wr_o <= 1'b1;
	else if((!ft_txe_i) & (!fifo_empty))
		ft_wr_o <= 1'b0;
	else
		ft_wr_o <= 1'b1;
	
	
	always_ff@(posedge adc_clk or negedge rst_n_i)
	if(!rst_n_i)
		fifo_test_data <= 'd0;
	else if(~fifo_full)
		fifo_test_data <= fifo_test_data + 1'b1;
	
	
	async_fifo	async_fifo_inst (
		//.data 		( {4'd0,ad_data}),
		.data 		( {fifo_test_data[7:0],fifo_test_data[7:0]}),
		.rdclk 		( ft_shift_clk 	),
		.rdreq 		( (~ft_txe_i)&(~fifo_empty)),
		.wrclk 		( adc_clk 		),
		.wrreq 		( ~fifo_full	),
		.q 			( ft_adbus_o 	),
		.rdempty 	( fifo_empty 	),
		.wrfull 	( fifo_full 	)
		);
	
	ad9221(
		.rst_n_i	(rst_n_i),
		.clk_i		(adc_clk),
		.ad_bus_i	(ad_db_i),
		.clk_o		(ad_clk_o),
		.ad_data_o	(ad_data));
	
	
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

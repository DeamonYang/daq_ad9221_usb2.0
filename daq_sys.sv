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
	logic	[7:0]	fifo_data;
	
	assign led[2] = fifo_full;
	
	ft232h_send_data ft232h_send_data_inst_u0(
		.rst_n_i		(rst_n_i		),
		.clk_i			(clk_i			),	
		.ft_shift_clk	(ft_clk_i	),//60MHz
		.ft_rxf_i		(ft_rxf_i		),//When high, do not read data from the FIFO
		.ft_txe_i		(ft_txe_i		),//When high, do not write data into the FIFO
		.ft_adbus_o		(ft_adbus_o		),
		.ft_rd_o		(ft_rd_o		),
		.ft_wr_o		(ft_wr_o		),
		.ft_usrst		(ft_usrst		),
		.ft_pwrsav		(ft_pwrsav		),
		.ft_oe_o		(ft_oe_o		),
		.ft_siwu_o		(ft_siwu_o		),
		.fifo_data		(fifo_data		),
		.fifo_empty		(fifo_empty		) 
	);
	
	reg r_fifo_empty;
	
	async_fifo	async_fifo_inst (
//		.data 		( {4'd0,ad_data}),
		.data 		( {4'd0,12'h123}),
//		.data 		( {fifo_test_data[7:0],fifo_test_data[7:0]}),
		.rdclk 		( ft_clk_i 	),
		.rdreq 		( (~ft_txe_i)&(~fifo_empty)),
		.wrclk 		( adc_clk 		),
		.wrreq 		( ~fifo_full	),
		.q 			( fifo_data 	),
		.rdempty 	( fifo_empty 	),
		.wrfull 	( fifo_full 	)
		);
		
	
	ad9221 ad9221_u0(
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

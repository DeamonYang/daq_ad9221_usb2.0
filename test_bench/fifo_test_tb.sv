`timescale 1ns/1ps

module fifo_test_tb;

	logic[15:0]	fifo_test_data;
	logic 		ft_shift_clk;
	logic 		adc_clk;
	logic 		ft_txe_i;
	logic 		fifo_empty;
	logic[7:0]	ft_adbus_o;
	logic 		fifo_full;
	logic 		rst_n;
	
	
	async_fifo	async_fifo_inst (
		.data 		( fifo_test_data),
		.rdclk 		( ft_shift_clk 	),
		.rdreq 		( (~ft_txe_i)&(~fifo_empty)),
		.wrclk 		( adc_clk 		),
		.wrreq 		( ~fifo_full	),
		.q 			( ft_adbus_o 	),
		.rdempty 	( fifo_empty 	),
		.wrfull 	( fifo_full 	)
		);

	initial begin
		ft_shift_clk = 0;
		adc_clk = 0;
		rst_n = 0;
		ft_txe_i = 1;
		repeat(100)@(posedge adc_clk);
		rst_n = 1;
		repeat(10)@(posedge adc_clk);
		
		ft_txe_i = 0;
		repeat(100)@(posedge adc_clk);
		
		ft_txe_i = 1;
		repeat(100)@(posedge adc_clk);
		
		ft_txe_i = 0;
		repeat(100)@(posedge adc_clk);		
		
		$stop;
		
	end

	always@(posedge adc_clk or negedge rst_n)
	if(!rst_n)
		fifo_test_data <= 'd0;
	else
		fifo_test_data <= fifo_test_data + 1'b1;
	
	
	always #10 ft_shift_clk = ~ft_shift_clk;
	always #66 adc_clk = ~adc_clk;
	
endmodule

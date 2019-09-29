`timescale 1ns/1ps

module ft232h_send_data(
	input	logic			rst_n_i,
	input	logic 			clk_i,
			
	input	logic			ft_shift_clk,//60MHz
	input	logic			ft_rxf_i,//When high, do not read data from the FIFO
	input	logic			ft_txe_i,//When high, do not write data into the FIFO
	output	logic[7:0]		ft_adbus_o,
	output	logic			ft_rd_o,
	output	logic			ft_wr_o,
	output	logic			ft_usrst,
	output	logic			ft_pwrsav,
	output	logic			ft_oe_o,
	output	logic			ft_siwu_o,
	
	/*data_bus*/
	input	logic[7:0]		fifo_data,
	input	logic			fifo_empty
	);

	assign ft_adbus_o = fifo_data;
	
	assign ft_siwu_o = 1'b1;
	assign ft_usrst = 1'b1;
	assign ft_pwrsav = 1'b1;
	
	
	always_ff@(posedge ft_shift_clk or negedge rst_n_i)
	if(!rst_n_i)
		ft_wr_o <= 1'b1;
	else if((!ft_txe_i) & (!fifo_empty))
		ft_wr_o <= 1'b0;
	else
		ft_wr_o <= 1'b1;
	

endmodule


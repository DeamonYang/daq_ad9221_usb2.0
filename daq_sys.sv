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
	output	logic			ad_clk_o,
	
	/*sdram interface*/
    output 	logic       	sdram_clk,                //SDRAM 芯片时钟
    output 	logic       	sdram_cke,                //SDRAM 时钟有效
    output 	logic       	sdram_cs_n,               //SDRAM 片选
    output 	logic       	sdram_ras_n,              //SDRAM 行有效
    output 	logic       	sdram_cas_n,              //SDRAM 列有效
    output 	logic       	sdram_we_n,               //SDRAM 写有效
    output 	logic[ 1:0] 	sdram_ba,                 //SDRAM Bank地址
    output 	logic[12:0] 	sdram_addr,               //SDRAM 行/列地址
    inout  	wire [15:0] 	sdram_data,               //SDRAM 数据
    output 	logic[ 1:0] 	sdram_dqm                //SDRAM 数据掩码	
	
);

	logic			ft_shift_clk;
	logic			adc_clk;
	logic	[11:0]	ad_data;
	logic			fifo_full;
	logic 			fifo_empty;
	
	logic	[11:0]	fifo_test_data;
	logic	[7:0]	fifo_data;
	
	logic 			sys_rst_n;
	logic			pll_locked;
	
	logic			clk_50m;
	logic			clk_100m;
	logic 			clk_100m_shift;
	
	logic	[15:0]	sdram_rd_data;
	logic			sdram_init_done;
	logic			sdram_wrf_full ;
	logic			sdram_rdf_empty;
	
	assign sys_rst_n = rst_n_i & pll_locked;
	
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
	
	async_fifo	async_fifo_inst (
//		.data 		( {4'd0,ad_data}),
		.data 		( sdram_rd_data),
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
	
	
	
	//SDRAM 控制器顶层模块,封装成FIFO接口
//SDRAM 控制器地址组成: {bank_addr[1:0],row_addr[12:0],col_addr[8:0]}
sdram_top u_sdram_top(
	.ref_clk			(clk_100m),			//sdram	控制器参考时钟
	.out_clk			(clk_100m_shift),	//用于输出的相位偏移时钟
	.rst_n				(sys_rst_n),		//系统复位
    
    //用户写端口
	.wr_clk 			(adc_clk),		    //写端口FIFO: 写时钟
	.wr_en				((~sdram_wrf_full)&(sys_rst_n)),			//写端口FIFO: 写使能
	.wr_data		    ({4'd0,ad_data}),		    //写端口FIFO: 写数据
	.wr_min_addr		(24'd0),			//写SDRAM的起始地址
	.wr_max_addr		(24'h8FFFFF),		    //写SDRAM的结束地址
	.wr_len			    (10'd512),			//写SDRAM时的数据突发长度
	.wr_load			(~sys_rst_n),		//写端口复位: 复位写地址,清空写FIFO
	
	.wrf_full			(sdram_wrf_full ),
    .rdf_empty			(sdram_rdf_empty), 	
   
    //用户读端口
	.rd_clk 			(ft_clk_i),			//读端口FIFO: 读时钟
    .rd_en				(~sdram_rdf_empty),			//读端口FIFO: 读使能
	.rd_data	    	(sdram_rd_data),		    //读端口FIFO: 读数据
	.rd_min_addr		(24'd0),			//读SDRAM的起始地址
	.rd_max_addr		(24'h8FFFFF),	    //读SDRAM的结束地址
	.rd_len 			(10'd512),			//从SDRAM中读数据时的突发长度
	.rd_load			(~sys_rst_n),		//读端口复位: 复位读地址,清空读FIFO
	   
     //用户控制端口  
	.sdram_read_valid	(1'b1),             //SDRAM 读使能
	.sdram_init_done	(sdram_init_done),	//SDRAM 初始化完成标志
   
	//SDRAM 芯片接口
	.sdram_clk			(sdram_clk),        //SDRAM 芯片时钟
	.sdram_cke			(sdram_cke),        //SDRAM 时钟有效
	.sdram_cs_n			(sdram_cs_n),       //SDRAM 片选
	.sdram_ras_n		(sdram_ras_n),      //SDRAM 行有效
	.sdram_cas_n		(sdram_cas_n),      //SDRAM 列有效
	.sdram_we_n			(sdram_we_n),       //SDRAM 写有效
	.sdram_ba			(sdram_ba),         //SDRAM Bank地址
	.sdram_addr			(sdram_addr),       //SDRAM 行/列地址 
	.sdram_data			(sdram_data),       //SDRAM 数据
	.sdram_dqm			(sdram_dqm)         //SDRAM 数据掩码
	);
	
	
	pll_adc pll_adc_u0(	
		.areset ( ~rst_n_i ),
		.inclk0 ( clk_i ),
		.c0 ( adc_clk ),
		.c1 ( clk_50m ),
		.c2 ( clk_100m ),
		.c3 ( clk_100m_shift ),
		.locked ( pll_locked ));
		
	
	bulinbulin_led bulinbulin_led_u0(
		.rst_n_i	(rst_n_i),
		.clk_i		(clk_i),
		.ft_clk_i	(ft_clk_i),
		.led		(led[1:0]));

endmodule

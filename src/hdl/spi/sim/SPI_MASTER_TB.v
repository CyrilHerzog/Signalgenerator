
`timescale 10ns / 1ns

// sending / resceiving 2 bytes 

module SPI_MASTER_TB;

reg sim_clk, sim_rst;
reg sim_en, bit1;
reg[7:0] sim_len;
reg[15:0] sim_dtx, sim_drx;
wire[15:0] net_drx;
wire net_sclk, net_sdo, net_ss, net_done, sim_sdi;





initial 
	begin
	sim_clk = 1'b0;
	forever
		#1 sim_clk = ~sim_clk;
	end	



// Dumpfile und Dumpvars für GtkWave
initial begin
    $dumpfile("sim/icarus/spi.vcd");
    $dumpvars(0, SPI_MASTER_TB);
end


initial
	begin
	#0   
		sim_rst = 1'b0;
		sim_en  = 1'b0;
		bit1    = 1'b0;
		sim_dtx = 16'b11000001_00000011;
		sim_drx = 16'b00000101_00001000;
	    sim_len = 2;
		$display("tx_data = %b, sim_rx = %b", sim_dtx, sim_drx);
		
	#5 
		sim_rst = 1'b1;
		sim_en  = 1'b1;
		
	#10
		sim_en  = 1'b1;
		
	#15 
		sim_en = 1'b0;
		repeat(16) @(posedge net_sclk)
			if (bit1 == 1'b1)
				begin
				sim_drx = sim_drx << 1;
				end
			else
				begin
				bit1 = 1'b1; 
				end
		
		
	#300
		$finish;
		
	end	

	
assign sim_sdi = sim_drx[15];
	
SPI_MASTER #(0,0,2000000, 16, 50000000) dut0
(
	.CLK(sim_clk),
	.RESET(sim_rst),
	.ENABLE(sim_en),
	.LENGTH(sim_len),
	.SDI(sim_sdi),
	.SCLK(net_sclk),
	.SS(net_ss),
	.SDO(net_sdo),
	.DATA_IN(sim_dtx),
	.DATA_OUT(net_drx),
	.DONE(net_done)
	
);
	   
endmodule
	
	

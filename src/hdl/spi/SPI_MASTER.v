

 /*
    Module  : SPI_MASTER
    Version : 1.1
    Author  : Herzog Cyril
    Date    : 2019

	change:
	- internal filter is removed

	info:
	- this old version has a bad fsm design =>

	ToDo (optional): Change FSM - Encoding to "ONE HOT"
	      Control datapath only by state => (mux_sel = state...)

*/


`ifndef _SPI_MASTER_V_
`define _SPI_MASTER_V_


module SPI_MASTER
#(

	parameter   
		CPHA               = 0,
		CPOL               = 0,
		TRANSFER_FREQUENCY = 1000000,
		DATA_WIDTH         = 16,
		BOARD_FREQUENCY    = 50000000
)

		
(
	input CLK, RESET, ENABLE, SDI,
	input[7:0] LENGTH,				//Lenght in Bytes 
	output SCLK, SDO, SS,
	input[DATA_WIDTH-1:0] DATA_IN,
	output[DATA_WIDTH-1:0] DATA_OUT,
	output reg DONE  
);


// change encoding
localparam [1:0]
	idle     = 2'b00,
	delay    = 2'b01,
	clk_t1   = 2'b10,
	clk_t2   = 2'b11;


		
localparam sc_t   = (BOARD_FREQUENCY / TRANSFER_FREQUENCY);
localparam f_sc_t = sc_t - 1; 
localparam h_sc_t = (sc_t / 2) -1;


	
reg[1:0] state_reg, state_next;
reg[DATA_WIDTH-1:0] rx_reg, tx_reg, rx_next, tx_next;
reg[7:0] c_reg, c_next;	
reg[10:0] n_reg, n_next;
reg ss_reg, ss_next, sc_reg, sc_next;
wire[10:0] full_data; 

assign full_data = LENGTH << 3;


	
	
always@(posedge CLK, negedge RESET)
	if (~RESET) 
		begin
		c_reg   	<= 0;
		n_reg   	<= 0;
		rx_reg  	<= 0;
		tx_reg  	<= 0;
		ss_reg  	<= 1'b1;
		state_reg   <= idle;
		sc_reg      <= CPOL;
		end
	else 
		begin
		state_reg   <= state_next;
		sc_reg  	<= sc_next;
		ss_reg  	<= ss_next;
		c_reg   	<= c_next;
		n_reg   	<= n_next;
		rx_reg  	<= rx_next;
		tx_reg  	<= tx_next;
	end

	
	
always@ *
	begin
	c_next     = c_reg;
	n_next     = n_reg;
	sc_next    = sc_reg;
	ss_next    = ss_reg;
	tx_next    = tx_reg;
	rx_next    = rx_reg;
	state_next = state_reg;
	
	DONE       = 1'b0;    // Tick when Transfer ending

		
	case(state_reg)
		idle: 
		begin
			sc_next = CPOL;
			if (ENABLE)
				begin
				state_next  = delay;
				ss_next     = 1'b0;
				end
			end
		
		//delay for 1 spi clk cycle 
		delay:
		begin
			if (c_reg == f_sc_t)
				begin
				if (n_reg == full_data) //  multiplexer is not only control by state => complex logic 
					begin
					state_next  = idle;
					c_next      = 0;
					n_next      = 0;
					ss_next     = 1'b1;
					DONE        = 1'b1;
					end
				else
					begin
					state_next = clk_t1;
					c_next     = 0;
					tx_next    = DATA_IN;
					end
				end
			else
				begin
				c_next = c_reg + 1;
				end
			end
					
				
		clk_t1:
		begin
			if (c_reg == h_sc_t)
				begin
				state_next  = clk_t2;
				c_next      = 0;
		
				if(~CPHA) // parameter
					begin
					rx_next = {rx_reg[DATA_WIDTH-2:0], SDI};
					end
				end
			else
				begin
				c_next = c_reg + 1;
				
				if(~CPOL) // parameter
					begin
					sc_next = 1'b0;
					end
				else
					begin
					sc_next = 1'b1;
				end
			end
		end
			

		clk_t2:
		begin
			if (n_reg == full_data)
				begin
				state_next  = delay;
				sc_next     = CPOL;
				tx_next     = 0;
				end
			else if (c_reg == h_sc_t)
				begin
				c_next      = 0;
				state_next  = clk_t1;
				n_next      = n_reg + 1;
				tx_next     = {tx_reg[DATA_WIDTH-2:0], 1'b0};
				if(CPHA)
					begin
					rx_next = {rx_reg[DATA_WIDTH-2:0], SDI};
					end
				end
			else
				begin
				c_next = c_reg + 1;
				if(CPOL)
					sc_next = 1'b0;
				else
					sc_next = 1'b1;
				end
			end
			
		endcase
	end
	
	assign SDO      = (~ss_reg) ? tx_reg[DATA_WIDTH-1] : 1'bz; 
	assign SCLK     = sc_reg;
	assign SS       = ss_reg;
	assign DATA_OUT = rx_reg;

endmodule

`endif /* SPI_MASTER */

		
		
	
	
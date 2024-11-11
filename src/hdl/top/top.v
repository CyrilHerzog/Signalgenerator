
/*
    Module  : TOP
    Version : 1.0
    Author  : Herzog Cyril
    Date    : 14.10.2024

*/

`include "src/hdl/uart/include/uart_defines.vh"
//
`include "src/hdl/top/clock_source/clock_source_pll.v"
`include "src/hdl/pc_interface/pc_interface_top.v"
`include "src/hdl/divers/simple_filter.v"
//
`include "src/hdl/cdc/async_reset.v"
`include "src/hdl/cdc/synchronizer.v"

//
`include "src/hdl/spi/SPI_MASTER.v"

//
`include "src/hdl/top/signal_generator.v"


module top(
    input wire sysclk,
    // pc
    input wire uart_rx,
    output wire uart_tx,
    // dac
    output wire dac_spi_cs,
    output wire dac_spi_sclk,
    output wire dac_spi_sdo,
    output wire dac_ldac,
    // state
    output wire [3:0] led
);

    // GLOBAL - CLOCK
    clock_source_pll inst_pll ( 
        .i_sysclk_125   (sysclk), 
        // 
        .o_bufg_clk_50  (),  // 50 MHZ
        .o_bufg_clk_100 (), // 100 MHZ
        //
        .o_locked       () 
    );

    // GLOBAL ASYNCHRONOUS RESET
    async_reset #(
        .STAGES  (6),
        .INIT    (1'b0),
        .RST_VAL (1'b0)
    ) inst_sys_arst_n (
        .i_clk   (inst_pll.o_bufg_clk_50),
        .i_rst_n (inst_pll.o_locked),
        .o_rst   ()
    );

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    synchronizer #(
        .STAGES   (2),
        .INIT     (1'b1)
    ) inst_sync_uart_rx (
        .i_clk    (inst_pll.o_bufg_clk_50),
        .i_arst_n (inst_sys_arst_n.o_rst),
        .i_async  (uart_rx),
        .o_sync   () 
    );


    simple_filter #(
        .FILTER_WIDTH (4),
        .INIT_VAL     (1'b1)
    ) inst_filter_uart_rx (
        .i_clk        (inst_pll.o_bufg_clk_50),
        .i_arst_n     (inst_sys_arst_n.o_rst),  
        .i_raw        (inst_sync_uart_rx.o_sync),
        .o_filter     ()
    );

 
    pc_interface_top #(
        .CLK_FREQUENCY           (50_000_000),
        .UART_BAUDRATE           (115200),
        .UART_STOP_BITS          (`STOP_BITS_ONE),
        .UART_PARITY             (`PARITY_EVEN),
        .UART_FIFO_TX_ADDR_WIDTH (4),
        .UART_FIFO_RX_ADDR_WIDTH (4),
        //
        .BANK_DATA_WIDTH         (16),
        .BANK_ADDR_WIDTH         (2)  // max address width is 6 => 6 * DATA_WIDTH
    ) inst_pc_interface_top (
        .i_clk                   (inst_pll.o_bufg_clk_50),
        .i_arst_n                (inst_sys_arst_n.o_rst),
        // UART
        .i_pc_rx                 (inst_filter_uart_rx.o_filter),
        .o_pc_tx                 (uart_tx), 
        .o_pc_err                (),
        // BANK
        .i_bank_data             ({16'b0, 
                                   16'b0,
                                   16'b0,
                                   inst_pc_interface_top.o_bank_data[15:0]}),            
        .o_bank_data             ()
    );


//////////////////////////////////////////////////////////////////////////////////////////////////////////////


signal_generator inst_signal_generator (
    .clk        (inst_pll.o_bufg_clk_50),
    .rst_n      (inst_sys_arst_n.o_rst),
    .on         (1'b1),
    .frequency  (inst_pc_interface_top.o_bank_data[47:32]),
    .amplitude  (16'h00ff),
    .duty_cycle (inst_pc_interface_top.o_bank_data[55:48]),
    .sel        (inst_pc_interface_top.o_bank_data[17:16]), // 00 rectangle 01 triangle , 10 sine
    .led_on     (led[0]),
    .led_rect   (led[1]),
    .led_ramp   (led[2]),
    .led_sin    (led[3]),
    .signal_out ()
);



/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SPI

reg [1:0] r_spi_wait_count;
wire[1:0] ri_spi_wait_count;
wire spi_enable;

//
always@(posedge inst_pll.o_bufg_clk_50) begin 
    r_spi_wait_count <= ri_spi_wait_count;
end

assign ri_spi_wait_count = r_spi_wait_count + 2'b01;
//
assign spi_enable = &r_spi_wait_count;


SPI_MASTER #(
    .CPHA               (0),
	.CPOL               (0),
	.TRANSFER_FREQUENCY (10000000),
	.DATA_WIDTH         (16),
	.BOARD_FREQUENCY    (50000000)
) inst_spi_master (
	.CLK                (inst_pll.o_bufg_clk_50), 
    .RESET              (inst_sys_arst_n.o_rst),
    .ENABLE             (spi_enable),
    .SDI                (1'b0),
	.LENGTH             (8'd2), // 2 Bytes 
	.SCLK               (dac_spi_sclk),
    .SDO                (dac_spi_sdo),
    .SS                 (dac_spi_cs),
	.DATA_IN            (inst_signal_generator.signal_out),
	.DATA_OUT           (),
	.DONE               ()  
);


//

reg[1:0] r_ldac;
wire[1:0] ri_ldac;

//
always@(posedge inst_pll.o_bufg_clk_50) begin
    r_ldac[0] <= ri_ldac[0];
    r_ldac[1] <= ri_ldac[1];
end

//
assign ri_ldac[0] = ~inst_spi_master.DONE;
assign ri_ldac[1] = r_ldac[0];
//
assign dac_ldac = r_ldac[1]; // confirm data transfer on the dac



endmodule
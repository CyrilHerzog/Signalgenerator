
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
`include "src/hdl/sin_cos_generator/sin_cos_generator_top.v"

//
`include "src/hdl/ramp/signal_generator.v"


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
        .i_bank_data             ({inst_pc_interface_top.o_bank_data[63:48], 
                                   inst_pc_interface_top.o_bank_data[47:32],
                                   inst_pc_interface_top.o_bank_data[31:16],
                                   inst_pc_interface_top.o_bank_data[15:0]}),            
        .o_bank_data             ()
    );



//////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*

signal_generator inst_signal_generator (
    .clk        (inst_pll.o_bufg_clk_50),
    .rst_n      (inst_sys_arst_n.o_rst),
    .on         (1'b1),
    .frequency  (16'h03ff),
    .amplitude  (16'h00ff),
    .duty_cycle (8'd50),
    .sel        (2'b00), // 00 rechteck 01 sägezahn , 10 sin
    .led_on     (led[0]),
    .led_rect   (led[1]),
    .led_ramp   (led[2]),
    .led_sin    (led[3]),
    .signal_out ()
);
*/

/////////////////////////////////////////////////////////////////////////////////////////////////////////////

//(* DONT_TOUCH = "yes" *)
sin_cos_generator_top #(
    .F_CLK          (50_000_000)
) inst_sin_cos_generator_top (
    .i_clk          (inst_pll.o_bufg_clk_50), 
    .i_arst_n       (inst_sys_arst_n.o_rst),
    .i_enable       (1'b1),
    .i_amplitude    (24'd5093852), // (2^15 - 1) / 1.64676 24'd5093852
    .i_phase_offset (24'd0), // pi = 8388
    .i_amp_offset   (16'd32767),
    .o_cos          (),
    .o_sin          (),
    .o_valid        ()
);

  



/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SPI

reg[3:0] r_pulse;
wire spi_enable;
reg[15:0] r_spi_data;
wire[15:0] ri_spi_data;

always@(posedge inst_pll.o_bufg_clk_50) begin 
    r_pulse <= r_pulse + 1;
    r_spi_data <= ri_spi_data;
end

assign spi_enable = &r_pulse;
assign ri_spi_data = &r_pulse ? r_spi_data + 1 : r_spi_data;

SPI_MASTER #(
    .CPHA               (0),
	.CPOL               (0),
	.TRANSFER_FREQUENCY (1000000),
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
	.DATA_IN            (inst_sin_cos_generator_top.o_cos),
	.DATA_OUT           (),
	.DONE               ()  
);

 
reg r_ldac;
reg r_ldac_1;

always@(posedge inst_pll.o_bufg_clk_50) begin
    r_ldac <= ~inst_spi_master.DONE;
    r_ldac_1 <= r_ldac;
end

assign dac_ldac = r_ldac_1;



endmodule
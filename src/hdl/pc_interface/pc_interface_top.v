
/*
    Module  : PC_INTERFACE_TOP
    Version : 1.0
    Author  : Herzog Cyril
    Date    : 14.10.2024
*/

`ifndef _PC_INTERFACE_TOP_V_
`define _PC_INTERFACE_TOP_V_


`include "src/hdl/uart/include/uart_defines.vh"
`include "src/hdl/uart/uart_transceiver.v"
//
`include "src/hdl/pc_interface/pc_interface_handler.v"
`include "src/hdl/pc_interface/pc_interface_write_bank.v"
`include "src/hdl/pc_interface/pc_interface_read_bank.v"
//
`include "src/hdl/cdc/async_reset.v"


module pc_interface_top #(
    parameter CLK_FREQUENCY           = 100_000_000,
    parameter UART_BAUDRATE           = 115200,
    parameter UART_STOP_BITS          = `STOP_BITS_ONE,
    parameter UART_PARITY             = `PARITY_EVEN,
    parameter UART_FIFO_TX_ADDR_WIDTH = 8,
    parameter UART_FIFO_RX_ADDR_WIDTH = 8,
    //
    parameter BANK_DATA_WIDTH = 16,
    parameter BANK_ADDR_WIDTH = 3 
) (
    input wire i_clk, i_arst_n,
    // UART
    input wire i_pc_rx,
    output wire o_pc_tx, 
    output wire o_pc_err,
    // BANK
    input wire[(BANK_DATA_WIDTH << BANK_ADDR_WIDTH)-1:0] i_bank_data, 
    output wire[(BANK_DATA_WIDTH << BANK_ADDR_WIDTH)-1:0] o_bank_data
 );
    
    /////////////////////////////////////////////////////////////////////////////////////////////
    // LOCAL RESET
    async_reset #(
      .STAGES   (2),
      .INIT     (1'b0),
      .RST_VAL  (1'b0)
    ) inst_local_reset (
      .i_clk    (i_clk), 
      .i_rst_n  (i_arst_n),
      .o_rst    ()
    );
   

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // CALC TIMEOUT WIDTH
    localparam PARITY_BIT = (UART_PARITY != `PARITY_NONE) ? 1 : 0;
    localparam STOP_BITS  = (UART_STOP_BITS != `STOP_BITS_ONE) ? 2 : 1;
    localparam UART_BITS  = 9 + PARITY_BIT + STOP_BITS;

    localparam TIMEOUT_WIDTH = $clog2((CLK_FREQUENCY / UART_BAUDRATE) * UART_BITS) + 8; // take the next larger width 



    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // PC - INTERFACE (UART - TRANSCEIVER)

    uart_transceiver #(
        .F_CLK              (CLK_FREQUENCY), 
        .BAUDRATE           (UART_BAUDRATE), 
        .DATA_WIDTH         (8), 
        .STOP_BITS          (UART_STOP_BITS), 
        .PARITY             (UART_PARITY),
        .FIFO_TX_ADDR_WIDTH (UART_FIFO_TX_ADDR_WIDTH),
        .FIFO_RX_ADDR_WIDTH (UART_FIFO_RX_ADDR_WIDTH)
    ) inst_pc_interface (
        .i_clk              (i_clk),
        .i_arst_n           (inst_local_reset.o_rst),
        .i_rx               (i_pc_rx),
        .o_tx               (o_pc_tx),
        .i_rd               (inst_handler.o_pc_rd),
        .i_wr               (inst_handler.o_pc_wr),
        .i_data             (inst_handler.o_pc_data),
        .o_data             (),
        .o_rx_valid         (),
        .o_tx_rdy           (),
        .o_err_state        (),
        .o_err              (o_pc_err)
    );

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    pc_interface_handler #(
        .BANK_DATA_WIDTH    (BANK_DATA_WIDTH),
        .BANK_ADDR_WIDTH    (BANK_ADDR_WIDTH),
        .UART_TIMEOUT_WIDTH (TIMEOUT_WIDTH) 
    ) inst_handler (
        .i_clk              (i_clk),
        .i_arst_n           (inst_local_reset.o_rst),
        // UART
        .i_pc_valid         (inst_pc_interface.o_rx_valid), 
        .i_pc_rdy           (inst_pc_interface.o_tx_rdy),  
        .i_pc_data          (inst_pc_interface.o_data),
        .o_pc_data          (),
        .o_pc_rd            (),
        .o_pc_wr            (),
        // DATA BANK
        .i_bank_data        (inst_read_bank.o_data),
        .o_bank_data        (),
        .o_bank_wr          (),
        .o_bank_addr        ()
    );

    pc_interface_write_bank #(
        .DATA_WIDTH (BANK_DATA_WIDTH),
        .ADDR_WIDTH (BANK_ADDR_WIDTH)
    ) inst_write_bank (
        .i_clk      (i_clk),
        .i_arst_n   (inst_local_reset.o_rst),              
        .i_wr       (inst_handler.o_bank_wr),
        .i_addr     (inst_handler.o_bank_addr),
        .i_data     (inst_handler.o_bank_data),
        .o_data     (o_bank_data)
    );

    pc_interface_read_bank #(
        .DATA_WIDTH (BANK_DATA_WIDTH),
        .ADDR_WIDTH (BANK_ADDR_WIDTH)
    ) inst_read_bank (
        .i_clk      (i_clk),
        .i_arst_n   (inst_local_reset.o_rst),              
        .i_addr     (inst_handler.o_bank_addr),
        .i_data     (i_bank_data),
        .o_data     ()
    );



endmodule

`endif /* PC_INTERFACE_TOP */

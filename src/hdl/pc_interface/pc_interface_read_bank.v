/*
    Module  : PC_INTERFACE_READ_BANK
    Version : 1.0
    Author  : Herzog Cyril
    Date    : 14.10.2024
*/

`ifndef _PC_INTERFACE_READ_BANK_V_
`define _PC_INTERFACE_READ_BANK_V_

`include "src/hdl/divers/register.v"

module pc_interface_read_bank #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 3
) (
    input wire i_clk,
    input wire i_arst_n,                       
    input wire[ADDR_WIDTH-1:0] i_addr,
    input wire[(DATA_WIDTH << ADDR_WIDTH)-1:0] i_data,
    output wire [DATA_WIDTH-1:0] o_data
);


    wire [DATA_WIDTH-1:0] mux_data [(1 << ADDR_WIDTH)-1:0];

    genvar i;
    generate
        for (i = 0; i < (1 << ADDR_WIDTH); i = i + 1) begin : register_gen
            register #(
                .DATA_WIDTH (DATA_WIDTH)
            ) u_register (
                .i_clk      (i_clk),
                .i_arst_n   (i_arst_n),
                .i_clr      (1'b0),
                .i_wr       (1'b1),
                .i_data     (i_data[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
                .o_data     (mux_data[i])
            );

        end
    endgenerate

    assign o_data = mux_data[i_addr];

endmodule

`endif /* PC_INTERFACE_READ_BANK */
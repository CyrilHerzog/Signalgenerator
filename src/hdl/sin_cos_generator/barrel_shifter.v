 /*
    Module  : BARREL_SHIFTER
    Version : 1.0
    Author  : Herzog Cyril
    Date    : 23.10.2024

*/

`ifndef _BARREL_SHIFTER_V_
`define _BARREL_SHIFTER_V_

`include "src/hdl/sin_cos_generator/include/barrel_shifter_defines.vh"

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// BARREL_SHIFTER_32

(* DONT_TOUCH = "yes" *)
module barrel_shifter_32 #(
    parameter SHIFT_MODE = `SHIFT_MODE_LEFT
) (
    input wire [31:0] i_data,
    input wire i_right,
    input wire i_arith,
    input wire [4:0] i_shift,
    output wire [31:0] o_data
);

  
    wire[31:0] right_shift_o, left_shift_o; 

    generate 
        if ((SHIFT_MODE == `SHIFT_MODE_RIGHT) || (SHIFT_MODE == `SHIFT_MODE_BIDIRECTIONAL)) begin
            //
            wire fillbit;
            assign fillbit = i_arith & i_data[31];
            // STAGE 0
            mux_2x1 #(32) inst_r_mux_s0 (.i_a(i_data), .i_b({{16{fillbit}}, i_data[31:16]}), .i_sel(i_shift[4]), .o_y());
            // STAGE 1
            mux_2x1 #(32) inst_r_mux_s1 (.i_a(inst_r_mux_s0.o_y), .i_b({{8{fillbit}}, inst_r_mux_s0.o_y[31:8]}), .i_sel(i_shift[3]), .o_y());
            // STAGE 2
            mux_2x1 #(32) inst_r_mux_s2 (.i_a(inst_r_mux_s1.o_y), .i_b({{4{fillbit}}, inst_r_mux_s1.o_y[31:4]}), .i_sel(i_shift[2]), .o_y());
            // STAGE 3
            mux_2x1 #(32) inst_r_mux_s3 (.i_a(inst_r_mux_s2.o_y), .i_b({{2{fillbit}}, inst_r_mux_s2.o_y[31:2]}), .i_sel(i_shift[1]), .o_y());
            // STAGE 4
            mux_2x1 #(32) inst_r_mux_s4 (.i_a(inst_r_mux_s3.o_y), .i_b({fillbit, inst_r_mux_s3.o_y[31:1]}), .i_sel(i_shift[0]), .o_y());
            //
            assign right_shift_o = inst_r_mux_s4.o_y;
            // 
        end

        if ((SHIFT_MODE == `SHIFT_MODE_LEFT) || (SHIFT_MODE == `SHIFT_MODE_BIDIRECTIONAL)) begin
            //
            // STAGE 0
            mux_2x1 #(32) inst_l_mux_s0 (.i_a(i_data), .i_b({i_data[15:0], 16'b0}), .i_sel(i_shift[4]), .o_y());
            // STAGE 1
            mux_2x1 #(32) inst_l_mux_s1 (.i_a(inst_l_mux_s0.o_y), .i_b({inst_l_mux_s0.o_y[23:0], 8'b0}), .i_sel(i_shift[3]), .o_y());
            // STAGE 2
            mux_2x1 #(32) inst_l_mux_s2 (.i_a(inst_l_mux_s1.o_y), .i_b({inst_l_mux_s1.o_y[27:0], 4'b0}), .i_sel(i_shift[2]), .o_y());
            // STAGE 3
            mux_2x1 #(32) inst_l_mux_s3 (.i_a(inst_l_mux_s2.o_y), .i_b({inst_l_mux_s2.o_y[29:0], 2'b0}), .i_sel(i_shift[1]), .o_y());
            // STAGE 4
            mux_2x1 #(32) inst_l_mux_s4 (.i_a(inst_l_mux_s3.o_y), .i_b({inst_l_mux_s3.o_y[30:0], 1'b0}), .i_sel(i_shift[0]), .o_y());
            //
            assign left_shift_o = inst_l_mux_s4.o_y;
        end

        if (SHIFT_MODE == `SHIFT_MODE_RIGHT) begin
            //
            assign o_data = right_shift_o;
            //
        end else if (SHIFT_MODE == `SHIFT_MODE_LEFT) begin
            //
            assign o_data = left_shift_o;
            //
        end else begin

            // STAGE 5
            mux_2x1 #(32) inst_rl_mux_s5 (.i_a(left_shift_o), .i_b(right_shift_o), .i_sel(i_right), .o_y(o_data));
            //
        end
    endgenerate

    
endmodule


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// BARREL_SHIFTER_16

(* DONT_TOUCH = "yes" *)
module barrel_shifter_16 #(
    parameter SHIFT_MODE = `SHIFT_MODE_LEFT
)(
    input wire [15:0] i_data,
    input wire i_right,
    input wire i_arith,
    input wire [3:0] i_shift,
    output wire [15:0] o_data
);

    wire[15:0] right_shift_o, left_shift_o; 

    generate 
        if ((SHIFT_MODE == `SHIFT_MODE_RIGHT) || (SHIFT_MODE == `SHIFT_MODE_BIDIRECTIONAL)) begin
            //
            wire fillbit;
            assign fillbit = i_arith & i_data[15];
            //
            // STAGE 0
            mux_2x1 #(16) inst_r_mux_s0 (.i_a(i_data), .i_b({{8{fillbit}}, i_data[15:8]}), .i_sel(i_shift[3]), .o_y());
            // STAGE 1
            mux_2x1 #(16) inst_r_mux_s1 (.i_a(inst_r_mux_s0.o_y), .i_b({{4{fillbit}}, inst_r_mux_s0.o_y[15:4]}), .i_sel(i_shift[2]), .o_y());
            // STAGE 2
            mux_2x1 #(16) inst_r_mux_s2 (.i_a(inst_r_mux_s1.o_y), .i_b({{2{fillbit}}, inst_r_mux_s1.o_y[15:2]}), .i_sel(i_shift[1]), .o_y());
            // STAGE 3
            mux_2x1 #(16) inst_r_mux_s3 (.i_a(inst_r_mux_s2.o_y), .i_b({fillbit, inst_r_mux_s2.o_y[15:1]}), .i_sel(i_shift[0]), .o_y());
            //
            assign right_shift_o = inst_r_mux_s3.o_y;
            //
        end

        if ((SHIFT_MODE == `SHIFT_MODE_LEFT) || (SHIFT_MODE == `SHIFT_MODE_BIDIRECTIONAL)) begin
            //
            // STAGE 0
            mux_2x1 #(16) inst_l_mux_s0 (.i_a(i_data), .i_b({i_data[7:0], 8'b0}), .i_sel(i_shift[3]), .o_y());
            // STAGE 1
            mux_2x1 #(16) inst_l_mux_s1 (.i_a(inst_l_mux_s0.o_y), .i_b({inst_l_mux_s0.o_y[11:0], 4'b0}), .i_sel(i_shift[2]), .o_y());
            // STAGE 2
            mux_2x1 #(16) inst_l_mux_s2 (.i_a(inst_l_mux_s1.o_y), .i_b({inst_l_mux_s1.o_y[13:0], 2'b0}), .i_sel(i_shift[1]), .o_y());
            // STAGE 3
            mux_2x1 #(16) inst_l_mux_s3 (.i_a(inst_l_mux_s2.o_y), .i_b({inst_l_mux_s2.o_y[14:0], 1'b0}), .i_sel(i_shift[0]), .o_y());
            //
            assign left_shift_o = inst_l_mux_s3.o_y;
            //
        end

        if (SHIFT_MODE == `SHIFT_MODE_RIGHT) begin
            //
            assign o_data = right_shift_o;
            //
        end else if (SHIFT_MODE == `SHIFT_MODE_LEFT) begin
            //
            assign o_data = left_shift_o;
            //
        end else begin
            // STAGE 5
            mux_2x1 #(16) inst_rl_mux_s4 (.i_a(left_shift_o), .i_b(right_shift_o), .i_sel(i_right), .o_y(o_data));
            //
        end
    endgenerate


endmodule


//////////////////////////////////////////////////////////////////////////////////
// MUX_2X1
/*
    assign o_y = (i_a & ~i_sel) | (i_b & i_sel);
*/

module mux_2x1 #(
    parameter DATA_WIDTH = 32
) (
    input wire [DATA_WIDTH-1:0] i_a,
    input wire [DATA_WIDTH-1:0] i_b,
    input wire i_sel,
    output wire[DATA_WIDTH-1:0] o_y
);

    assign o_y = (i_sel) ? i_b : i_a;

endmodule



`endif /* BARREL_SHIFTER */
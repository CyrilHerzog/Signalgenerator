 /*
    Module  : BARREL_SHIFTER
    Version : 1.0
    Author  : Herzog Cyril
    Date    : 23.10.2024

    info: currently not used in top - design

    ToDo (optional): parameterizable for left/right and arithmetic right

    fillbit for arithmetic right shift => i_arith (port) & i_data[N-1];

*/

`ifndef _BARREL_SHIFTER_V_
`define _BARREL_SHIFTER_V_



module barrel_shifter_32 (
    input wire [31:0] i_data,
    input wire [4:0] i_shift,
    output wire [31:0] o_data
);

   

  
    // STAGE 0
    mux_2x1 #(32) inst_mux_stage_0 (.i_a(i_data), .i_b({i_data[15:0], 16'b0}), .i_sel(i_shift[4]));
    // STAGE 1
    mux_2x1 #(32) inst_mux_stage_1 (.i_a(inst_mux_stage_0.o_y), .i_b({inst_mux_stage_0.o_y[23:0], 8'b0}), .i_sel(i_shift[3]));
    // STAGE 2
    mux_2x1 #(32) inst_mux_stage_2 (.i_a(inst_mux_stage_1.o_y), .i_b({inst_mux_stage_1.o_y[27:0], 4'b0}), .i_sel(i_shift[2]));
    // STAGE 3
    mux_2x1 #(32) inst_mux_stage_3 (.i_a(inst_mux_stage_2.o_y), .i_b({inst_mux_stage_2.o_y[29:0], 2'b0}), .i_sel(i_shift[1]));
    // STAGE 4
    mux_2x1 #(32) inst_mux_stage_4 (.i_a(inst_mux_stage_3.o_y), .i_b({inst_mux_stage_3.o_y[30:0], 1'b0}), .i_sel(i_shift[0]));


    // output
    assign o_data = inst_mux_stage_4.o_y;

endmodule


module barrel_shifter_16 (
    input wire [15:0] i_data,
    input wire [3:0] i_shift,
    output wire [15:0] o_data
);

/*
    // STAGE 0
    mux_2x1 #(16) inst_mux_stage_0 (.i_a(i_data), .i_b({i_data[7:0], 8'b0}), .i_sel(i_shift[3]));
    // STAGE 1
    mux_2x1 #(16) inst_mux_stage_1 (.i_a(inst_mux_stage_0.o_y), .i_b({inst_mux_stage_0.o_y[11:0], 4'b0}), .i_sel(i_shift[2]));
    // STAGE 2
    mux_2x1 #(16) inst_mux_stage_2 (.i_a(inst_mux_stage_1.o_y), .i_b({inst_mux_stage_1.o_y[13:0], 2'b0}), .i_sel(i_shift[1]));
    // STAGE 3
    mux_2x1 #(16) inst_mux_stage_3 (.i_a(inst_mux_stage_2.o_y), .i_b({inst_mux_stage_2.o_y[14:0], 1'b0}), .i_sel(i_shift[0]));
*/
    // output

    // STAGE 0
    mux_2x1 #(16) inst_mux_stage_0 (.i_a(i_data), .i_b({{8{i_data[15]}}, i_data[15:8]}), .i_sel(i_shift[3]));
    // STAGE 1
    mux_2x1 #(16) inst_mux_stage_1 (.i_a(inst_mux_stage_0.o_y), .i_b({{4{i_data[15]}},inst_mux_stage_0.o_y[15:4]}), .i_sel(i_shift[2]));
    // STAGE 2
    mux_2x1 #(16) inst_mux_stage_2 (.i_a(inst_mux_stage_1.o_y), .i_b({{2{i_data[15]}}, inst_mux_stage_1.o_y[15:2]}), .i_sel(i_shift[1]));
    // STAGE 3
    mux_2x1 #(16) inst_mux_stage_3 (.i_a(inst_mux_stage_2.o_y), .i_b({{1{i_data[15]}}, inst_mux_stage_2.o_y[15:1]}), .i_sel(i_shift[0]));

    assign o_data = inst_mux_stage_3.o_y;

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
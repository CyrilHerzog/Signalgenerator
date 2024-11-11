

 /*
    Module  : SIN_COS_GENERATOR_TOP
    Version : 1.0
    Author  : Herzog Cyril
    Date    : 28.10.2024



*/


`ifndef _SIN_COS_GENERATOR_TOP_V_
`define _SIN_COS_GENERATOR_TOP_V_


`include "src/hdl/sin_cos_generator/carry_lookahead_adder.v"
`include "src/hdl/sin_cos_generator/cordic.v"
`include "src/hdl/sin_cos_generator/phase_accumulator.v"
//
`include "src/hdl/cdc/async_reset.v"


module sin_cos_generator_top (
    input wire i_clk, i_arst_n,
    input wire i_enable,
    input wire [11:0] i_frequency,
    input wire [23:0] i_amplitude,
    input wire [23:0] i_phase_offset,
    input wire [15:0] i_amp_offset,
    output wire [15:0] o_cos,
    output wire [15:0] o_sin,
    output wire o_valid
);


// LOCAL RESET
async_reset #(
    .STAGES  (2),
    .INIT    (1'b0),
    .RST_VAL (1'b0)
) inst_arst_n (
    .i_clk   (i_clk),
    .i_rst_n (i_arst_n),
    .o_rst   ()
);


// PHASE ACCUMULATOR
phase_accumulator inst_phase_accumulator (
    .i_clk          (i_clk),
    .i_arst_n       (inst_arst_n.o_rst),
    .i_enable       (i_enable),
    .i_frequency    (i_frequency),
    .i_offset       (i_phase_offset),
    .o_angle        (),
    .o_valid        ()
);

// CORDIC
cordic inst_cordic(
    .i_clk      (i_clk),
    .i_arst_n   (inst_arst_n.o_rst),
    .i_valid    (inst_phase_accumulator.o_valid),
    .i_x        (i_amplitude),
    .i_y        (24'd0), // 0
    .i_z        (inst_phase_accumulator.o_angle),
    .o_x        (),
    .o_y        (),
    .o_z        (),
    .o_valid    ()
);

// ADD AMPLITUDE OFFSET FOR COSINUS
cla_16 inst_adder_offset_cos (
    .i_c    (1'b0),
    .i_a    (inst_cordic.o_x[23:8]),
    .i_b    (i_amp_offset), 
    .o_s    (),
    .o_c    (),
    .o_g    (),
    .o_p    ()
);

// ADD AMPLITUDE OFFSET FOR SINUS
cla_16 inst_adder_offset_sin (
    .i_c    (1'b0),
    .i_a    (inst_cordic.o_y[23:8]),
    .i_b    (i_amp_offset), 
    .o_s    (),
    .o_c    (),
    .o_g    (),
    .o_p    ()
);

//
reg[15:0] r_cos, r_sin;
wire[15:0] ri_cos, ri_sin;
//
always@(posedge i_clk, negedge inst_arst_n.o_rst)
    if (~inst_arst_n.o_rst) begin
        r_cos <= 16'b0;
        r_sin <= 16'b0;
    end else begin
        r_cos <= ri_cos;
        r_sin <= ri_sin;
    end

//
assign ri_cos = inst_adder_offset_cos.o_s;
assign ri_sin = inst_adder_offset_sin.o_s;


// OUTPUT
assign o_valid = inst_cordic.o_valid;
//
assign o_cos = r_cos;
assign o_sin = r_sin;


endmodule

`endif /* SIN_COS_GENERATOR_TOP */
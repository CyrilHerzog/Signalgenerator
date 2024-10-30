
 /*
    Module  : PHASE_ACCUMULATOR
    Version : 1.0
    Author  : Herzog Cyril
    Date    : 28.10.2024



*/


`ifndef _PHASE_ACCUMULATOR_V_
`define _PHASE_ACCUMULATOR_V_

`include "src/hdl/sin_cos_generator/carry_lookahead_adder.v"

module phase_accumulator #(
    parameter F_CLK = 50_000_000
) (
    input wire i_clk, i_arst_n,
    input wire i_enable,
    input wire [23:0] i_offset,
    output wire [23:0] o_angle,
    output wire o_valid
);



    // MIN STEP
    localparam phase_step = ((3 * (1 << 24)) << 16) / F_CLK;


    //
    reg[23:0] r_accu;
    wire[23:0] ri_accu;
    reg r_run;
    wire ri_run;

    // ADDER
    cla_24 inst_adder (
        .i_c    (1'b0),
        .i_a    (r_accu),
        .i_b    (phase_step[23:0]),
        .o_s    (),
        .o_c    (),
        .o_g    (),
        .o_p    ()
    );


    always@(posedge i_clk, negedge i_arst_n)
        if (~i_arst_n) begin
            r_accu <= 24'b0;
            r_run  <= 1'b0;
        end else begin
            r_accu <= ri_accu;
            r_run  <= ri_run;
        end
    //
    assign ri_run  = i_enable;
    assign ri_accu = r_run ? inst_adder.o_s : i_offset;

    // OUTPUT
    assign o_angle = r_accu;
    assign o_valid = r_run;
    
endmodule


`endif /* PHASE_ACCUMULATOR */




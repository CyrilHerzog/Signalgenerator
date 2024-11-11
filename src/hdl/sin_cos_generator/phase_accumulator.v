
 /*
    Module  : PHASE_ACCUMULATOR
    Version : 1.0
    Author  : Herzog Cyril
    Date    : 28.10.2024

    phase (2 * pi) = 2^24
    minimum possible frequency = 50 * 10^6 / 2^24 = 3 Hz  

    calc_phase_step = [(i_frequency * 1374) / 4096] + 1

    1374 => 2^10 + 2^8 + 2^6 + 2^4 + 2^2 + 2^1

    1374 / 4096 => 2^-2 + 2^-4 + 2^-6 + 2^-8 + 2^-9 + 2^-10 + 2^-11

    => 3 - 4095 Hz => single step in range of  1 - 1374 

*/


`ifndef _PHASE_ACCUMULATOR_V_
`define _PHASE_ACCUMULATOR_V_

`include "src/hdl/sin_cos_generator/include/barrel_shifter_defines.vh"
//
`include "src/hdl/sin_cos_generator/carry_lookahead_adder.v"
`include "src/hdl/sin_cos_generator/barrel_shifter.v"


module phase_accumulator (
    input wire i_clk, i_arst_n,
    input wire i_enable,
    input wire[11:0] i_frequency,
    input wire [23:0] i_offset,
    output wire [23:0] o_angle,
    output wire o_valid
);

    localparam [7:0] S_0 = 8'b00000001, // 0
                     S_1 = 8'b00000010, // 1
                     S_2 = 8'b00000100, // 2
                     S_3 = 8'b00001000, // 3
                     S_4 = 8'b00010000, // 4
                     S_5 = 8'b00100000, // 5
                     S_6 = 8'b01000000, // 6
                     S_7 = 8'b10000000; // 7  
    
    (* fsm_encoding = "user_encoding" *)
    reg[7:0] r_state = S_0;
    reg[7:0] ri_state;

    reg[3:0] r_shift, ri_shift;
    reg [11:0] r_frequency;
    wire[11:0] ri_frequency;
    reg[15:0] r_calc_accu;
    wire[15:0] ri_calc_accu;
    //
    reg r_step_run;
    wire ri_step_run;

    reg[15:0] r_calc_step;
    wire[15:0] ri_calc_step;
    reg[23:0] r_step_accu;
    wire[23:0] ri_step_accu;



    always@(posedge i_clk, negedge i_arst_n)
        if (~i_arst_n) begin
            r_state     <= S_0;
            r_shift     <= 4'b0000;
            r_frequency <= 12'b0;
            r_calc_accu <= 16'b0;
            r_calc_step <= 16'b0;
            //
            r_step_run  <= 1'b0;
            r_step_accu <= 24'b0;
        end else begin
            r_state     <= ri_state;
            r_shift     <= ri_shift;
            r_frequency <= ri_frequency;
            r_calc_accu <= ri_calc_accu;
            r_calc_step <= ri_calc_step;
            //
            r_step_run  <= ri_step_run;
            r_step_accu <= ri_step_accu;
            
        end

    //
    assign ri_frequency = (r_state[0]) ? i_frequency : r_frequency;
    assign ri_calc_accu = (r_state[0]) ? 16'b0 : inst_calc_adder.o_s;
    assign ri_calc_step = (r_state[7]) ? r_calc_accu : r_calc_step;

    //
    assign ri_step_run  = i_enable;
    assign ri_step_accu = r_step_run ? inst_step_adder.o_s : i_offset;

    //
    always@ * begin
        //
        ri_state = r_state;
        ri_shift = r_shift;

        case(r_state)
            S_0: begin ri_shift = 4'b0010; ri_state = S_1; end
            S_1: begin ri_shift = 4'b0100; ri_state = S_2; end
            S_2: begin ri_shift = 4'b0110; ri_state = S_3; end
            S_3: begin ri_shift = 4'b1000; ri_state = S_4; end
            S_4: begin ri_shift = 4'b1001; ri_state = S_5; end
            S_5: begin ri_shift = 4'b1010; ri_state = S_6; end
            S_6: begin ri_shift = 4'b1011; ri_state = S_7; end
            S_7: begin ri_state = S_0; end
            //
            default: begin ri_state = S_0; end
            //
        endcase

    end        

    // SHIFTER => 2^-x
    barrel_shifter_16 #(
        .SHIFT_MODE (`SHIFT_MODE_RIGHT)
    ) inst_calc_shifter (
        .i_data     ({4'b0, r_frequency}),
        .i_right    (1'b0), // only for bidirectional mode
        .i_arith    (1'b0),
        .i_shift    (r_shift),
        .o_data     ()
    );

    // ADDER => SUM[2^-x + 2^-y + 2^....]
    cla_16 inst_calc_adder (
        .i_c    (r_state[6]),
        .i_a    (r_calc_accu),
        .i_b    (inst_calc_shifter.o_data),
        .o_s    (),
        .o_c    (),
        .o_g    (),
        .o_p    ()
    );

    // ADDER SUM[calc_step[n] + calc_step[n-1] + calc_step[n-2] + ....]
    cla_24 inst_step_adder (
        .i_c    (1'b0),
        .i_a    (r_step_accu),
        .i_b    ({8'b0, r_calc_step}),
        .o_s    (),
        .o_c    (),
        .o_g    (),
        .o_p    ()
    );
    


    // OUTPUT
    assign o_angle = r_step_accu;
    assign o_valid = r_step_run;


endmodule


`endif /* PHASE_ACCUMULATOR */




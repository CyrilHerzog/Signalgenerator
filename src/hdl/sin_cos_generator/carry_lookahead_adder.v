
 /*
    Module  : CARRY_LOOKAHEAD_ADDER
    Version : 1.0
    Author  : Herzog Cyril
    Date    : 23.10.2024

*/


`ifndef _CARRY_LOOKAHEAD_ADDER_V_
`define _CARRY_LOOKAHEAD_ADDER_V_



////////////////////////////////////////////////////////////////////////////////////////////////
// CARRY LOOKAHEAD ADDER 32 BIT

(* DONT_TOUCH = "yes" *)
module cla_32 (
    input wire i_c,
    input wire [31:0] i_a, i_b,
    output wire[31:0] o_s,
    output wire o_c,
    output wire o_p, o_g
);

    cla_16 inst_cla_16_0 (
        .i_c     (i_c), 
        .i_a     (i_a[15:0]), 
        .i_b     (i_b[15:0]),
        .o_s     (o_s[15:0]),
        .o_c     (),
        .o_p     (),
        .o_g     ()
    );

    cla_16 inst_cla_16_1 (
        .i_c     (inst_gp_2.o_c[0]), 
        .i_a     (i_a[31:16]), 
        .i_b     (i_b[31:16]),
        .o_s     (o_s[31:16]),
        .o_c     (),
        .o_p     (),
        .o_g     ()
    );

    gp_2 inst_gp_2 (
        .i_c    (i_c),
        .i_g    ({inst_cla_16_1.o_g, inst_cla_16_0.o_g}),
        .i_p    ({inst_cla_16_1.o_p, inst_cla_16_0.o_p}),
        .o_c    (),
        .o_g    (o_g),
        .o_p    (o_p)
    );

    assign o_c = inst_gp_2.o_c[1];

endmodule


////////////////////////////////////////////////////////////////////////////////////////////////
// CARRY LOOKAHEAD ADDER 24 BIT
(* DONT_TOUCH = "yes" *)
module cla_24 (
    input wire i_c,
    input wire [23:0] i_a, i_b,
    output wire[23:0] o_s,
    output wire o_c,
    output wire o_p, o_g
);

    cla_16 inst_cla_16 (
        .i_c     (i_c), 
        .i_a     (i_a[15:0]), 
        .i_b     (i_b[15:0]),
        .o_s     (o_s[15:0]),
        .o_c     (),
        .o_p     (),
        .o_g     ()
    );

    cla_8 inst_cla_8 (
        .i_c     (inst_gp_2.o_c[0]), 
        .i_a     (i_a[23:16]), 
        .i_b     (i_b[23:16]),
        .o_s     (o_s[23:16]),
        .o_c     (),
        .o_p     (),
        .o_g     ()
    );

    gp_2 inst_gp_2 (
        .i_c    (i_c),
        .i_g    ({inst_cla_8.o_g, inst_cla_16.o_g}),
        .i_p    ({inst_cla_8.o_p, inst_cla_16.o_p}),
        .o_c    (),
        .o_g    (o_g),
        .o_p    (o_p)
    );

    assign o_c = inst_gp_2.o_c[1];

endmodule


////////////////////////////////////////////////////////////////////////////////////////////////
// CARRY LOOKAHEAD ADDER 16 BIT
(* DONT_TOUCH = "yes" *)
module cla_16 (
    input wire i_c,
    input wire [15:0] i_a, i_b,
    output wire[15:0] o_s,
    output wire o_c,
    output wire o_p, o_g
);

    wire[15:0] c, g, p;

    
    // FIRST STAGE

    assign c[0]     = i_c;
    assign c[3:1]   = inst_gp4_0.o_c[2:0]; 
    //
    assign c[4]     = inst_gp4_4.o_c[0];
    assign c[7:5]   = inst_gp4_1.o_c[2:0];
    //
    assign c[8]     = inst_gp4_4.o_c[1];
    assign c[11:9]  = inst_gp4_2.o_c[2:0];
    //
    assign c[12]    = inst_gp4_4.o_c[2];
    assign c[15:13] = inst_gp4_3.o_c[2:0];

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_pfa
            pfa inst_pfa (
                .i_a (i_a[i]),
                .i_b (i_b[i]),
                .i_c (c[i]),
                .o_g (g[i]),
                .o_p (p[i]),
                .o_s (o_s[i])
            );

        end
    endgenerate


    // SECOND STAGE
    gp_4 inst_gp4_0 (
        .i_c    (i_c), 
        .i_g    (g[3:0]), 
        .i_p    (p[3:0]),
        .o_c    (),
        .o_p    (),
        .o_g    ()
    );


    gp_4 inst_gp4_1 (
        .i_c    (inst_gp4_4.o_c[0]), 
        .i_g    (g[7:4]), 
        .i_p    (p[7:4]),
        .o_c    (),
        .o_p    (),
        .o_g    ()
    );

    gp_4 inst_gp4_2 (
        .i_c    (inst_gp4_4.o_c[1]), 
        .i_g    (g[11:8]), 
        .i_p    (p[11:8]),
        .o_c    (),
        .o_p    (),
        .o_g    ()
    );

    gp_4 inst_gp4_3 (
        .i_c    (inst_gp4_4.o_c[2]), 
        .i_g    (g[15:12]), 
        .i_p    (p[15:12]),
        .o_c    (),
        .o_p    (),
        .o_g    ()
    );


    // THIRD STAGE
    gp_4 inst_gp4_4 (
        .i_c    (i_c), 
        .i_g    ({inst_gp4_3.o_g, inst_gp4_2.o_g, inst_gp4_1.o_g, inst_gp4_0.o_g}), 
        .i_p    ({inst_gp4_3.o_p, inst_gp4_2.o_p, inst_gp4_1.o_p, inst_gp4_0.o_p}),
        .o_c    (),
        .o_p    (o_p),
        .o_g    (o_g)
    );

    assign o_c = inst_gp4_4.o_c[3];


endmodule


////////////////////////////////////////////////////////////////////////////////////////////////
// CARRY LOOKAHEAD ADDER 8 BIT
(* DONT_TOUCH = "yes" *)
module cla_8 (
    input wire i_c,
    input wire [7:0] i_a, i_b,
    output wire[7:0] o_s,
    output wire o_c,
    output wire o_p, o_g
);

    wire[7:0] c, g, p;

    
    // FIRST STAGE

    assign c[0]     = i_c;
    assign c[3:1]   = inst_gp4_0.o_c[2:0]; 
    //
    assign c[4]     = inst_gp2_0.o_c[0];
    assign c[7:5]   = inst_gp4_1.o_c[2:0];
    

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_pfa
            pfa inst_pfa (
                .i_a (i_a[i]),
                .i_b (i_b[i]),
                .i_c (c[i]),
                .o_g (g[i]),
                .o_p (p[i]),
                .o_s (o_s[i])
            );

        end
    endgenerate


    // SECOND STAGE
    gp_4 inst_gp4_0 (
        .i_c    (c[0]), 
        .i_g    (g[3:0]), 
        .i_p    (p[3:0]),
        .o_c    (),
        .o_p    (),
        .o_g    ()
    );


    gp_4 inst_gp4_1 (
        .i_c    (inst_gp2_0.o_c[0]), 
        .i_g    (g[7:4]), 
        .i_p    (p[7:4]),
        .o_c    (),
        .o_p    (),
        .o_g    ()
    );


    // THIRD STAGE
    gp_2 inst_gp2_0 (
        .i_c    (c[0]), 
        .i_g    ({inst_gp4_1.o_g, inst_gp4_0.o_g}), 
        .i_p    ({inst_gp4_1.o_p, inst_gp4_0.o_p}),
        .o_c    (),
        .o_p    (o_p),
        .o_g    (o_g)
    );

    assign o_c = inst_gp2_0.o_c[1];


endmodule





///////////////////////////////////////////////////////////////////////////////////////////////
// PARTIAL FULL ADDER 

module pfa (
    input wire i_a, i_b, i_c,
    output wire o_g, o_p, o_s
);

    assign o_s = i_a ^ i_b ^ i_c;
    //
    assign o_p = i_a ^ i_b;
    assign o_g = i_a & i_b;

endmodule

///////////////////////////////////////////////////////////////////////////////////////////////
//

module gp_2 (
    input wire i_c,
    input wire[1:0] i_g, i_p,
    output wire[1:0] o_c, 
    output wire o_g, o_p
);

    assign o_c[0] = i_g[0] | (i_p[0] & i_c);
    //
    assign o_c[1] = i_g[1] | (i_p[1] & i_g[0]) 
                           | (i_p[0] & i_p[1] & i_c);
    //
    assign o_p = i_p[0] & i_p[1]; 
    assign o_g = i_g[1] | (i_p[1] & i_g[0]);

endmodule


module gp_4 (
    input wire i_c,
    input wire [3:0] i_g, i_p,
    output wire [3:0] o_c,
    output wire o_g, o_p
);

    assign o_c[0] = i_g[0] | (i_p[0] & i_c);
    //
    assign o_c[1] = i_g[1] | (i_p[1] & i_g[0]) 
                           | (i_p[1] & i_p[0] & i_c);
    //
    assign o_c[2] = i_g[2] | (i_p[2] & i_g[1]) 
                           | (i_p[2] & i_p[1] & i_g[0]) 
                           | (i_p[2] & i_p[1] & i_p[0] & i_c);
    //
    assign o_c[3] = i_g[3] | (i_p[3] & i_g[2]) 
                           | (i_p[3] & i_p[2] & i_g[1]) 
                           | (i_p[3] & i_p[2] & i_p[1] & i_g[0])
                           | (i_p[3] & i_p[2] & i_p[1] & i_p[0] & i_c);
    //
    assign o_p = i_p[3] & i_p[2] & i_p[1] & i_p[0]; 
    assign o_g = i_g[3] | (i_p[3] & i_g[2]) 
                        | (i_p[3] & i_p[2] & i_g[1]) 
                        | (i_p[3] & i_p[2] & i_p[1] & i_g[0]);


endmodule

`endif /* CARRY_LOCKAHEAD_ADDER */
 /*
    Module  : CORDIC
    Version : 1.0
    Author  : Herzog Cyril
    Date    : 20.10.2024


    constant K = 1.64676 => 1/K = 0.60725


*/


`ifndef _CORDIC_V_
`define _CORDIC_V_

`include "src/hdl/sin_cos_generator/carry_lookahead_adder.v"

module cordic (
    input wire i_clk, i_arst_n,
    input wire i_valid,
    input wire[23:0] i_x, i_y, i_z,  
    output wire [23:0] o_x, o_y, o_z,
    output wire o_valid
);


    localparam NUM_STAGES = 23;

    

    /////////////////////////////////////////////////////////////////////////////////////////////
    // CONTROL

    reg[NUM_STAGES-1:0] r_shift;
    wire[NUM_STAGES-1:0] ri_shift;

    always@(posedge i_clk, negedge i_arst_n)
        if (~i_arst_n)
            r_shift <= {NUM_STAGES{1'b0}};
        else
            r_shift <= ri_shift;

    //
    assign ri_shift = {r_shift[NUM_STAGES-2:0], i_valid};

    //
    assign o_valid = r_shift[NUM_STAGES-1];     


    /////////////////////////////////////////////////////////////////////////////////////////////
    // DATA PATH

    reg [23:0] r_x [0:NUM_STAGES];
    reg [23:0] r_y [0:NUM_STAGES];
    reg [23:0] r_z [0:NUM_STAGES];
    wire [23:0] ri_x [0:NUM_STAGES];
    wire [23:0] ri_y [0:NUM_STAGES];
    wire [23:0] ri_z [0:NUM_STAGES];
    //
    wire [23:0] atan_const [0:22];

    integer k;
    always@(posedge i_clk, negedge i_arst_n)
        if (~i_arst_n) begin
            for (k = 0; k < NUM_STAGES; k = k + 1) begin
                r_x[k] <= 24'b0;
                r_y[k] <= 24'b0;
                r_z[k] <= 24'b0;
            end
        end else begin
            for (k = 0; k < NUM_STAGES; k = k + 1) begin
                r_x[k] <= ri_x[k];
                r_y[k] <= ri_y[k];
                r_z[k] <= ri_z[k];
            end
        end

    
    // QUADRANT
    wire [23:0] neg_xy;
    assign neg_xy = i_z[23] ? ~i_x : ~i_y;
    cla_24 inst_inc_xy(.i_c(1'b1), .i_a(neg_xy), .i_b(24'd0), .o_c(), .o_s(), .o_p(), .o_g());
 
    

    assign ri_x[0] = (^i_z[23:22]) ? (i_z[23] ? i_y : inst_inc_xy.o_s) : i_x;
    assign ri_y[0] = (^i_z[23:22]) ? (i_z[23] ? inst_inc_xy.o_s : i_x) : i_y;
    assign ri_z[0] = (^i_z[23:22]) ? (i_z[23] ? {2'b11, i_z[21:0]} : {2'b00, i_z[21:0]}) : i_z;



    
    genvar i, j;
    generate
        //
        wire z_sign [0:NUM_STAGES];
        //
        wire [23:0] shr_x [0:NUM_STAGES];
        wire [23:0] shr_y [0:NUM_STAGES];
        //
        wire [23:0] add_x [0:NUM_STAGES];
        wire [23:0] add_y [0:NUM_STAGES];
        wire [23:0] add_z [0:NUM_STAGES];

        //
        for (i = 0; i < NUM_STAGES; i = i + 1) begin : stages
            //
            assign z_sign[i] = r_z[i][23];
            //
            // SHIFT
            assign shr_x[i] = {{i{r_x[i][23]}}, r_x[i][23:i]};
            assign shr_y[i] = {{i{r_y[i][23]}}, r_y[i][23:i]}; 
  
            //
            // ADD/SUB
            for (j = 0; j < 24; j = j + 1) begin 
                assign add_x[i][j] = ~z_sign[i] ^ shr_y[i][j]; 
                assign add_y[i][j] =  z_sign[i] ^ shr_x[i][j];
                assign add_z[i][j] = ~z_sign[i] ^ atan_const[i][j];
                //
            end  

            cla_24 inst_adder_x (.i_c(~z_sign[i]), .i_a(r_x[i]), .i_b(add_x[i]), .o_s(ri_x[i+1]), .o_c(), .o_p(), .o_g());
            cla_24 inst_adder_y (.i_c(z_sign[i]),  .i_a(r_y[i]), .i_b(add_y[i]), .o_s(ri_y[i+1]), .o_c(), .o_p(), .o_g());
            cla_24 inst_adder_z (.i_c(~z_sign[i]), .i_a(r_z[i]), .i_b(add_z[i]), .o_s(ri_z[i+1]), .o_c(), .o_p(), .o_g());
            //
        end
    endgenerate


    //
    assign o_x = r_x[NUM_STAGES-1];
    assign o_y = r_y[NUM_STAGES-1];
    assign o_z = r_z[NUM_STAGES-1];



    
    //////////////////////////////////////////////////////////////////////////////////////////////
    // ATAN CONSTANT'S => (atan(2^-i) / (2 * pi)) * 2^24 

    assign atan_const[00] = 24'b001000000000000000000000;
    assign atan_const[01] = 24'b000100101110010000000101;
    assign atan_const[02] = 24'b000010011111101100111000;   
    assign atan_const[03] = 24'b000001010001000100010001;
    assign atan_const[04] = 24'b000000101000101100001101;
    assign atan_const[05] = 24'b000000010100010111010111;
    assign atan_const[06] = 24'b000000001010001011110110;
    assign atan_const[07] = 24'b000000000101000101111100;
    assign atan_const[08] = 24'b000000000010100010111110;
    assign atan_const[09] = 24'b000000000001010001011111;
    assign atan_const[10] = 24'b000000000000101000101111;
    assign atan_const[11] = 24'b000000000000010100010111;
    assign atan_const[12] = 24'b000000000000001010001011;
    assign atan_const[13] = 24'b000000000000000101000101;
    assign atan_const[14] = 24'b000000000000000010100010;
    assign atan_const[15] = 24'b000000000000000001010001;
    assign atan_const[16] = 24'b000000000000000000101000;
    assign atan_const[17] = 24'b000000000000000000010100;
    assign atan_const[18] = 24'b000000000000000000001010;
    assign atan_const[19] = 24'b000000000000000000000101;
    assign atan_const[20] = 24'b000000000000000000000010;
    assign atan_const[21] = 24'b000000000000000000000001;
    assign atan_const[22] = 24'b000000000000000000000000;
        


endmodule    



`endif /* CORDIC */




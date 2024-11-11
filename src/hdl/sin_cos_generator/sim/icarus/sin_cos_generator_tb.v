
 /*
    Module  : SIN_COS_GENERATOR_TB
    Version : 1.0
    Author  : Herzog Cyril
    Date    : 28.10.2024

*/


`timescale 1ns/1ns


module sin_cos_generator_tb;


reg sim_clk, sim_arst_n;
reg sim_enable;



initial begin
        sim_clk = 1'b0;
        forever
        #10 sim_clk = ~sim_clk;
    end


// Dumpfile und Dumpvars für GtkWave
initial begin
    $dumpfile("sim/icarus/sin_cos_generator.vcd");
    $dumpvars(0, sin_cos_generator_tb);
end

initial 
    begin
    #0        sim_arst_n = 1'b0;
              sim_enable = 1'b0;         
    #1000     sim_arst_n = 1'b1;
              sim_enable = 1'b1;
    
    #1000000;   

    
   

    $finish;
end

// 

sin_cos_generator_top dut_sin_cos_generator_top (
    .i_clk          (sim_clk), 
    .i_arst_n       (sim_arst_n),
    .i_enable       (sim_enable),
    .i_frequency    (12'd3800), // 3 - 4095 Hz
    .i_amplitude    (24'd5093852), // (2^15 - 1) / 1.64676
    .i_phase_offset (24'd0),
    .i_amp_offset   (16'd32768),
    .o_cos          (),
    .o_sin          (),
    .o_valid        ()
);





endmodule

            

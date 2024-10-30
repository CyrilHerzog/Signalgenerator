`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.10.2024 18:41:41
// Design Name: 
// Module Name: top_wave_generator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_wave_generator(
        input sysclk,
        input reset_button,
        output led_on,
        output led_rect,
        output led_ramp,
        output led_sin
        
    );
    
    wire on = 1'b1;
    reg [1:0] sel = 2'b00; // Select Signal
    // 00 = Rechteck
    // 01 = Sägezahn
    // 10 = Sin
    reg [15:0] frequency = 16'h3FFF;// Frequenz 1 - 8192Hz in 2^n Schritten
    reg [7:0] amplitude = 16'h00FF; // Amplitude in %
    reg[7:0] duty_cycle = 8'd100; // Duty Cycle des Sägezahns (0-100%)
    
    wire [15:0] signal_out; // Signaloutput
   
    
    // Instanz von Rechteckgenerator
    signal_generator signal_generator_instance (
        .clk(sysclk),
        .rst_n(~reset_button),
        .on(on),
        .frequency(frequency),
        .amplitude(amplitude),
        .duty_cycle(duty_cycle),
        .sel(sel),
        .led_on(led_on),
        .led_rect(led_rect),
        .led_ramp(led_ramp),
        .led_sin(led_sin),
        .signal_out(signal_out)
    );
    
    assign led_on = on;
    
endmodule

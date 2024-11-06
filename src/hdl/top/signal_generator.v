`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.10.2024 19:31:30
// Design Name: 
// Module Name: signal_generator
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


`include "src/hdl/rect/rect.v"
`include "src/hdl/ramp/ramp.v"
`include "src/hdl/sin_cos_generator/sin_cos_generator_top.v"


module signal_generator(
    input wire clk,
    input wire rst_n,
    input wire on, // Signal on
    input wire [1:0] sel, // Select Signal
    // 00 = Rechteck
    // 01 = Sägezahn
    // 10 = Sin
    input wire [15:0] frequency, // Frequenz 1 - 8192Hz in 2^n Schritten
    input wire [7:0] amplitude, // Amplitude in %
    input wire [7:0] duty_cycle, // Duty Cycle des Sägezahns (0-100%)
    output reg [15:0] signal_out,
    output reg led_on,
    output reg led_rect,
    output reg led_ramp,
    output reg led_sin

);

wire [15:0] rect_out;
wire [15:0] ramp_out;
wire [15:0] sine_out;

    // Instanz von Rechteckgenerator
    rect rect_instance (
        .clk(clk),
        .rst_n(rst_n),
        .on(on),
        .frequency(frequency),
        .amplitude(amplitude),
        .duty_cycle(duty_cycle),
        .rect_out(rect_out)
    );

    // Instanz von Rechteckgenerator     
    ramp ramp_instance (
        .clk(clk),
        .rst_n(rst_n),
        .on(on),
        .frequency(frequency),
        .amplitude(amplitude),
        .ramp_out(ramp_out)
    );

    sin_cos_generator_top #(
        .F_CLK          (50_000_000)
    ) inst_sin_cos_generator_top (
        .i_clk          (clk), 
        .i_arst_n       (rst_n),
        .i_enable       (1'b1),
        .i_freq         (frequency[4:0]),
        .i_amplitude    (24'd5093852), // (2^15 - 1) / 1.64676 24'd5093852
        .i_phase_offset (24'd0), // pi = 8388
        .i_amp_offset   (16'd32767),
        .o_cos          (sine_out),
        .o_sin          (),
        .o_valid        ()
    );

    // Multiplexer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_out <= 0;
            led_rect <= 0;
            led_ramp <= 0;
            led_sin <= 0;
        end else begin
            if (on == 1'b1) begin
                case (sel)
                    2'b00: begin // Rechteck
                        signal_out <= rect_out;
                        led_rect <= 1;
                        led_ramp <= 0;
                        led_sin <= 0;
                    end
                    2'b01: begin // Sägezahn
                        signal_out <= ramp_out;
                        led_rect <= 0;
                        led_ramp <= 1;
                        led_sin <= 0;
                    end
                    2'b10: begin // Sinus
                        signal_out <= sine_out;
                        led_rect <= 0;
                        led_ramp <= 0;
                        led_sin <= 1;
                    end
                    default: begin
                        signal_out <= 16'h0000;
                        led_rect <= 0;
                        led_ramp <= 0;
                        led_sin <= 0;
                    end
                endcase
            end else begin
                signal_out <= 16'h0000;
            end
        end
    end

    always led_on = on;
    
endmodule

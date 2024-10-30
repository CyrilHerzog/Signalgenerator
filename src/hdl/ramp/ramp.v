`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.10.2024 16:05:38
// Design Name: 
// Module Name: ramp2
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


module ramp(
    input wire clk, // 50 MHz clock input
    input wire rst_n, // Asynchronous reset (active low)
    input wire on, // Signal einschalten
    input wire [15:0] frequency, // Frequenz des Sägezahns 2^n
    input wire [7:0] amplitude, // Amplitundenhöhe in %
    output reg [15:0] ramp_out // 16-bit Ausgabe des Sägezahnsignals
);

    reg [31:0] counter = 0; // Zähler für den Sägezahn
//    reg [15:0] max_frequency; // Maximalfrequenz basierend auf Eingabe
    reg [15:0] delta = 0; // Schrittweite für das Sägezahnsignal
    reg [15:0] delay = 0; // Zähler für 762-Schritte
    reg [15:0] delay_counter = 0; // Zähler für 762-Schritte
    reg [15:0] out; // 16-bit Ausgabe des Sägezahnsignals

    //always@(*) begin
    //   max_frequency = (16'hFFFF);// >> frequency) * 762; // 2^16 * 762 = 49.93 MHz
    //    delta = 16'h1 << frequency;
    //end

    always@(*) begin
        case (frequency)
            16'h0000: begin
                delta <= 1;
                delay <= 762;
            end
            16'h0001: begin
                delta <= 1;
                delay <= 381;
            end
            16'h0003: begin
                delta <= 1;
                delay <= 190;
            end
            16'h0007: begin
                delta <= 1;
                delay <= 95;
            end
            16'h000F: begin
                delta <= 1;
                delay <= 47;
            end
            16'h001F: begin
                delta <= 1;
                delay <= 23;
            end
            16'h003F: begin
                delta <= 1;
                delay <= 11;
            end
            16'h007F: begin
                delta <= 1;
                delay <= 5;
            end
            16'h00FF: begin
                delta <= 1;
                delay <= 2;
            end
            16'h01FF: begin
                delta <= 1;
                delay <= 1;
            end
            16'h03FF: begin
                delta <= 2;
                delay <= 1;
            end
            16'h07FF: begin
                delta <= 4;
                delay <= 1;
            end
            16'h0FFF: begin
                delta <= 8;
                delay <= 1;
            end
            16'h1FFF: begin
                delta <= 16;
                delay <= 1;
            end
            default: begin
                delta <= 1;
                delay <= 762;
            end
        endcase
    end

    // Zählerlogik für das Sägezahnsignal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            out <= 0;
            delay_counter <= 0;
        end else begin
            if (on == 1'b1) begin
                if (counter < 16'hFFFF) begin
                    counter <= counter + 1;

                    if (delay_counter >= delay) begin
                        delay_counter <= 0;

                        out <= out + delta; // Update des Sägezahnsignals

                        ramp_out <= out;
                    end else begin
                        ramp_out <= out;
                        delay_counter <= delay_counter + 1;
                    end

                end else begin
                    counter <= 0;
                end
            end else begin
                counter <= 0;
                out <= 0;
                ramp_out <= 0;
                delay_counter <= 0;
            end

        end
    end



endmodule














`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.10.2024 19:31:30
// Design Name: 
// Module Name: rect
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

module rect(
    input wire clk, // 100 MHz clock input
    input wire rst_n, // Asynchronous reset (active low)
    input wire on, // Signal einschalten
    input wire [15:0] frequency, // Frequenz des Rechtecksignals 2^n
    input wire [7:0] amplitude, // Amplitundenhöhe in %
    input wire [7:0] duty_cycle, // Duty Cycle des Sägezahns (0-100%)
    output reg [15:0] rect_out // 16-bit Ausgabe des Rechtecksignals
);

    reg [15:0] counter; // Zähler für den Sägezahn
    reg [15:0] counter_duty_cycle = 0; // Zähler für den duty_cycle
    reg [15:0] max_amplitude; // Maximale Amplitudenhöhe
    reg [18:0] unit = 0; // Wert des Unit
    reg [7:0] unit_counter = 0; // counter des Unit

    
     always@(*) begin
        case (frequency)
            16'h0000: begin
                unit <= 19'd500_000;
            end
            16'h0001: begin
                unit <= 19'd250_000;
            end
            16'h0003: begin
                unit <= 19'd125_000;
            end
            16'h0007: begin
                unit <= 19'd62_500;
            end
            16'h000F: begin
                unit <= 19'd31_250;
            end
            16'h001F: begin
                unit <= 19'd15_625;
            end
            16'h003F: begin
                unit <= 19'd7_812;
            end
            16'h007F: begin
                unit <= 19'd3_906;
            end
            16'h00FF: begin
                unit <= 19'd1_953;
            end
            16'h01FF: begin
                unit <= 19'd976;
            end
            16'h03FF: begin
                unit <= 19'd488;
            end
            16'h07FF: begin
                unit <= 19'd244;
            end
            16'h0FFF: begin
                unit <= 19'd122;
            end
            16'h1FFF: begin
                unit <= 19'd61;
            end
            16'h3FFF: begin
                unit <= 19'd31;
            end
            16'h7FFF: begin
                unit <= 19'd15;
            end
            default: begin
                unit <= 19'd500_000;
            end
        endcase
    end

    // Berechne der max_amplitude
    always @(amplitude) begin
        if (amplitude > 99) begin
            max_amplitude = 16'hFFFF;
        end else begin
            max_amplitude =  655 * amplitude; // 656 Takte = 1%     
        end
    end

    // Zählerlogik für das Sägezahnsignal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            rect_out <= 0;
            counter_duty_cycle <= 0;
        end else begin
            if (on == 1'b1) begin
                if (counter > unit) begin
                    counter <= 0;
                    unit_counter <= unit_counter + 1;
                    
                    if (unit_counter > 100) begin
                        unit_counter <= 0;
                    end
                    
                end else begin
                 counter <= counter + 1;
                end
                
                if (unit_counter < duty_cycle) begin
                    rect_out <= max_amplitude;
                end else begin
                    rect_out <= 16'h0000;
                end
               
            end else begin
                counter <= 0;
                rect_out <= 0;
                counter_duty_cycle <= 0;
            end
        end
    end
endmodule


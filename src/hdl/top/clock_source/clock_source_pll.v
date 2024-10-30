 /*
    Module  : CLOCK_SOURCE_PLL
    Version : 1.0
    Author  : Herzog Cyril
    Date    : 11.08.2024

*/

`ifndef _CLOCK_SOURCE_PLL_V_
`define _CLOCK_SOURCE_PLL_V_

module clock_source_pll
( 
    input wire i_sysclk_125, 
    // 
    output wire o_bufg_clk_50,  // 50 MHZ
    output wire o_bufg_clk_100, // 100 MHZ
    //
    output wire o_locked 
 );

   
    wire ibuf_sysclk_o;
    //    
    wire pll_clk_50_o;
    wire pll_clk_100_o;
    wire pll_clk_fb_o;
    wire pll_clk_fb_i;
    
  

    // buffer single clock - input (K17)    
    IBUF inst_ibuf_clk_in (
        .I (i_sysclk_125),
        .O (ibuf_sysclk_o)    
    );
    
    PLLE2_BASE #(
        .BANDWIDTH          ("OPTIMIZED"),  
        .CLKFBOUT_MULT      (36),        
        .CLKFBOUT_PHASE     (0.0),     
        .CLKIN1_PERIOD      (8.0),   
        .CLKOUT0_DIVIDE     (18),
        .CLKOUT1_DIVIDE     (9),
        .CLKOUT2_DIVIDE     (1),
        .CLKOUT3_DIVIDE     (1),
        .CLKOUT4_DIVIDE     (1),
        .CLKOUT5_DIVIDE     (1),
        .CLKOUT0_DUTY_CYCLE (0.5),
        .CLKOUT1_DUTY_CYCLE (0.5),
        .CLKOUT2_DUTY_CYCLE (0.5),
        .CLKOUT3_DUTY_CYCLE (0.5),
        .CLKOUT4_DUTY_CYCLE (0.5),
        .CLKOUT5_DUTY_CYCLE (0.5),
        .CLKOUT0_PHASE      (0.0),
        .CLKOUT1_PHASE      (0.0),
        .CLKOUT2_PHASE      (0.0),
        .CLKOUT3_PHASE      (0.0),
        .CLKOUT4_PHASE      (0.0),
        .CLKOUT5_PHASE      (0.0),
        .DIVCLK_DIVIDE      (5),       
        .REF_JITTER1        (0.0),       
        .STARTUP_WAIT       ("FALSE")    
    ) inst_plle2_base (
        .CLKOUT0            (pll_clk_50_o),   
        .CLKOUT1            (pll_clk_100_o),   
        .CLKOUT2            (),  
        .CLKOUT3            (),  
        .CLKOUT4            (),  
        .CLKOUT5            (),   
        .CLKFBOUT           (pll_clk_fb_o),  
        .LOCKED             (o_locked),     
        .CLKIN1             (ibuf_sysclk_o),    
        .PWRDWN             (1'b0),   
        .RST                (1'b0),   
        .CLKFBIN            (pll_clk_fb_i)   
    );

    // internal loop => no phase alligning
    assign pll_clk_fb_i = pll_clk_fb_o;
    
    
    ///////////////////////////////////////////////////////////////////////////////
    // OUTPUT CLOCK BUFFERING

    BUFG inst_bufg_clk0 (
        .I  (pll_clk_50_o),
        .O  (o_bufg_clk_50)
    );

    BUFG inst_bufg_clk1 (
        .I  (pll_clk_100_o),
        .O  (o_bufg_clk_100)
    );

endmodule

`endif /* CLOCK_SOURCE_PLL */


 /*
    Module  : PC_INTERFACE_HANDLER
    Version : 1.0
    Author  : Herzog Cyril
    Date    : 14.10.2024

*/
 
 
`ifndef _PC_INTERFACE_HANDLER_V_
`define _PC_INTERFACE_HANDLER_V_


`include "src/hdl/global_functions.vh"


 module pc_interface_handler #(
    parameter BANK_DATA_WIDTH    = 16,
    parameter BANK_ADDR_WIDTH    = 3,    
    parameter UART_TIMEOUT_WIDTH = 4 
 )(
    input wire i_clk, i_arst_n,
    // UART
    input wire i_pc_valid, 
    input wire i_pc_rdy, 
    input wire [7:0] i_pc_data,
    output wire [7:0] o_pc_data,
    output wire o_pc_rd, o_pc_wr,
    // DATA BANK
    input wire [BANK_DATA_WIDTH-1:0] i_bank_data,
    output wire [BANK_DATA_WIDTH-1:0] o_bank_data,
    output wire o_bank_wr, 
    output wire[BANK_ADDR_WIDTH-1:0] o_bank_addr
 );

    ////////////////////////////////////////////////////////////////////////////////////////////
    // INTERNAL CONSTANT'S
    localparam integer MAX_BANK_ADDR_WIDTH = `fun_limit(1, BANK_ADDR_WIDTH, 6);
    //
    localparam integer PC_SHIFT_BYTES = `fun_sizeof_byte(BANK_DATA_WIDTH);
    localparam integer PC_SHIFT_WIDTH = PC_SHIFT_BYTES << 3;


    ////////////////////////////////////////////////////////////////////////////////////////////
    // FSM
    localparam [8:0]  S_IDLE          = 9'b000000001, // 0
                      S_CMD_DECODE    = 9'b000000010, // 1
                      S_RW_BANK       = 9'b000000100, // 2
                      S_WAIT_PC_VALID = 9'b000001000, // 3
                      S_WAIT_PC_READY = 9'b000010000, // 4
                      S_READ_PC       = 9'b000100000, // 5
                      S_WRITE_PC      = 9'b001000000, // 6
                      S_WRITE_BANK    = 9'b010000000, // 7
                      S_READ_BANK     = 9'b100000000; // 8


    (* fsm_encoding = "user_encoding" *)
    reg [8:0] r_state = S_IDLE;
    reg [8:0] ri_state;
    
    // state assigment
    assign o_pc_wr   = r_state[6];                     
    assign o_pc_rd   = (r_state[1] || r_state[5]);
    //
    assign o_bank_wr = r_state[7];
    //

    reg [UART_TIMEOUT_WIDTH-1:0] r_timeout, ri_timeout;

    reg[PC_SHIFT_WIDTH-1:0] r_pc_shift_in, ri_pc_shift_in;
    reg[PC_SHIFT_WIDTH-1:0] r_pc_shift_out, ri_pc_shift_out;

    reg[$clog2(PC_SHIFT_BYTES-1):0] r_byte_cnt, ri_byte_cnt;
    reg[MAX_BANK_ADDR_WIDTH-1:0] r_bank_addr, ri_bank_addr; 

    reg[1:0] r_rw_cmd, ri_rw_cmd;
    
    wire timeout;
    wire addr_inc_enable, max_bank_addr;
    wire bank_bytes_done, bank_wr_enable;

    always@(posedge i_clk, negedge i_arst_n)
        if (~i_arst_n) begin
            r_state        <= S_IDLE;
            r_timeout      <= 0;
            r_pc_shift_in  <= 0;
            r_pc_shift_out <= 0;
            r_bank_addr    <= 0;
            r_byte_cnt     <= 0;
            r_rw_cmd       <= 0;
        end else begin
            r_state        <= ri_state;
            r_timeout      <= ri_timeout;
            r_pc_shift_in  <= ri_pc_shift_in;
            r_pc_shift_out <= ri_pc_shift_out;
            r_bank_addr    <= ri_bank_addr;
            r_byte_cnt     <= ri_byte_cnt;
            r_rw_cmd       <= ri_rw_cmd;
        end

    
    //assign timeout       = &r_timeout;     
    assign timeout         = 1'b0;
    assign max_bank_addr   = &r_bank_addr;
    assign bank_bytes_done = (r_byte_cnt == 0);
    assign bank_wr_enable  = r_rw_cmd[1];
    assign addr_inc_enable = r_rw_cmd[0] && ~max_bank_addr;
    
  
    always @* begin

        // default
        ri_state        = r_state;
        ri_timeout      = r_timeout;
        ri_pc_shift_in  = r_pc_shift_in;
        ri_pc_shift_out = r_pc_shift_out;
        ri_bank_addr    = r_bank_addr;
        ri_byte_cnt     = r_byte_cnt;
        ri_rw_cmd       = r_rw_cmd;

        case (r_state) 

            S_IDLE: begin
                // data_path
                ri_timeout = 0;
                ri_pc_shift_in = {r_pc_shift_in[PC_SHIFT_WIDTH-8:0], i_pc_data};

                if (i_pc_valid)
                    ri_state = S_CMD_DECODE;

            end

          
            S_CMD_DECODE: begin
                ri_bank_addr = r_pc_shift_in[MAX_BANK_ADDR_WIDTH-1:0];
                ri_rw_cmd    = r_pc_shift_in[7:6];
                ri_state     = S_RW_BANK;
            end


            S_RW_BANK: begin
                ri_byte_cnt     = PC_SHIFT_BYTES - 1;
                ri_pc_shift_out = i_bank_data;
                if (bank_wr_enable)
                    ri_state = S_WAIT_PC_VALID;
                else
                    ri_state = S_WAIT_PC_READY;

            end


            S_WAIT_PC_VALID: begin
                // data path
                ri_timeout = r_timeout + 1;
                // next state
                if (timeout)
                    ri_state = S_IDLE;
                else if (i_pc_valid)
                    ri_state = S_READ_PC;
            end


            S_READ_PC: begin
                ri_pc_shift_in = {r_pc_shift_in[PC_SHIFT_WIDTH-8:0], i_pc_data};
                ri_byte_cnt    = r_byte_cnt - 1;
                ri_timeout = 0;
                if (bank_bytes_done)
                    ri_state = S_WRITE_BANK;
                else
                    ri_state = S_WAIT_PC_VALID;
            end


            S_WRITE_BANK: begin
                ri_bank_addr = r_bank_addr + 1;
                if (addr_inc_enable)
                    ri_state = S_RW_BANK;
                else 
                    ri_state = S_IDLE;
            end

            S_WAIT_PC_READY: begin
                if (i_pc_rdy)
                    ri_state = S_WRITE_PC;
            end


            S_WRITE_PC: begin
                ri_pc_shift_out = {r_pc_shift_out[PC_SHIFT_WIDTH-8:0], 8'b0};
                ri_byte_cnt = r_byte_cnt - 1;
                if (bank_bytes_done)
                    ri_state = S_READ_BANK;
                else
                    ri_state = S_WAIT_PC_READY;
            end

            S_READ_BANK: begin
                ri_bank_addr = r_bank_addr + 1;
                if (addr_inc_enable)
                    ri_state = S_RW_BANK;
                else
                    ri_state = S_IDLE;

            end

            default: begin
                ri_state = S_IDLE;

            end

        endcase

    end

    assign o_bank_addr = r_bank_addr[MAX_BANK_ADDR_WIDTH-1:0];
    assign o_bank_data = r_pc_shift_in[BANK_DATA_WIDTH-1:0];
    //
    assign o_pc_data = r_pc_shift_out[PC_SHIFT_WIDTH-1:PC_SHIFT_WIDTH-8];

           
endmodule

`endif /* PC_INTERFACE_HANDLER */
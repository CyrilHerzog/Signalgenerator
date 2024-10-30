/*
    Module  : GLOBAL_FUNCTIONS
    Version : 1.1
    Author  : Herzog Cyril
    Date    : 14.10.2024

*/


`ifndef GLOBAL_FUNCTIONS_VH
`define GLOBAL_FUNCTIONS_VH

// fun_sizeof_byte => return number of bytes to represent the data width
`define fun_sizeof_byte(width) (((((width) % 8) == 0) ? (width) : ((width) + 8 - ((width) % 8))) / 8)

// fun_padding_bits => return number of padding bits 
`define fun_padding_bits(width) ((8 - ((width) % 8)) % 8)

// fun_max => return the higher input
`define fun_max(a, b) (((a) >= (b)) ? (a) : (b))

// fun_limit => returns the parameter value in the valid range
`define fun_limit(min, param, max) ((param) < (min) ? (min) : ((param) > (max) ? (max) : (param)))


`endif

 

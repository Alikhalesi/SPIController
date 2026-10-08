`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/12/2026 09:09:10 AM
// Design Name: 
// Module Name: register_file
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


module register_file #(parameter int DATA_WIDTH=32,parameter int ADDR_WIDTH=4, localparam int MAX_ADDR_WITH  = 6)
(
input logic clk,

input logic [ADDR_WIDTH-1:0] w_addr, r_addr,
input logic [DATA_WIDTH-1:0] w_data,
input logic wr_en,
output logic [DATA_WIDTH-1:0] r_data

);
    
   generate
        if (ADDR_WIDTH > MAX_ADDR_WITH) begin : param_check
            $fatal(1, "Error in %m: ADDR_WIDTH (%0d) exceeds the maximum allowed value (%0d)!", ADDR_WIDTH, MAX_ADDR_WITH);
            end
    endgenerate
    
    
logic [DATA_WIDTH-1:0] array_reg [0:2**ADDR_WIDTH-1]; 
    
//combinational read logic    
assign r_data= array_reg[r_addr];
    
 //sequential write logic
 always_ff @(posedge clk)
    begin
        if (wr_en)
            array_reg[w_addr]<=w_data;
    end
 

    
    
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/12/2026 09:04:50 AM
// Design Name: 
// Module Name: fifo
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


module fifo #(
parameter int DATA_WIDTH = 32, parameter int ADDR_WIDTH = 4,localparam int MAX_INDEX=2**ADDR_WIDTH-1
)
(
input logic clk,
input logic nrst,
input logic w_en,
input logic r_en,// read operation is asynchronous, this signal just pop the data from FIFO.
output logic[DATA_WIDTH-1:0] r_data,
input logic[DATA_WIDTH-1:0] w_data,
output logic empty,full
    );
      
   logic [ADDR_WIDTH-1:0] r_pointer,w_pointer,next_r_pointer,next_w_pointer;
   logic full_reg,next_full_reg,empty_reg,next_empty_reg;
    
    register_file #(.DATA_WIDTH(DATA_WIDTH),.ADDR_WIDTH(ADDR_WIDTH))
     register (.clk(clk),
      .w_addr(w_pointer),
      .r_addr(r_pointer),
      .w_data(w_data),
      .wr_en(w_en),
      .r_data(r_data)  
     );
  
always_ff @(posedge clk, negedge nrst)
    begin
        if (!nrst)
            begin
                r_pointer<=0;
                w_pointer<=0;
                full_reg<=0;
                empty_reg<=1;
            end
        else
            begin
                r_pointer<=next_r_pointer;
                w_pointer<=next_w_pointer;
                full_reg<=next_full_reg;
                empty_reg<=next_empty_reg;
            end        
    end
     
//Next State Logic
always_comb
    begin
    next_r_pointer=r_pointer;
    next_w_pointer= w_pointer;
    next_full_reg=full_reg;
    next_empty_reg = empty_reg;
        if (r_en)
            begin
                next_r_pointer= r_pointer==MAX_INDEX?0:r_pointer+1;
                 next_full_reg=0;
                if(next_r_pointer==w_pointer)
                    next_empty_reg=1;
            end
        else if (w_en)
                begin
                    next_w_pointer= w_pointer==MAX_INDEX?0:w_pointer+1;
                     next_empty_reg=0;
                    if(next_w_pointer==r_pointer)
                    next_full_reg=1;
                end
    end    
    
    
    //Output logic
    assign empty= empty_reg;
    assign full= full_reg;

    
endmodule

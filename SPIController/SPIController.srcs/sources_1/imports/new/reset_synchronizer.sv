`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/11/2026 10:39:16 AM
// Design Name: 
// Module Name: reset_synchronizer
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


module reset_synchronizer(
    input logic nrst,
    input logic clk,
    output logic sync_nrst
    
    );
    
    
    (* async_reg = "true" *) logic rst_stage1,rst_stage2;
    
    assign sync_nrst=rst_stage2;
    
    always_ff @(posedge clk,negedge nrst) begin
        if(!nrst)
            begin
                rst_stage2<=1'b0;
                rst_stage1<=1'b0;
            end
         else
            begin
                rst_stage1<=1'b1;
                rst_stage2<=rst_stage1;
            end
            
    end
    
    
    
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/02/2026 06:36:27 PM
// Design Name: 
// Module Name: top
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


module top(
input logic clk,
input logic nrst,
input logic miso,
output logic mosi,
output logic sclk,
output logic csn,
output logic[7:0] sseg_data,
output logic[7:0] sseg_ctrl

    );
    

    
    logic synced_rst;
    reset_synchronizer rst_synchronizer(.nrst(nsrt),.clk(clk),.sync_nrst(synced_rst));
  
  
  
  logic ready;
  logic start;
  
  logic[7:0] r_din,next_din;
  logic[7:0] dout;
  logic finished;
  
  spi_master master(
 .clk(clk),
 .nrst(synced_rst),
.sclk(sclk),
.mosi(mosi),
.ready(ready),
.miso(miso),
.start(start),
.din(r_din),
.dout(dout),
.finished(finished)
);


//now just send data
  logic r_csn,next_csn;
  always_ff @(posedge clk, negedge nrst)
  begin
    if(!nrst)
        begin
            r_csn<=1;
        end
    else
        begin
        r_csn<=next_csn;
        end
  end



logic[3:0] hard_sseg_ctrl=4'b1111;
assign sseg_ctrl[7:4]=hard_sseg_ctrl;
assign start_signal=finished;
 logic finished_signal;


sseg_mux seven_mux(.number( {8'b0,din} ),
.ctrl(sseg_ctrl[3:0]),
.data(sseg_data),
.start_signal(start_signal),
.finished_signal(finished_signal),
.clk(clk),
.nRst(synced_rst));

assign led=1'b1;
    
    
    
endmodule

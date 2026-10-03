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
output logic[7:0] sseg_ctrl,
input logic btn,
output logic led

    );
    

    
    logic synced_rst;
    reset_synchronizer rst_synchronizer(.nrst(nrst),.clk(clk),.sync_nrst(synced_rst));
  
  
  
  logic ready;
  logic r_start,next_start;
  


  logic finished;
  



//now just send data

  
  typedef enum logic[7:0] {WRITE_REGISTER=8'h0A,READ_REGISTER=8'h0B,READ_FIFO=8'h0D} Commands;
    
  
typedef enum logic [3:0] {
    IDLE = 4'd0,
    TEAR_UP_TRANSACTION=4'd1,
    SEND_BYTE=4'd2,
    READ_BYTE=4'd3,
    WAIT_FOR_FINISH=4'd4,
    TEAR_DOWN_TRANSACTION=4'd5,
    WAIT_FOR_SETTLE=4'd6
  
} state_t;
  
  state_t r_state,next_state;
    logic r_csn,next_csn;
    logic[4:0] r_counter,next_counter;
      logic[7:0] r_din,next_din;
    localparam int TEAR_UP_COUNT=10;
    logic r_led,next_led;
      logic[7:0] r_dout,next_dout;
  always_ff @(posedge clk, negedge nrst)
  begin
    if(!nrst)
        begin
            r_csn<=1;
            r_din<=0;
            r_dout<=0;
            r_state<=IDLE;
            r_counter<=0;
            r_start<=0;
            r_led<=0;
        end
    else
        begin
            r_csn<=next_csn;
            r_din<=next_din;
            r_state<=next_state;
            r_counter<=next_counter;
            r_start<=next_start;
            r_led<=next_led;
            if(r_state==TEAR_DOWN_TRANSACTION)
            r_dout<=next_dout;
        end
  end
  always_comb
  begin
  next_csn=r_csn;
  next_din=r_din;
  next_state=r_state;
  next_counter=r_counter;
  next_led=r_led;
  next_start=r_start;
    case (r_state)
        IDLE:
            begin
                next_led=0;
              if(btn)
                begin
                    next_csn=0;
                    next_state=TEAR_UP_TRANSACTION;
                    next_counter=0;
                end
            end
          
        TEAR_UP_TRANSACTION:
            begin
               if(r_counter==TEAR_UP_COUNT)
                begin
                    next_state=SEND_BYTE;
                    next_start=1;
                    next_din=READ_REGISTER;
                end
               else
                next_counter=r_counter+1;
            end
        SEND_BYTE:
            begin
                begin
                    next_state=READ_BYTE;
                    next_start=0;
                end
            end
        READ_BYTE:
            begin
                if(ready)
                    begin
                        next_start=1;
                        next_din=8'd0;
                        next_state=WAIT_FOR_SETTLE;
                    end
            end
        WAIT_FOR_SETTLE:
            begin
                next_state=WAIT_FOR_FINISH;
                next_start=0;
            end    
        WAIT_FOR_FINISH:
            begin
                if(ready)
                    begin
                        next_state=TEAR_DOWN_TRANSACTION;
                        next_led=1;
                        next_counter=0;
                     end
            end
          TEAR_DOWN_TRANSACTION:
            begin
                if(r_counter==1)
                next_state=IDLE;
                else
                next_counter=r_counter+1;
            end
    endcase
  end
  
  assign csn=r_csn;
  assign led=r_led;

  spi_master master(
 .clk(clk),
 .nrst(synced_rst),
.sclk(sclk),
.mosi(mosi),
.ready(ready),
.miso(miso),
.start(r_start),
.din(r_din),
.dout(next_dout),
.finished(finished)
);

logic[3:0] hard_sseg_ctrl=4'b1111;
assign sseg_ctrl[7:4]=hard_sseg_ctrl;
assign start_signal= r_state==TEAR_DOWN_TRANSACTION;
 logic finished_signal;


sseg_mux seven_mux(.number( {8'b0,r_din} ),
.ctrl(sseg_ctrl[3:0]),
.data(sseg_data),
.start_signal(start_signal),
.finished_signal(finished_signal),
.clk(clk),
.nRst(synced_rst));


    
    
    
endmodule

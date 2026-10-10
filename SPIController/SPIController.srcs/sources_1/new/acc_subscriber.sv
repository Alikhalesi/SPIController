`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2026 10:57:13 AM
// Design Name: 
// Module Name: acc_subscriber
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


module acc_subscriber(
        input logic clk,
        input logic nrst,
        input logic fifo_empy,
        input logic fifo_full,
        input logic[7:0] fifo_top,
        input logic fifo_updated,
        output logic[7:0] sseg_data,
output logic[7:0] sseg_ctrl
    );
    
    
    

    
    typedef enum logic[1:0] {IDLE=2'd0,TRY_TO_REFRESH=2'd1} state;
     
 
     logic r_need_refresh,next_need_refresh;
      state r_state, next_state;
    always_ff @(posedge clk,negedge nrst)
        begin
            if(!nrst)
                begin
                    r_state<=IDLE;
                    r_need_refresh<=0;
                end
            else
                begin
                    r_state<=next_state;
                    r_need_refresh<=next_need_refresh;
                end
        end
    
    always_comb
        begin
            next_state=r_state;
            next_need_refresh=r_need_refresh;
            case (r_state)
                IDLE:
                    begin
                        if(fifo_updated)
                            begin
                                next_state=TRY_TO_REFRESH;
                            end
                            
                    end
                TRY_TO_REFRESH:
                    begin
                        if(seven_seg_ready)
                            begin
                                next_need_refresh=1;
                                next_state=IDLE;
                            end
                    end
            endcase
        end
    
    
    
    logic[3:0] hard_sseg_ctrl=4'b1111;
   
assign sseg_ctrl[7:4]=hard_sseg_ctrl;
     logic seven_seg_ready;
logic[7:0] full_indicator;
logic[7:0] empty_indicator;
logic[7:0] normal_indicator;

assign full_indicator=8'b00000011;
assign empty_indicator=8'b00000001;
assign normal_indicator=8'b00000000;

logic[7:0] indicator;
assign indicator=fifo_full?full_indicator:
fifo_empy?empty_indicator:
normal_indicator
;

sseg_mux seven_mux(.number( {indicator, fifo_top} ),
.ctrl(sseg_ctrl[3:0]),
.data(sseg_data),
.start_signal(r_need_refresh),
.finished_signal(seven_seg_ready),
.clk(clk),
.nRst(nrst));
endmodule

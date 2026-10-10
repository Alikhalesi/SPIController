`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2026 08:20:06 AM
// Design Name: 
// Module Name: edge_detector
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


module delay_signal
(
input logic clk,
input logic nrst,
input logic d,
input logic q
    );
    
    typedef enum logic [1:0] {IDLE=2'd0,HIGH=2'd1,NOTIFY=2'd2} state;
    logic r_q,next_q;
    state r_state,next_state;
    
    always_ff @(posedge clk, negedge nrst)
        begin
            if(!nrst)
                begin
                    r_q<=0;
                    r_state<=IDLE;
                end
             else
                begin
                    r_q<=next_q;
                    r_state<=next_state;
                end
        end
        
        
        always_comb
            begin
                next_q=0;
                next_state=r_state;
                case (r_state)
                    IDLE:
                        begin
                            if(d)
                                next_state=HIGH;
                        end
                    HIGH:
                        begin
                            if(!d)
                                next_state=NOTIFY;
                        end
                    NOTIFY:
                        begin
                            next_q=1;
                            next_state=IDLE;
                        end 
                endcase
                
              end  
                
             
    assign q=r_q;
    
    
endmodule

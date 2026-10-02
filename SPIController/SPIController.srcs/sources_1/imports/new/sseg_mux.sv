`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/27/2026 03:59:22 PM
// Design Name: 
// Module Name: sseg_mux
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


module sseg_mux(
input logic [15:0] number,
output logic [3:0] ctrl,
output logic [7:0] data,
 input logic start_signal,
 output logic finished_signal, 
input logic clk,
input logic nRst
    );
    
    
    logic ready;
    logic [1:0] current_segment;
    logic [3:0] current_value;
    
    logic [19:0] dec_value;
    logic start_binary_decoding;
    logic binary_decode_finished;  
    logic [15:0] registered_number;
   
    assign finished_signal= ready;
    
    
    typedef enum logic[1:0] { IDLE=2'b0,DECODING=2'b01,FINISHED=2'b10} state;
    state current_state,next_state;
    
        always_ff @(posedge clk or negedge nRst) begin
        if (!nRst) 
            current_state <= IDLE;
        else 
            current_state <= next_state;
    end
    
    localparam RENDERING_TIME=28'd000_100_000;
    
    binary_to_decimal_16bit bintodec(.clk(clk),.rst_n(nRst),.start(start_binary_decoding),
    .binary_in(registered_number),.bcd_out(dec_value),.ready(binary_decode_finished));


    logic [27:0] delay;

    always_ff @(posedge clk, negedge nRst)  begin
    if (!nRst)
        begin
            start_binary_decoding<=1'b0;
            registered_number<=16'b0;
            ready<=1'b1;
          
        end
    else
    
    case (current_state)
    IDLE:
        begin
        if(start_signal)
            begin
                registered_number<=number;
                start_binary_decoding<=1'b1;                
                ready<=1'b0;
            end
        end
        
        FINISHED:
        begin
         ready<=1'b1;
        start_binary_decoding<=1'b0;   
         end
   //     default:current_state<=current_state;
    endcase
     
    end
    
    
    
    
    //next_state logic
       always_comb begin
       next_state=current_state;
        case (current_state)
    IDLE:
        begin
            if(start_signal)
                next_state=DECODING;
        end
    DECODING:
        begin
            if(binary_decode_finished)
                next_state=FINISHED;
                
        end
  
        FINISHED:
          next_state=IDLE;
        
        default: next_state=current_state;
        endcase
        
       end
    
    
    
      always_ff @(posedge clk, negedge nRst)  begin
    if (!nRst)
        begin
          delay<=28'd0;
  
        current_segment<=2'b11;
        end
    else
  if (delay<RENDERING_TIME)
                          delay<=delay+1'b1;
                          else
                          begin
    current_segment<=current_segment-1'b1;
    delay<=28'd0;
    end
    
    end
    
    //Output logic
    
    always_comb begin
  ctrl=4'b1111;
    case (current_segment)
  
    2'b01:
        begin
            current_value=dec_value[7:4];
            ctrl=4'b1101;
        end
    2'b10:
        begin 
            current_value=dec_value[11:8];
            ctrl=4'b1011;
        end
    2'b11: 
        begin
            current_value=dec_value[15:12];
                ctrl=4'b0111;
        end
    default:  
        begin
            current_value=dec_value[3:0];
            ctrl=4'b1110;
        end
    endcase

    
    
    end
    
    assign data[7]=1'b1;
    
    sseg seg(.number(current_value),.segments(data[6:0]));

endmodule
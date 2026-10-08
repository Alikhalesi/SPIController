`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/01/2026 07:29:46 PM
// Design Name: 
// Module Name: spi_master
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

//cpol = 0
//cpha = 0
module spi_master #(parameter int freq=2_000_000)
(
input logic clk,
input logic nrst,
output logic sclk,
output logic mosi,
output logic ready,
input logic miso,
input logic start,
input logic[7:0] din,
output logic[7:0] dout,
output logic finished


    );
    
    localparam int dvsr=(100_000_000/(2*freq))-1;
    
    logic r_ready,next_ready;
    logic[7:0] r_din,next_din;
    logic[7:0] r_dout,next_dout;
    logic r_sclk,next_sclk;
    logic[2:0] r_bit_count,next_bit_count;
    logic r_mosi,next_mosi;
    logic r_finish,next_finish;
    
    logic [23:0] r_counter,next_counter;
    
    typedef enum logic[1:0] {IDLE=2'b00,P0=2'b01,P1=2'b10} state;
    
  state r_state,next_state;
    
    always_ff @(posedge clk,negedge nrst)
        begin
            if (!nrst)
                begin
                    r_ready<=0;
                    r_din<=0;
                    r_dout<=0;
                    r_state<=IDLE;
                    r_sclk<=0; //as cpol=0
                    r_bit_count<=7;
                    r_counter<=0;
                    r_mosi<=0;
                    r_finish<=0;
                end
             else
                begin
                    r_ready<=next_ready;
                    r_din<=next_din;
                    r_dout<=next_dout;
                    r_state<=next_state;
                    r_sclk<=next_sclk;
                    r_bit_count<=next_bit_count;
                    r_counter<=next_counter;
                    r_mosi<=next_mosi;
                    r_finish<=next_finish;
                end
        end 
    
    
    always_comb
        begin
            next_ready=0;
            next_din=r_din;
            next_dout=r_dout;
            next_state=r_state;
            next_sclk=r_sclk;
            next_bit_count=r_bit_count;
            next_counter=r_counter;
            next_mosi=r_mosi;
            next_finish=0;
            case (r_state)
                IDLE:
                    begin
                       next_bit_count=7;
                        if(start)
                            begin
                                next_din=din;
                                next_ready=0;
                                next_state=P0;
                                next_counter=0;
                                next_sclk=0;
                                next_dout=0;
                            end
                         else
                            begin
                                next_ready=1;
                            end   
                     end
                P0:
                    begin
                       next_mosi = r_din[r_bit_count];
                       if(r_counter==dvsr)
                          begin
                            next_state=P1;
                            next_sclk=1;
                            next_counter=0;
                          end
                       else
                        next_counter=r_counter+1;
                       
                    end
                P1:
                    begin
                    
                           if(r_counter==dvsr)
                            begin
                                next_dout={r_dout[6:0],miso};
                                if(r_bit_count==0)
                                    begin
                                  
                                        next_state=IDLE;
                                        next_finish=1;
                                    end
                                else
                                    begin
                                        next_bit_count=r_bit_count-1;
                                        next_state=P0;
                                        next_counter=0;
                                        next_sclk=0;
                                    end
                            end
                           else
                             next_counter=r_counter+1;
                    end
            endcase
        end
    
    
    
    assign dout=r_dout;
    assign ready=r_ready;
    assign mosi=r_mosi;
    assign sclk=r_sclk;
    assign finished=r_finish;
endmodule

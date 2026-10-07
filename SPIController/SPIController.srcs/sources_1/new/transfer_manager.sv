`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2026 07:33:39 AM
// Design Name: 
// Module Name: transfer_manager
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


module adxl_driver #(localparam int READ_COUNT=1)
(
    input logic clk,
input logic nrst,
input logic spi_master_ready,
input logic spi_master_finished,
output logic csn,
output logic[7:0] spi_master_din,
output spi_master_start_transfer
    );
    
      
  typedef enum logic[7:0] {WRITE_REGISTER=8'h0A,READ_REGISTER=8'h0B,READ_FIFO=8'h0D} Commands;
  typedef enum logic [3:0] {
    IDLE = 4'd0,
    TEAR_UP_TRANSACTION=4'd1,
    SEND_INSTRUCTION=4'd2,
    SEND_ADDRESS=4'd3,
    GET_DATA=4'd4,
    TEAR_DOWN_TRANSACTION=4'd5
} state_t;

state_t r_state,next_state;
logic r_spi_master_ready,next_spi_master_ready;
logic r_spi_master_finished,next_spi_master_finished;
logic r_csn,next_csn;
logic r_spi_master_start_transfer,next_spi_master_start_transfer;
logic[7:0] r_spi_master_din,next_spi_master_din;
    
    always_ff @(posedge clk, negedge nrst)
        begin
            if(!nrst)
                begin
                    r_state<=0;
                    r_spi_master_ready<=0;
                    r_spi_master_finished<=0;
                    r_csn<=0;
                    r_spi_master_din<=0;
                    r_spi_master_start_transfer<=0;
                end
             else
                begin
                    r_state<=next_state;
                    r_spi_master_ready<=next_spi_master_ready;
                    r_spi_master_finished<=next_spi_master_finished;
                    r_csn<=next_csn;
                    r_spi_master_din<=next_spi_master_din;
                    r_spi_master_start_transfer<=next_spi_master_start_transfer;
                end
        end 
    
    
    always_comb
    begin
        case (r_state)
            IDLE:
                begin
                end
            TEAR_UP_TRANSACTION:
                begin
                end
            SEND_INSTRUCTION:
                begin
                end
            SEND_ADDRESS:
                begin
                end
            GET_DATA:
                begin
                end
            TEAR_DOWN_TRANSACTION:
                begin
                end
            
        endcase
    end
    
    
    
    
    assign csn=r_csn;
    assign spi_master_din=r_spi_master_din;
    assign spi_master_start_transfer=r_spi_master_start_transfer;
    
    
    
endmodule

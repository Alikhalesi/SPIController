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


module adxl_driver #(localparam int READ_COUNT=1,localparam logic[7:0] READ_PATTERN=8'd1)
(
    input logic clk,
input logic nrst,
input logic spi_master_ready,
input logic spi_master_finished,
output logic csn,
output logic[7:0] spi_master_din,
output logic spi_master_start_transfer,
input logic start,
output logic ready,
input logic [7:0] instruction,
input logic [7:0] addr,
output logic finish,
output logic data_phase
    );
    
      

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
logic r_ready,next_ready;
logic[7:0] r_instruction,next_instruction;
logic[7:0] r_addr,next_addr;
logic [7:0] r_readed_byte_count,next_readed_byte_count;
logic  r_finish,next_finish;
    
    always_ff @(posedge clk, negedge nrst)
        begin
            if(!nrst)
                begin
                    r_state<=IDLE;
                    r_spi_master_ready<=0;
                    r_spi_master_finished<=0;
                    r_csn<=1;
                    r_spi_master_din<=0;
                    r_spi_master_start_transfer<=0;
                    r_ready<=0;
                    r_instruction<=0;
                    r_addr<=0;
                    r_readed_byte_count<=0;
                    r_finish<=0;
                end
             else
                begin
                    r_state<=next_state;
                    r_spi_master_ready<=next_spi_master_ready;
                    r_spi_master_finished<=next_spi_master_finished;
                    r_csn<=next_csn;
                    r_spi_master_din<=next_spi_master_din;
                    r_spi_master_start_transfer<=next_spi_master_start_transfer;
                    r_ready<=next_ready;
                    r_instruction<=next_instruction;
                    r_addr<=next_addr;
                    r_readed_byte_count<=next_readed_byte_count;
                    r_finish<=next_finish;
                end
        end 
    
    
    always_comb
    begin
    next_state=r_state;
    next_spi_master_ready=r_spi_master_ready;
    next_spi_master_finished=r_spi_master_finished;
    next_csn=r_csn;
    next_spi_master_din=r_spi_master_din;
    next_spi_master_start_transfer=r_spi_master_start_transfer;
    next_ready<=r_ready;
    next_instruction<=r_instruction;
    next_addr<=r_addr;
    next_readed_byte_count<=r_readed_byte_count;
    next_finish<=r_finish;
        case (r_state)
            IDLE:
                begin
                    if(start && spi_master_ready)
                        begin
                            next_instruction=instruction;
                            next_addr=addr;
                            next_ready=0;
                            next_state=TEAR_UP_TRANSACTION;
                        end
                    else
                        begin
                            next_ready=0;
                            next_readed_byte_count=0;
                            next_finish=0;
                        end
                end
            TEAR_UP_TRANSACTION:
                begin
                    next_csn=0;
                    next_state=SEND_INSTRUCTION;
                end
            SEND_INSTRUCTION:
                begin
                    next_spi_master_din=r_instruction;
                    next_spi_master_start_transfer=1;
                    next_state=SEND_ADDRESS;
                end
            SEND_ADDRESS:
                begin
                  if (r_spi_master_finished)
                    begin
                        next_spi_master_din=r_addr;
                        next_spi_master_start_transfer=1;
                        next_state=GET_DATA;
                    end
                end
            GET_DATA:
                begin
                    if (r_spi_master_finished)
                        begin
                           if(r_readed_byte_count==READ_COUNT)
                                next_state=TEAR_DOWN_TRANSACTION;
                           else
                                begin
                                    next_readed_byte_count=r_readed_byte_count+1;
                                    next_spi_master_din=READ_PATTERN;
                                    next_spi_master_start_transfer=1;
                                end
                        end
                end
            TEAR_DOWN_TRANSACTION:
                begin
                next_state=IDLE;
                next_csn=0;
                next_finish=1;
                end
            
        endcase
    end
    
    
    
    assign csn=r_csn;
    assign spi_master_din=r_spi_master_din;
    assign spi_master_start_transfer=r_spi_master_start_transfer;
    assign ready=r_ready;
    assign finish=r_finish;
    assign data_phase=r_state==GET_DATA && r_readed_byte_count!=0;
endmodule

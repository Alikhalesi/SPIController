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
input logic btnr,
output logic led

    );
    

      
  typedef enum logic[7:0] {WRITE_REGISTER=8'h0A,READ_REGISTER=8'h0B,READ_FIFO=8'h0D} AXL_INSTRUCTION;
  
    logic synced_rst;
    reset_synchronizer rst_synchronizer(.nrst(nrst),.clk(clk),.sync_nrst(synced_rst));
    
        logic btn_debounced;
debouncer btn_debouncer(.d(btn),.q(btn_debounced),.clk(clk),.nrst(synced_rst));
    
    logic btn_delayed;
     delay_signal btn_delay(.clk(clk),.nrst(nrst),.d(btn_debounced),.q(btn_delayed));
    
        logic btnr_debounced;
debouncer btnr_debouncer(.d(btnr),.q(btnr_debounced),.clk(clk),.nrst(synced_rst));
    
    logic btnr_delayed;
     delay_signal btnr_delay(.clk(clk),.nrst(nrst),.d(btnr_debounced),.q(btnr_delayed));

    
    logic transmit_finished;
    
    logic[7:0] fifo_read;
    logic[7:0] fifo_write;
    logic fifo_empty;
    logic fifo_full;
    logic spi_master_ready;
    logic spi_master_finished;
    logic [7:0] spi_master_din;
    logic spi_master_start_transfer;
    logic data_phase;
    
    //driver
     logic driver_start;
    logic driver_ready;
    logic driver_finished;
    logic [7:0] instruction;
    logic [7:0] addr;
    logic [7:0] spi_write_data;
    logic spi_transaction_type;
    assign spi_transaction_type=0;
    assign instruction=READ_REGISTER;
    assign addr=8'h0;
    
    assign write_enable=spi_master_finished && data_phase;
    logic read_enable= (!fifo_empty) && btnr_delayed;// read operation is asynchronous, this signal just pop the data from FIFO.
    logic fifo_top_updated;    
    fifo  #(.DATA_WIDTH(8)) fifo_instance
    (.clk(clk),.nrst(synced_rst),.w_en(write_enable),.r_en(read_enable),.r_data(fifo_read),.w_data(fifo_write),.empty(fifo_empty),.full(fifo_full),.top_updated(fifo_top_updated));
    
    
      //this code is temporary replacement of software code ,
     logic r_start_transaction,next_start_transaction;
     logic [7:0] r_instruction,next_instruction;
     logic [7:0] r_addr,next_addr;
     logic [7:0] r_write_data,next_write_data;
     logic r_transaction_type,next_transaction_type;
     logic [7:0] r_counter,next_counter;
    //
    
    
  spi_master master(
 .clk(clk),
 .nrst(synced_rst),
.sclk(sclk),
.mosi(mosi),
.ready(spi_master_ready),
.miso(miso),
.start(spi_master_start_transfer),
.din(spi_master_din),
.dout(fifo_write),
.finished(spi_master_finished)
);

  adxl_driver driver
(
    .clk(clk),
.nrst(synced_rst),
.spi_master_ready(spi_master_ready),
  .spi_master_finished(spi_master_finished),
.csn(csn),
.spi_master_din(spi_master_din),
.spi_master_start_transfer(spi_master_start_transfer),
.start(r_start_transaction),
.ready(driver_ready),
.instruction(r_instruction),
.addr(r_addr),
.finish(driver_finished),
.data_phase(data_phase),
.transaction_type(r_transaction_type),
.write_data(r_write_data)
    );
  
 
acc_subscriber seven_seg_subscriber(.clk(clk),
        .nrst(synced_rst),
        .fifo_empy(fifo_empty),
        .fifo_full(fifo_full),
        .fifo_top(fifo_read),
        .fifo_updated(fifo_top_updated),
         .sseg_data(sseg_data),
.sseg_ctrl(sseg_ctrl)
    );


 assign led= fifo_full; 
    
    //this code is temporary replacement of software code ,
    typedef enum logic [4:0] {IDLE=4'd0,RESET_AXL=4'd2,SET_MEASURE_MODE=4'd3,READ_TEMPS=4'd4} state;
    state r_state,next_state;

    always_ff @(posedge clk,negedge synced_rst)
        begin
            if(!synced_rst)
                begin
                    r_state<=IDLE;
                    r_start_transaction<=0;
                    r_instruction<=0;
                    r_addr<=0;
                    r_write_data<=0;
                    r_transaction_type<=0;
                    r_counter<=0;
                end
            else
                begin
                    r_state<=next_state;
                    r_start_transaction<=next_start_transaction;
                    r_instruction<=next_start_transaction;
                    r_addr<=next_addr;
                    r_write_data<=next_write_data;
                    r_transaction_type<=next_transaction_type;
                    r_counter<=next_counter;
                    
                end
        end
    
    always_comb
        begin
            next_state=r_state;
            next_start_transaction=0;
            next_instruction=r_instruction;
            next_addr=r_addr;
            next_write_data=r_write_data;
            next_transaction_type=r_transaction_type;
            next_counter=r_counter;
            case (r_state)
                IDLE:
                    begin
                        if(btn_delayed)
                            begin
                                next_state=RESET_AXL;
                            end
                    end
                RESET_AXL:
                    begin
                          next_instruction=WRITE_REGISTER;
                          next_addr=8'h1F;
                          next_write_data=8'h52;
                          next_transaction_type=0;  
                          next_start_transaction=1;
                    end
                SET_MEASURE_MODE:
                    begin
                         next_start_transaction=0;
                         if(driver_finished)
                            begin
                               if (r_counter==1000_000)
                                begin
                                     next_instruction=WRITE_REGISTER;
                                     next_addr=8'h2D;
                                     next_write_data=8'h02;
                                     next_transaction_type=0;
                                     next_start_transaction=1;
                                     next_state=READ_TEMPS;
                                end
                            else
                                begin
                                    next_counter=r_counter+1;
                                end
                        
                            end
                         else
                            begin
                            
                            end
                    end
                    READ_TEMPS:
                        begin
                          next_start_transaction=0;
                            if(driver_finished)
                                begin
                                     next_instruction=READ_REGISTER;
                                     next_addr=8'h14;
                                     next_transaction_type=1;
                                     next_start_transaction=1;
                                     next_state=IDLE;
                                end
                          
                        end
                    
            endcase
        end
    
    
endmodule
